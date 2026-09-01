package com.community.micrologistics.service

import com.community.micrologistics.entity.WalletEntity
import com.community.micrologistics.entity.WalletTransactionEntity
import com.community.micrologistics.enums.WalletType
import com.community.micrologistics.enums.WalletTransactionType
import com.community.micrologistics.exception.InsufficientFundsException
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.WalletRepository
import com.community.micrologistics.repository.WalletTransactionRepository
import com.community.micrologistics.util.MoneyUtils
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.util.UUID

@Service
class WalletService(
    private val walletRepository: WalletRepository,
    private val walletTransactionRepository: WalletTransactionRepository
) {
    @Transactional
    fun createDefaultWalletsForUser(userId: UUID) {
        ensureWallet(userId, WalletType.CREATOR)
        ensureWallet(userId, WalletType.RUNNER)
    }

    @Transactional
    fun freezeCreatorEscrow(userId: UUID, amount: BigDecimal, referenceId: UUID? = null): WalletEntity {
        val creatorWallet = getWalletForUpdate(userId, WalletType.CREATOR)
        if (creatorWallet.availableBalance.compareTo(amount) < 0) {
            throw InsufficientFundsException(
                "Insufficient available balance in creator wallet. Required=$amount, available=${creatorWallet.availableBalance}"
            )
        }

        creatorWallet.availableBalance = MoneyUtils.scale(creatorWallet.availableBalance.subtract(amount))
        creatorWallet.frozenBalance = MoneyUtils.scale(creatorWallet.frozenBalance.add(amount))
        val savedWallet = walletRepository.save(creatorWallet)
        val transactionReference = referenceId ?: UUID.randomUUID()
        recordTransaction(
            userId = userId,
            wallet = creatorWallet,
            type = WalletTransactionType.ESCROW_FREEZE,
            amount = amount,
            deltaAvailable = amount.negate(),
            deltaFrozen = amount,
            referenceType = "TASK",
            referenceId = transactionReference,
            idempotencyKey = "ESCROW_FREEZE:$transactionReference",
            description = "任务托管冻结"
        )
        return savedWallet
    }

    @Transactional
    fun releaseEscrowToRunner(
        creatorId: UUID,
        runnerId: UUID,
        grossAmount: BigDecimal,
        referenceId: UUID? = null
    ): SettlementResult {
        val wallets = listOf(
            WalletKey(creatorId, WalletType.CREATOR),
            WalletKey(runnerId, WalletType.RUNNER)
        ).sortedWith(compareBy({ it.userId.toString() }, { it.walletType.name }))
            .associateWith { getWalletForUpdate(it.userId, it.walletType) }
        val creatorWallet = wallets.getValue(WalletKey(creatorId, WalletType.CREATOR))
        val runnerWallet = wallets.getValue(WalletKey(runnerId, WalletType.RUNNER))

        if (creatorWallet.frozenBalance.compareTo(grossAmount) < 0) {
            throw InsufficientFundsException(
                "Frozen escrow is lower than settlement amount. Frozen=${creatorWallet.frozenBalance}, gross=$grossAmount"
            )
        }

        val platformFee = MoneyUtils.scale(grossAmount.multiply(BigDecimal("0.05")))
        val runnerPayout = MoneyUtils.scale(grossAmount.subtract(platformFee))

        creatorWallet.frozenBalance = MoneyUtils.scale(creatorWallet.frozenBalance.subtract(grossAmount))
        runnerWallet.availableBalance = MoneyUtils.scale(runnerWallet.availableBalance.add(runnerPayout))

        walletRepository.save(creatorWallet)
        walletRepository.save(runnerWallet)

        val settlementReference = referenceId ?: UUID.randomUUID()
        recordTransaction(
            userId = creatorId,
            wallet = creatorWallet,
            type = WalletTransactionType.ESCROW_RELEASE,
            amount = grossAmount,
            deltaAvailable = BigDecimal.ZERO,
            deltaFrozen = grossAmount.negate(),
            referenceType = "ORDER",
            referenceId = settlementReference,
            idempotencyKey = "ESCROW_RELEASE:$settlementReference",
            description = "订单完成，释放托管"
        )
        recordTransaction(
            userId = runnerId,
            wallet = runnerWallet,
            type = WalletTransactionType.RUNNER_PAYOUT,
            amount = runnerPayout,
            deltaAvailable = runnerPayout,
            deltaFrozen = BigDecimal.ZERO,
            referenceType = "ORDER",
            referenceId = settlementReference,
            idempotencyKey = "RUNNER_PAYOUT:$settlementReference",
            description = "订单完成，跑者收入"
        )
        recordTransaction(
            userId = creatorId,
            wallet = creatorWallet,
            type = WalletTransactionType.PLATFORM_FEE,
            amount = platformFee,
            deltaAvailable = BigDecimal.ZERO,
            deltaFrozen = BigDecimal.ZERO,
            referenceType = "ORDER",
            referenceId = settlementReference,
            idempotencyKey = "PLATFORM_FEE:$settlementReference",
            description = "平台服务费"
        )

        return SettlementResult(
            grossAmount = MoneyUtils.scale(grossAmount),
            platformFee = platformFee,
            runnerPayout = runnerPayout
        )
    }

    @Transactional
    fun refundCreatorEscrow(userId: UUID, amount: BigDecimal, referenceId: UUID? = null): WalletEntity {
        val creatorWallet = getWalletForUpdate(userId, WalletType.CREATOR)
        if (creatorWallet.frozenBalance.compareTo(amount) < 0) {
            throw InsufficientFundsException(
                "Frozen escrow is lower than refund amount. Frozen=${creatorWallet.frozenBalance}, refund=$amount"
            )
        }
        creatorWallet.frozenBalance = MoneyUtils.scale(creatorWallet.frozenBalance.subtract(amount))
        creatorWallet.availableBalance = MoneyUtils.scale(creatorWallet.availableBalance.add(amount))
        val savedWallet = walletRepository.save(creatorWallet)
        val refundReference = referenceId ?: UUID.randomUUID()
        recordTransaction(
            userId = userId,
            wallet = creatorWallet,
            type = WalletTransactionType.ESCROW_REFUND,
            amount = amount,
            deltaAvailable = amount,
            deltaFrozen = amount.negate(),
            referenceType = "TASK",
            referenceId = refundReference,
            idempotencyKey = "ESCROW_REFUND:$refundReference",
            description = "任务取消，退回托管"
        )
        return savedWallet
    }

    @Transactional(readOnly = true)
    fun getWalletOrZero(userId: UUID, walletType: WalletType): WalletSnapshot {
        val wallet = walletRepository.findByUserIdAndWalletType(userId, walletType)
        return if (wallet == null) {
            WalletSnapshot(BigDecimal.ZERO, BigDecimal.ZERO)
        } else {
            WalletSnapshot(
                availableBalance = MoneyUtils.scale(wallet.availableBalance),
                frozenBalance = MoneyUtils.scale(wallet.frozenBalance)
            )
        }
    }

    private fun getWalletForUpdate(userId: UUID, walletType: WalletType): WalletEntity =
        walletRepository.findByUserIdAndWalletTypeForUpdate(userId, walletType)
            ?: throw ResourceNotFoundException("Wallet for user $userId and type $walletType was not found")

    private fun ensureWallet(userId: UUID, walletType: WalletType) {
        val exists = walletRepository.findByUserIdAndWalletType(userId, walletType)
        if (exists != null) {
            return
        }
        walletRepository.save(
            WalletEntity(
                userId = userId,
                walletType = walletType,
                availableBalance = BigDecimal.ZERO,
                frozenBalance = BigDecimal.ZERO
            )
        )
    }

    private fun recordTransaction(
        userId: UUID,
        wallet: WalletEntity,
        type: WalletTransactionType,
        amount: BigDecimal,
        deltaAvailable: BigDecimal,
        deltaFrozen: BigDecimal,
        referenceType: String,
        referenceId: UUID,
        idempotencyKey: String,
        description: String
    ) {
        if (walletTransactionRepository.existsByIdempotencyKey(idempotencyKey)) {
            return
        }
        walletTransactionRepository.save(
            WalletTransactionEntity(
                userId = userId,
                transactionType = type,
                amount = MoneyUtils.scale(amount),
                deltaAvailable = MoneyUtils.scale(deltaAvailable),
                deltaFrozen = MoneyUtils.scale(deltaFrozen),
                availableBalance = MoneyUtils.scale(wallet.availableBalance),
                frozenBalance = MoneyUtils.scale(wallet.frozenBalance),
                referenceType = referenceType,
                referenceId = referenceId,
                idempotencyKey = idempotencyKey,
                description = description
            )
        )
    }

    private data class WalletKey(val userId: UUID, val walletType: WalletType)
}

data class SettlementResult(
    val grossAmount: BigDecimal,
    val platformFee: BigDecimal,
    val runnerPayout: BigDecimal
)

data class WalletSnapshot(
    val availableBalance: BigDecimal,
    val frozenBalance: BigDecimal
)

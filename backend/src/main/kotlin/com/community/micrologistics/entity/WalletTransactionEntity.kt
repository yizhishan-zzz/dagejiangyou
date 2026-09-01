package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.WalletTransactionType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.math.BigDecimal
import java.util.UUID

@Entity
@Table(name = "wallet_transactions")
class WalletTransactionEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "user_id", nullable = false)
    var userId: UUID = UUID.randomUUID(),

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 24)
    var transactionType: WalletTransactionType = WalletTransactionType.ESCROW_FREEZE,

    @Column(name = "amount", nullable = false, precision = 12, scale = 2)
    var amount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "delta_available", nullable = false, precision = 12, scale = 2)
    var deltaAvailable: BigDecimal = BigDecimal.ZERO,

    @Column(name = "delta_frozen", nullable = false, precision = 12, scale = 2)
    var deltaFrozen: BigDecimal = BigDecimal.ZERO,

    @Column(name = "available_balance", nullable = false, precision = 12, scale = 2)
    var availableBalance: BigDecimal = BigDecimal.ZERO,

    @Column(name = "frozen_balance", nullable = false, precision = 12, scale = 2)
    var frozenBalance: BigDecimal = BigDecimal.ZERO,

    @Column(name = "reference_type", nullable = false, length = 24)
    var referenceType: String = "SYSTEM",

    @Column(name = "reference_id", nullable = false)
    var referenceId: UUID = UUID.randomUUID(),

    @Column(name = "idempotency_key", nullable = false, unique = true, length = 160)
    var idempotencyKey: String = UUID.randomUUID().toString(),

    @Column(name = "description", nullable = false, length = 200)
    var description: String = ""
) : AuditableEntity()

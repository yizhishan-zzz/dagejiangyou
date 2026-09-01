package com.community.micrologistics.service

import com.community.micrologistics.dto.pool.CreatePoolRequest
import com.community.micrologistics.dto.pool.JoinPoolRequest
import com.community.micrologistics.entity.PoolEntity
import com.community.micrologistics.entity.PoolMemberEntity
import com.community.micrologistics.entity.UserEntity
import com.community.micrologistics.enums.PoolStatus
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.repository.PoolMemberRepository
import com.community.micrologistics.repository.PoolRepository
import com.community.micrologistics.repository.UserRepository
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import java.math.BigDecimal
import java.util.Optional
import java.util.UUID

class PoolServiceTest {
    private lateinit var poolRepository: PoolRepository
    private lateinit var poolMemberRepository: PoolMemberRepository
    private lateinit var userRepository: UserRepository
    private lateinit var walletService: WalletService
    private lateinit var poolService: PoolService

    @BeforeEach
    fun setUp() {
        poolRepository = mock(PoolRepository::class.java)
        poolMemberRepository = mock(PoolMemberRepository::class.java)
        userRepository = mock(UserRepository::class.java)
        walletService = WalletService(
            mock(com.community.micrologistics.repository.WalletRepository::class.java),
            mock(com.community.micrologistics.repository.WalletTransactionRepository::class.java)
        )
        poolService = PoolService(poolRepository, poolMemberRepository, UserService(userRepository, walletService))
    }

    @Test
    fun `createPool creates an open pool with initial shared cost`() {
        val creatorId = UUID.randomUUID()
        val communityId = UUID.randomUUID()
        val creator = UserEntity(
            id = creatorId,
            phoneNumber = "13800000000",
            displayName = "creator",
            activeMode = UserMode.CREATOR,
            communityId = communityId
        )
        val request = CreatePoolRequest(
            title = "早餐拼单",
            storeName = "南门豆浆铺",
            category = "早餐到楼",
            summary = "统一送到门厅",
            pickupPoint = "7号楼门厅",
            freightFee = BigDecimal("6.00"),
            deliveryFee = BigDecimal("3.60"),
            targetParticipants = 6,
            countdownMinutes = 30
        )

        `when`(userRepository.findById(creatorId)).thenReturn(Optional.of(creator))
        `when`(poolRepository.save(any(PoolEntity::class.java))).thenAnswer { it.arguments[0] as PoolEntity }

        val response = poolService.createPool(creatorId, request)

        assertEquals(PoolStatus.OPEN, response.status)
        assertEquals(1, response.currentParticipants)
        assertEquals(BigDecimal("9.60"), response.sharedFeePerUser)
    }

    @Test
    fun `joinPool recalculates the shared fee for all active participants`() {
        val creatorId = UUID.randomUUID()
        val runnerId = UUID.randomUUID()
        val communityId = UUID.randomUUID()
        val poolId = UUID.randomUUID()
        val user = UserEntity(
            id = runnerId,
            phoneNumber = "13800000001",
            displayName = "runner",
            activeMode = UserMode.RUNNER,
            communityId = communityId
        )
        val pool = PoolEntity(
            id = poolId,
            creatorId = creatorId,
            communityId = communityId,
            title = "晚饭拼单",
            storeName = "社区店",
            summary = "一起下单",
            pickupPoint = "门厅",
            freightFee = BigDecimal("6.00"),
            deliveryFee = BigDecimal("3.60"),
            targetParticipants = 4,
            currentParticipants = 1,
            sharedFeePerUser = BigDecimal("9.60")
        )
        val member = PoolMemberEntity(poolId = poolId, userId = runnerId)

        `when`(userRepository.findById(runnerId)).thenReturn(Optional.of(user))
        `when`(poolRepository.findByIdForUpdate(poolId)).thenReturn(pool)
        `when`(poolMemberRepository.existsByPoolIdAndUserIdAndActiveTrue(poolId, runnerId)).thenReturn(false)
        `when`(poolMemberRepository.save(any(PoolMemberEntity::class.java))).thenReturn(member)
        `when`(poolMemberRepository.findAllByPoolIdAndActiveTrue(poolId)).thenReturn(listOf(member))

        val response = poolService.joinPool(runnerId, poolId, JoinPoolRequest())

        assertEquals(2, response.currentParticipants)
        assertEquals(BigDecimal("4.80"), response.sharedFeePerUser)
        assertEquals(BigDecimal("4.80"), response.yourSharedFee)
        assertTrue(pool.status == PoolStatus.OPEN)
    }
}

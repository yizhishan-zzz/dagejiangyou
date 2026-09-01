package com.community.micrologistics.service

import com.community.micrologistics.dto.pool.CreatePoolRequest
import com.community.micrologistics.dto.pool.JoinPoolRequest
import com.community.micrologistics.dto.pool.PoolJoinResponse
import com.community.micrologistics.dto.pool.PoolShowcaseResponse
import com.community.micrologistics.entity.PoolEntity
import com.community.micrologistics.entity.PoolMemberEntity
import com.community.micrologistics.enums.PoolStatus
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.PoolMemberRepository
import com.community.micrologistics.repository.PoolRepository
import com.community.micrologistics.util.MoneyUtils
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class PoolService(
    private val poolRepository: PoolRepository,
    private val poolMemberRepository: PoolMemberRepository,
    private val userService: UserService
) {
    @Transactional
    fun createPool(userId: UUID, request: CreatePoolRequest): PoolShowcaseResponse {
        val creator = userService.requireMode(userId, UserMode.CREATOR)
        val freightFee = MoneyUtils.scale(request.freightFee)
        val deliveryFee = MoneyUtils.scale(request.deliveryFee)
        val sharedFeePerUser = MoneyUtils.scale(freightFee.add(deliveryFee))
        val pool = poolRepository.save(
            PoolEntity(
                creatorId = userId,
                communityId = creator.communityId,
                title = request.title.trim(),
                storeName = request.storeName.trim(),
                category = request.category.trim(),
                summary = request.summary.trim(),
                pickupPoint = request.pickupPoint.trim(),
                status = PoolStatus.OPEN,
                freightFee = freightFee,
                deliveryFee = deliveryFee,
                targetParticipants = request.targetParticipants,
                currentParticipants = 1,
                countdownMinutes = request.countdownMinutes,
                sharedFeePerUser = sharedFeePerUser
            )
        )
        return pool.toShowcaseResponse()
    }

    @Transactional(readOnly = true)
    fun listShowcasePools(userId: UUID): List<PoolShowcaseResponse> {
        val user = userService.findUser(userId)
        return poolRepository.findAllByStatusInOrderByCreatedAtDesc(listOf(PoolStatus.OPEN, PoolStatus.FULL))
            .filter { pool ->
                user.systemRole.name == "ADMIN" || pool.communityId == user.communityId
            }
            .map { pool ->
                pool.toShowcaseResponse()
            }
    }

    @Transactional
    fun joinPool(userId: UUID, poolId: UUID, request: JoinPoolRequest): PoolJoinResponse {
        val user = userService.findUser(userId)
        val pool = poolRepository.findByIdForUpdate(poolId)
            ?: throw ResourceNotFoundException("Pool $poolId was not found")

        if (pool.status != PoolStatus.OPEN) {
            throw InvalidOperationException("Pool $poolId is not open for joining")
        }
        if (pool.creatorId == userId) {
            throw InvalidOperationException("The pool creator is already counted as a participant")
        }
        if (pool.currentParticipants >= pool.targetParticipants) {
            pool.status = PoolStatus.FULL
            poolRepository.save(pool)
            throw InvalidOperationException("Pool $poolId is already full")
        }
        if (pool.communityId != null && pool.communityId != user.communityId) {
            throw InvalidOperationException("User $userId is not in the same community as pool $poolId")
        }
        if (poolMemberRepository.existsByPoolIdAndUserIdAndActiveTrue(poolId, userId)) {
            throw InvalidOperationException("User $userId has already joined pool $poolId")
        }

        val member = poolMemberRepository.save(
            PoolMemberEntity(
                poolId = poolId,
                userId = userId,
                quantity = request.quantity,
                itemAmount = request.itemAmount
            )
        )

        val allMembers = poolMemberRepository.findAllByPoolIdAndActiveTrue(poolId)
        // The creator is the implicit first participant; pool_members stores joiners.
        // Recalculate from active rows so a stale cached counter cannot inflate shares.
        val participantCount = allMembers.size + 1
        val sharedCost = pool.freightFee.add(pool.deliveryFee)
        val sharePerUser = MoneyUtils.scale(sharedCost.divide(participantCount.toBigDecimal(), 2, java.math.RoundingMode.HALF_UP))

        allMembers.forEach {
            it.sharedFeeShare = sharePerUser
        }
        poolMemberRepository.saveAll(allMembers)

        pool.currentParticipants = participantCount
        pool.sharedFeePerUser = sharePerUser
        pool.status = if (participantCount >= pool.targetParticipants) PoolStatus.FULL else PoolStatus.OPEN
        pool.countdownMinutes = maxOf(pool.countdownMinutes - 2, 5)
        poolRepository.save(pool)

        return PoolJoinResponse(
            poolId = pool.id,
            currentParticipants = pool.currentParticipants,
            targetParticipants = pool.targetParticipants,
            sharedFeePerUser = pool.sharedFeePerUser,
            yourSharedFee = member.sharedFeeShare.takeIf { it > java.math.BigDecimal.ZERO } ?: sharePerUser,
            poolStatus = pool.status
        )
    }

    private fun PoolEntity.toShowcaseResponse() =
        PoolShowcaseResponse(
            poolId = id,
            title = title,
            category = category,
            storeName = storeName,
            summary = summary,
            pickupPoint = pickupPoint,
            currentParticipants = currentParticipants,
            targetParticipants = targetParticipants,
            sharedFeePerUser = sharedFeePerUser,
            countdownMinutes = countdownMinutes,
            status = status
        )
}

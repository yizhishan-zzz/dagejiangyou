package com.community.micrologistics.repository

import com.community.micrologistics.entity.PoolMemberEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface PoolMemberRepository : JpaRepository<PoolMemberEntity, UUID> {
    fun existsByPoolIdAndUserIdAndActiveTrue(poolId: UUID, userId: UUID): Boolean
    fun findAllByPoolIdAndActiveTrue(poolId: UUID): List<PoolMemberEntity>
    fun findByPoolIdAndUserId(poolId: UUID, userId: UUID): PoolMemberEntity?
}

package com.community.micrologistics.repository

import com.community.micrologistics.entity.PoolEntity
import com.community.micrologistics.enums.PoolStatus
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface PoolRepository : JpaRepository<PoolEntity, UUID> {
    fun findAllByStatusInOrderByCreatedAtDesc(statuses: Collection<PoolStatus>): List<PoolEntity>

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from PoolEntity p where p.id = :id")
    fun findByIdForUpdate(@Param("id") id: UUID): PoolEntity?
}

package com.community.micrologistics.repository

import com.community.micrologistics.entity.DisputeTicketEntity
import com.community.micrologistics.enums.DisputeStatus
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface DisputeTicketRepository : JpaRepository<DisputeTicketEntity, UUID> {
    fun existsByTaskIdAndOpenedBy(taskId: UUID, openedBy: UUID): Boolean

    fun findAllByOpenedByOrAgainstUserIdOrderByCreatedAtDesc(
        openedBy: UUID,
        againstUserId: UUID
    ): List<DisputeTicketEntity>

    fun findAllByStatusInOrderByCreatedAtAsc(statuses: Collection<DisputeStatus>): List<DisputeTicketEntity>

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select d from DisputeTicketEntity d where d.id = :id")
    fun findByIdForUpdate(@Param("id") id: UUID): DisputeTicketEntity?
}

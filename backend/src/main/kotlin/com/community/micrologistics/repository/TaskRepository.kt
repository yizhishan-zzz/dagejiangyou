package com.community.micrologistics.repository

import com.community.micrologistics.entity.TaskEntity
import com.community.micrologistics.enums.TaskStatus
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.domain.Pageable
import java.util.UUID

interface TaskRepository : JpaRepository<TaskEntity, UUID> {
    fun findAllByStatusAndRunnerIdIsNull(status: TaskStatus): List<TaskEntity>

    @Query(
        "select t from TaskEntity t " +
            "where t.status = :status and t.runnerId is null " +
            "and t.isPublic = true " +
            "and t.pickupLatitude between :minLatitude and :maxLatitude " +
            "and t.pickupLongitude between :minLongitude and :maxLongitude " +
            "order by t.createdAt desc"
    )
    fun findOpenTasksInBoundingBox(
        @Param("status") status: TaskStatus,
        @Param("minLatitude") minLatitude: Double,
        @Param("maxLatitude") maxLatitude: Double,
        @Param("minLongitude") minLongitude: Double,
        @Param("maxLongitude") maxLongitude: Double,
        pageable: Pageable
    ): List<TaskEntity>
    fun findAllByCreatorIdOrderByCreatedAtDesc(creatorId: UUID): List<TaskEntity>
    fun findAllByRunnerIdOrderByCreatedAtDesc(runnerId: UUID): List<TaskEntity>
    fun existsByTaskCode(taskCode: String): Boolean
    fun findByTaskCode(taskCode: String): TaskEntity?
    fun findTop100ByOrderByCreatedAtDesc(): List<TaskEntity>
    fun countByStatus(status: TaskStatus): Long

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from TaskEntity t where t.id = :id")
    fun findByIdForUpdate(@Param("id") id: UUID): TaskEntity?
}

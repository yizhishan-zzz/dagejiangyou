package com.community.micrologistics.repository

import com.community.micrologistics.entity.ReviewEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.time.OffsetDateTime
import java.util.UUID

interface ReviewRepository : JpaRepository<ReviewEntity, UUID> {
    fun existsByTaskIdAndFromUserId(taskId: UUID, fromUserId: UUID): Boolean

    @Query(
        "select avg(r.rating) from ReviewEntity r " +
            "where r.toUserId = :userId and r.createdAt >= :since"
    )
    fun averageRatingForUserSince(
        @Param("userId") userId: UUID,
        @Param("since") since: OffsetDateTime
    ): Double?

    fun findAllByTaskIdOrderByCreatedAtAsc(taskId: UUID): List<ReviewEntity>
}

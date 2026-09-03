package com.community.micrologistics.repository

import com.community.micrologistics.entity.VisitLogEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.time.OffsetDateTime
import java.util.UUID

interface VisitLogRepository : JpaRepository<VisitLogEntity, UUID> {
    fun countByCreatedAtGreaterThanEqual(since: OffsetDateTime): Long
}

package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "visit_logs")
class VisitLogEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "user_id")
    var userId: UUID? = null
) : AuditableEntity()

package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.DisputeStatus
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import jakarta.persistence.Version
import java.time.OffsetDateTime
import java.util.UUID

@Entity
@Table(
    name = "dispute_tickets",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_dispute_task_opener", columnNames = ["task_id", "opened_by"])
    ]
)
class DisputeTicketEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "task_id", nullable = false)
    var taskId: UUID = UUID.randomUUID(),

    @Column(name = "opened_by", nullable = false)
    var openedBy: UUID = UUID.randomUUID(),

    @Column(name = "against_user_id", nullable = false)
    var againstUserId: UUID = UUID.randomUUID(),

    @Column(name = "reason", nullable = false, length = 64)
    var reason: String = "",

    @Column(name = "description", nullable = false, length = 1000)
    var description: String = "",

    @Column(name = "proof_token", length = 128)
    var proofToken: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 16)
    var status: DisputeStatus = DisputeStatus.OPEN,

    @Column(name = "resolution_note", length = 1000)
    var resolutionNote: String? = null,

    @Column(name = "resolved_by")
    var resolvedBy: UUID? = null,

    @Column(name = "resolved_at")
    var resolvedAt: OffsetDateTime? = null
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

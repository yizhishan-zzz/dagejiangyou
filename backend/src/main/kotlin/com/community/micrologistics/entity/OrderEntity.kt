package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.OrderStatus
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import jakarta.persistence.Version
import java.math.BigDecimal
import java.time.OffsetDateTime
import java.util.UUID

@Entity
@Table(
    name = "orders",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_order_task", columnNames = ["task_id"])
    ]
)
class OrderEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "task_id", nullable = false)
    var taskId: UUID = UUID.randomUUID(),

    @Column(name = "creator_id", nullable = false)
    var creatorId: UUID = UUID.randomUUID(),

    @Column(name = "runner_id", nullable = false)
    var runnerId: UUID = UUID.randomUUID(),

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    var status: OrderStatus = OrderStatus.ACCEPTED,

    @Column(name = "gross_amount", nullable = false, precision = 10, scale = 2)
    var grossAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "platform_fee", nullable = false, precision = 10, scale = 2)
    var platformFee: BigDecimal = BigDecimal.ZERO,

    @Column(name = "runner_payout", nullable = false, precision = 10, scale = 2)
    var runnerPayout: BigDecimal = BigDecimal.ZERO,

    @Column(name = "settled_at")
    var settledAt: OffsetDateTime? = null
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

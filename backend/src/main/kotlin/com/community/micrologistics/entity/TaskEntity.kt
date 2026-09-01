package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.TaskType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.math.BigDecimal
import java.time.OffsetDateTime
import java.util.UUID

@Entity
@Table(name = "tasks")
class TaskEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "creator_id", nullable = false)
    var creatorId: UUID = UUID.randomUUID(),

    @Column(name = "runner_id")
    var runnerId: UUID? = null,

    @Column(name = "community_id")
    var communityId: UUID? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "task_type", nullable = false)
    var taskType: TaskType = TaskType.ERRAND,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    var status: TaskStatus = TaskStatus.OPEN,

    @Column(name = "title", nullable = false)
    var title: String = "",

    @Column(name = "description", nullable = false, length = 1000)
    var description: String = "",

    @Column(name = "pickup_latitude", nullable = false)
    var pickupLatitude: Double = .0,

    @Column(name = "pickup_longitude", nullable = false)
    var pickupLongitude: Double = .0,

    @Column(name = "dropoff_latitude", nullable = false)
    var dropoffLatitude: Double = .0,

    @Column(name = "dropoff_longitude", nullable = false)
    var dropoffLongitude: Double = .0,

    @Column(name = "pickup_floor", nullable = false)
    var pickupFloor: Int = 1,

    @Column(name = "dropoff_floor", nullable = false)
    var dropoffFloor: Int = 1,

    @Column(name = "pickup_has_elevator", nullable = false)
    var pickupHasElevator: Boolean = true,

    @Column(name = "dropoff_has_elevator", nullable = false)
    var dropoffHasElevator: Boolean = true,

    @Column(name = "weight_kg", nullable = false, precision = 10, scale = 2)
    var weightKg: BigDecimal = BigDecimal.ZERO,

    @Column(name = "weather_surcharge", nullable = false, precision = 10, scale = 2)
    var weatherSurcharge: BigDecimal = BigDecimal.ZERO,

    @Column(name = "base_fee", nullable = false, precision = 10, scale = 2)
    var baseFee: BigDecimal = BigDecimal("2.00"),

    @Column(name = "suggested_tip", nullable = false, precision = 10, scale = 2)
    var suggestedTip: BigDecimal = BigDecimal.ZERO,

    @Column(name = "escrow_amount", nullable = false, precision = 10, scale = 2)
    var escrowAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "photo_proof_token")
    var photoProofToken: String? = null,

    @Column(name = "is_public", nullable = false)
    var isPublic: Boolean = true,

    @Column(name = "task_code", unique = true, length = 12)
    var taskCode: String? = null,

    @Column(name = "accepted_at")
    var acceptedAt: OffsetDateTime? = null,

    @Column(name = "completed_at")
    var completedAt: OffsetDateTime? = null

) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

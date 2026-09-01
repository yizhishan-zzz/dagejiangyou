package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.PoolStatus
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.math.BigDecimal
import java.util.UUID

@Entity
@Table(name = "pools")
class PoolEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "creator_id", nullable = false)
    var creatorId: UUID = UUID.randomUUID(),

    @Column(name = "community_id")
    var communityId: UUID? = null,

    @Column(name = "title", nullable = false)
    var title: String = "",

    @Column(name = "store_name", nullable = false)
    var storeName: String = "",

    @Column(name = "category", nullable = false, length = 32)
    var category: String = "社区拼单",

    @Column(name = "summary", nullable = false, length = 200)
    var summary: String = "",

    @Column(name = "pickup_point", nullable = false, length = 120)
    var pickupPoint: String = "",

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    var status: PoolStatus = PoolStatus.OPEN,

    @Column(name = "freight_fee", nullable = false, precision = 10, scale = 2)
    var freightFee: BigDecimal = BigDecimal.ZERO,

    @Column(name = "delivery_fee", nullable = false, precision = 10, scale = 2)
    var deliveryFee: BigDecimal = BigDecimal.ZERO,

    @Column(name = "target_participants", nullable = false)
    var targetParticipants: Int = 2,

    @Column(name = "current_participants", nullable = false)
    var currentParticipants: Int = 1,

    @Column(name = "countdown_minutes", nullable = false)
    var countdownMinutes: Int = 20,

    @Column(name = "shared_fee_per_user", nullable = false, precision = 10, scale = 2)
    var sharedFeePerUser: BigDecimal = BigDecimal.ZERO
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

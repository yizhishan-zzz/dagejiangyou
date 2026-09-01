package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import jakarta.persistence.Version
import java.math.BigDecimal
import java.util.UUID

@Entity
@Table(
    name = "pool_members",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_pool_member", columnNames = ["pool_id", "user_id"])
    ]
)
class PoolMemberEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "pool_id", nullable = false)
    var poolId: UUID = UUID.randomUUID(),

    @Column(name = "user_id", nullable = false)
    var userId: UUID = UUID.randomUUID(),

    @Column(name = "quantity", nullable = false)
    var quantity: Int = 1,

    @Column(name = "item_amount", nullable = false, precision = 10, scale = 2)
    var itemAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "shared_fee_share", nullable = false, precision = 10, scale = 2)
    var sharedFeeShare: BigDecimal = BigDecimal.ZERO,

    @Column(name = "active", nullable = false)
    var active: Boolean = true
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

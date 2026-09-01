package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.OffsetDateTime
import java.util.UUID

@Entity
@Table(name = "ad_slots")
class AdSlotEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(nullable = false, length = 32)
    var placement: String = "HOME_TOP",

    @Column(nullable = false, length = 24)
    var label: String = "社区推荐",

    @Column(nullable = false, length = 120)
    var title: String = "",

    @Column(nullable = false, length = 240)
    var subtitle: String = "",

    @Column(name = "action_label", nullable = false, length = 32)
    var actionLabel: String = "查看",

    @Column(name = "action_route", nullable = false, length = 160)
    var actionRoute: String = "",

    @Column(name = "accent_hex", nullable = false, length = 7)
    var accentHex: String = "#2257D9",

    @Column(name = "image_url", length = 500)
    var imageUrl: String? = null,

    @Column(nullable = false)
    var active: Boolean = true,

    @Column(name = "sort_order", nullable = false)
    var sortOrder: Int = 0,

    @Column(name = "starts_at")
    var startsAt: OffsetDateTime? = null,

    @Column(name = "ends_at")
    var endsAt: OffsetDateTime? = null
) : AuditableEntity()

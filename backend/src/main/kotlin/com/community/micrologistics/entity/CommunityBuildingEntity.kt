package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "community_buildings")
class CommunityBuildingEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "community_id", nullable = false)
    var communityId: UUID = UUID.randomUUID(),

    @Column(nullable = false, length = 64)
    var name: String = "",

    @Column(nullable = false)
    var latitude: Double = .0,

    @Column(nullable = false)
    var longitude: Double = .0,

    @Column(name = "sort_order", nullable = false)
    var sortOrder: Int = 0,

    @Column(nullable = false)
    var active: Boolean = true
) : AuditableEntity()

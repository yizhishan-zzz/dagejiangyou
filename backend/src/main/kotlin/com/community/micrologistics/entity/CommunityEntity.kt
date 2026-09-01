package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "communities")
class CommunityEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(nullable = false, unique = true, length = 64)
    var name: String = "",

    @Column(nullable = false)
    var latitude: Double = .0,

    @Column(nullable = false)
    var longitude: Double = .0,

    @Column(name = "service_radius_meters", nullable = false)
    var serviceRadiusMeters: Int = 500,

    @Column(nullable = false)
    var active: Boolean = true
) : AuditableEntity()

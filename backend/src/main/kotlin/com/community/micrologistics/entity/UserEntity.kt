package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.enums.AccountStatus
import com.community.micrologistics.enums.SystemRole
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
@Table(name = "users")
class UserEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "phone_number", nullable = false, unique = true)
    var phoneNumber: String = "",

    @Column(name = "display_name", nullable = false)
    var displayName: String = "",

    @Column(name = "avatar_emoji", nullable = false, length = 8)
    var avatarEmoji: String = "邻",

    @Column(name = "bio", nullable = false, length = 160)
    var bio: String = "",

    @Column(name = "password_hash", length = 128)
    var passwordHash: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "active_mode", nullable = false)
    var activeMode: UserMode = UserMode.CREATOR,

    @Column(name = "credit_score", nullable = false, precision = 10, scale = 2)
    var creditScore: BigDecimal = BigDecimal("80.00"),

    @Column(name = "creator_enabled", nullable = false)
    var creatorEnabled: Boolean = true,

    @Column(name = "runner_enabled", nullable = false)
    var runnerEnabled: Boolean = true,

    @Column(name = "community_name", length = 64)
    var communityName: String? = null,

    @Column(name = "building_name", length = 64)
    var buildingName: String? = null,

    @Column(name = "room_mask", length = 32)
    var roomMask: String? = null,

    @Column(name = "notifications_enabled", nullable = false)
    var notificationsEnabled: Boolean = true,

    @Column(name = "privacy_masked", nullable = false)
    var privacyMasked: Boolean = true,

    @Column(name = "community_verified", nullable = false)
    var communityVerified: Boolean = false,

    @Column(name = "community_id")
    var communityId: UUID? = null,

    @Column(name = "location_latitude")
    var locationLatitude: Double? = null,

    @Column(name = "location_longitude")
    var locationLongitude: Double? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "system_role", nullable = false, length = 16)
    var systemRole: SystemRole = SystemRole.USER,

    @Enumerated(EnumType.STRING)
    @Column(name = "account_status", nullable = false, length = 16)
    var accountStatus: AccountStatus = AccountStatus.ACTIVE
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

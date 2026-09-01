package com.community.micrologistics.dto.user

import jakarta.validation.constraints.Size
import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.DecimalMin
import java.util.UUID

data class UpdateUserSettingsRequest(
    @field:Size(max = 32)
    val displayName: String? = null,

    @field:Size(max = 8)
    val avatarEmoji: String? = null,

    @field:Size(max = 160)
    val bio: String? = null,

    @field:Size(max = 64)
    val communityName: String? = null,

    val communityId: UUID? = null,

    @field:Size(max = 64)
    val buildingName: String? = null,

    val buildingId: UUID? = null,

    @field:Size(max = 32)
    val roomMask: String? = null,

    val notificationsEnabled: Boolean? = null,

    val privacyMasked: Boolean? = null,

    @field:DecimalMin("-90.0")
    @field:DecimalMax("90.0")
    val latitude: Double? = null,

    @field:DecimalMin("-180.0")
    @field:DecimalMax("180.0")
    val longitude: Double? = null
)

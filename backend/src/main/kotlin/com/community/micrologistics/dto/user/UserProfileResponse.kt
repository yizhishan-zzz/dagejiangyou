package com.community.micrologistics.dto.user

import com.community.micrologistics.enums.UserMode
import java.math.BigDecimal
import java.util.UUID

data class UserProfileResponse(
    val userId: UUID,
    val displayName: String,
    val avatarEmoji: String,
    val bio: String,
    val phoneNumber: String,
    val currentMode: UserMode,
    val creditScore: BigDecimal,
    val communityName: String?,
    val buildingName: String?,
    val roomMask: String?,
    val notificationsEnabled: Boolean,
    val privacyMasked: Boolean,
    val communityVerified: Boolean,
    val latitude: Double?,
    val longitude: Double?,
    val creatorWalletBalance: BigDecimal,
    val creatorFrozenBalance: BigDecimal,
    val runnerWalletBalance: BigDecimal,
    val runnerFrozenBalance: BigDecimal
)

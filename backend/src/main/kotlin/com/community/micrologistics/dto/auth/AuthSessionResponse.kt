package com.community.micrologistics.dto.auth

import com.community.micrologistics.enums.UserMode
import java.math.BigDecimal
import java.util.UUID

data class AuthSessionResponse(
    val userId: UUID,
    val displayName: String,
    val avatarEmoji: String,
    val phoneNumber: String,
    val currentMode: UserMode,
    val creditScore: BigDecimal,
    val communityName: String?,
    val buildingName: String?,
    val accessToken: String,
    val refreshToken: String,
    val tokenType: String = "Bearer",
    val expiresInSeconds: Long
)

package com.community.micrologistics.dto.auth

import com.community.micrologistics.enums.OtpPurpose
import java.time.OffsetDateTime
import java.util.UUID

data class SendOtpResponse(
    val requestId: UUID,
    val phoneNumber: String,
    val purpose: OtpPurpose,
    val otpCode: String?,
    val expiresAt: OffsetDateTime,
    val registered: Boolean
)

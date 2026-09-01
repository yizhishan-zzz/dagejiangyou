package com.community.micrologistics.dto.auth

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import java.util.UUID

data class LoginRequest(
    val requestId: UUID,

    @field:NotBlank
    @field:Pattern(regexp = "^1\\d{10}$", message = "phoneNumber must be a valid mainland China mobile number")
    val phoneNumber: String,

    @field:NotBlank
    @field:Pattern(regexp = "^\\d{6}$", message = "otpCode must be a 6-digit code")
    val otpCode: String
)

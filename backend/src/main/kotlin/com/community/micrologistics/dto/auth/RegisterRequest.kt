package com.community.micrologistics.dto.auth

import jakarta.validation.constraints.AssertTrue
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size

data class RegisterRequest(
    @field:NotBlank
    @field:Pattern(regexp = "^1\\d{10}$", message = "phoneNumber must be a valid mainland China mobile number")
    val phoneNumber: String,

    @field:NotBlank
    @field:Size(min = 8, max = 64)
    val password: String,

    @field:NotBlank
    @field:Size(max = 32)
    val displayName: String,

    @field:Size(max = 64)
    val communityName: String? = null,

    @field:Size(max = 64)
    val buildingName: String? = null,

    @field:AssertTrue(message = "You must accept the service terms and privacy policy")
    val termsAccepted: Boolean
)

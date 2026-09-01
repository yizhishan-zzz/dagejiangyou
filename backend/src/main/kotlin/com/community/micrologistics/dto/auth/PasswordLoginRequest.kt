package com.community.micrologistics.dto.auth

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size

data class PasswordLoginRequest(
    @field:NotBlank
    @field:Pattern(regexp = "^1\\d{10}$", message = "phoneNumber must be a valid mainland China mobile number")
    val phoneNumber: String,

    @field:NotBlank
    @field:Size(min = 6, max = 32)
    val password: String
)

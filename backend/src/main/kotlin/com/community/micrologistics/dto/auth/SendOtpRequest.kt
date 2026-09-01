package com.community.micrologistics.dto.auth

import com.community.micrologistics.enums.OtpPurpose
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern

data class SendOtpRequest(
    @field:NotBlank
    @field:Pattern(regexp = "^1\\d{10}$", message = "phoneNumber must be a valid mainland China mobile number")
    val phoneNumber: String,

    val purpose: OtpPurpose = OtpPurpose.LOGIN
)

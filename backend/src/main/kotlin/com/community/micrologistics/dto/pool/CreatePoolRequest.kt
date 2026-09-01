package com.community.micrologistics.dto.pool

import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.DecimalMin
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.math.BigDecimal

data class CreatePoolRequest(
    @field:NotBlank
    @field:Size(max = 120)
    val title: String,

    @field:NotBlank
    @field:Size(max = 120)
    val storeName: String,

    @field:NotBlank
    @field:Size(max = 32)
    val category: String = "社区拼单",

    @field:NotBlank
    @field:Size(max = 200)
    val summary: String,

    @field:NotBlank
    @field:Size(max = 120)
    val pickupPoint: String,

    @field:DecimalMin("0.0")
    @field:DecimalMax("1000000.0")
    val freightFee: BigDecimal = BigDecimal.ZERO,

    @field:DecimalMin("0.0")
    @field:DecimalMax("1000000.0")
    val deliveryFee: BigDecimal = BigDecimal.ZERO,

    @field:Min(2)
    @field:Max(100)
    val targetParticipants: Int = 6,

    @field:Min(5)
    @field:Max(1440)
    val countdownMinutes: Int = 30
)

package com.community.micrologistics.dto.pool

import jakarta.validation.constraints.DecimalMin
import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.Min
import java.math.BigDecimal

data class JoinPoolRequest(
    @field:Min(1)
    val quantity: Int = 1,

    @field:DecimalMin("0.0")
    @field:DecimalMax("1000000.0")
    val itemAmount: BigDecimal = BigDecimal.ZERO
)

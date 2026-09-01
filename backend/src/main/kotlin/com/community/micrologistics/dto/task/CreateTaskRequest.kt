package com.community.micrologistics.dto.task

import com.community.micrologistics.enums.TaskType
import jakarta.validation.constraints.DecimalMin
import jakarta.validation.constraints.DecimalMax
import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.math.BigDecimal

data class CreateTaskRequest(
    @field:NotBlank
    @field:Size(max = 120)
    val title: String,

    @field:NotBlank
    @field:Size(max = 1000)
    val description: String,

    @field:NotNull
    val taskType: TaskType,

    @field:DecimalMin("0.01")
    @field:DecimalMax("1000.0")
    val baseFee: BigDecimal = BigDecimal("2.00"),

    @field:DecimalMin("0.0")
    @field:DecimalMax("100.0")
    val weightKg: BigDecimal = BigDecimal.ZERO,

    @field:DecimalMin("0.0")
    @field:DecimalMax("1000.0")
    val weatherSurcharge: BigDecimal = BigDecimal.ZERO,

    @field:Min(1)
    @field:Max(99)
    val pickupFloor: Int = 1,

    @field:Min(1)
    @field:Max(99)
    val dropoffFloor: Int = 1,

    val pickupHasElevator: Boolean = true,
    val dropoffHasElevator: Boolean = true,

    val isPublic: Boolean = true,

    val pickupLatitude: Double,
    val pickupLongitude: Double,
    val dropoffLatitude: Double,
    val dropoffLongitude: Double
)

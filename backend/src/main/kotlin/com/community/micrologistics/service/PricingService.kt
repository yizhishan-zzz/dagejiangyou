package com.community.micrologistics.service

import com.community.micrologistics.dto.task.CreateTaskRequest
import com.community.micrologistics.util.MoneyUtils
import org.springframework.stereotype.Service
import java.math.BigDecimal

@Service
class PricingService {
    private val floorUnitRate = BigDecimal("0.50")
    private val weightUnitRate = BigDecimal("0.30")

    fun calculateSuggestedTip(request: CreateTaskRequest): BigDecimal {
        val pickupPenalty = if (request.pickupHasElevator) BigDecimal.ZERO else {
            floorUnitRate.multiply(request.pickupFloor.toBigDecimal())
        }
        val dropoffPenalty = if (request.dropoffHasElevator) BigDecimal.ZERO else {
            floorUnitRate.multiply(request.dropoffFloor.toBigDecimal())
        }
        val weightCharge = weightUnitRate.multiply(request.weightKg)
        val total = request.baseFee
            .add(pickupPenalty)
            .add(dropoffPenalty)
            .add(weightCharge)
            .add(request.weatherSurcharge)
        return MoneyUtils.scale(total)
    }
}

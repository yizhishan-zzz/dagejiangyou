package com.community.micrologistics.dto.pool

import com.community.micrologistics.enums.PoolStatus
import java.math.BigDecimal
import java.util.UUID

data class PoolShowcaseResponse(
    val poolId: UUID,
    val title: String,
    val category: String,
    val storeName: String,
    val summary: String,
    val pickupPoint: String,
    val currentParticipants: Int,
    val targetParticipants: Int,
    val sharedFeePerUser: BigDecimal,
    val countdownMinutes: Int,
    val status: PoolStatus
)

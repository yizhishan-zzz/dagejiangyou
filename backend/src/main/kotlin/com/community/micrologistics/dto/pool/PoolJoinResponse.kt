package com.community.micrologistics.dto.pool

import com.community.micrologistics.enums.PoolStatus
import java.math.BigDecimal
import java.util.UUID

data class PoolJoinResponse(
    val poolId: UUID,
    val currentParticipants: Int,
    val targetParticipants: Int,
    val sharedFeePerUser: BigDecimal,
    val yourSharedFee: BigDecimal,
    val poolStatus: PoolStatus
)

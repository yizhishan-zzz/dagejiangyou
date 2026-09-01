package com.community.micrologistics.dto.task

import java.math.BigDecimal
import java.util.UUID

data class TaskConfirmResponse(
    val taskId: UUID,
    val orderId: UUID,
    val grossAmount: BigDecimal,
    val platformFee: BigDecimal,
    val runnerPayout: BigDecimal
)

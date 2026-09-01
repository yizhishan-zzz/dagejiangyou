package com.community.micrologistics.dto.task

import com.community.micrologistics.enums.TaskType
import com.community.micrologistics.enums.TaskStatus
import java.math.BigDecimal
import java.util.UUID

data class NearbyTaskResponse(
    val taskId: UUID,
    val title: String,
    val description: String,
    val taskType: TaskType,
    val status: TaskStatus,
    val suggestedTip: BigDecimal,
    val distanceMeters: Double,
    val pickupFloor: Int,
    val dropoffFloor: Int
)

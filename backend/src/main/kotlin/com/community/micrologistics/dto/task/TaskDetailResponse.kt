package com.community.micrologistics.dto.task

import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.TaskType
import java.math.BigDecimal
import java.time.OffsetDateTime
import java.util.UUID

data class TaskDetailResponse(
    val taskId: UUID,
    val creatorId: UUID,
    val runnerId: UUID?,
    val taskType: TaskType,
    val status: TaskStatus,
    val title: String,
    val description: String,
    val suggestedTip: BigDecimal,
    val escrowAmount: BigDecimal,
    val pickupFloor: Int,
    val dropoffFloor: Int,
    val pickupHasElevator: Boolean,
    val dropoffHasElevator: Boolean,
    val weightKg: BigDecimal,
    val pickupLatitude: Double?,
    val pickupLongitude: Double?,
    val dropoffLatitude: Double?,
    val dropoffLongitude: Double?,
    val photoProofToken: String?,
    val isPublic: Boolean,
    val taskCode: String?,
    val isCreator: Boolean,
    val isRunner: Boolean,
    val createdAt: OffsetDateTime,
    val acceptedAt: OffsetDateTime?,
    val completedAt: OffsetDateTime?
)

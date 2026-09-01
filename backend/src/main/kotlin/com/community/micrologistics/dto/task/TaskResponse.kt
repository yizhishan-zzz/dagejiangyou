package com.community.micrologistics.dto.task

import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.TaskType
import java.math.BigDecimal
import java.util.UUID

data class TaskResponse(
    val taskId: UUID,
    val creatorId: UUID,
    val runnerId: UUID?,
    val taskType: TaskType,
    val status: TaskStatus,
    val title: String,
    val description: String,
    val suggestedTip: BigDecimal,
    val escrowAmount: BigDecimal,
    val photoProofToken: String?,
    val isPublic: Boolean,
    val taskCode: String?
)

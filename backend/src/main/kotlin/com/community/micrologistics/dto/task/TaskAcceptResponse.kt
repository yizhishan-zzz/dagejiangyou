package com.community.micrologistics.dto.task

import com.community.micrologistics.enums.TaskStatus
import java.util.UUID

data class TaskAcceptResponse(
    val taskId: UUID,
    val orderId: UUID,
    val status: TaskStatus,
    val runnerId: UUID
)

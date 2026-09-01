package com.community.micrologistics.dto.task

import com.community.micrologistics.enums.TaskStatus
import java.util.UUID

data class TaskStatusUpdateResponse(
    val taskId: UUID,
    val status: TaskStatus,
    val proofToken: String?
)

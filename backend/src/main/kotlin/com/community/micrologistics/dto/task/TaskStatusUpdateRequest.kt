package com.community.micrologistics.dto.task

import com.community.micrologistics.enums.TaskStatus
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size

data class TaskStatusUpdateRequest(
    @field:NotNull
    val targetStatus: TaskStatus,
    @field:Size(max = 128)
    val proofToken: String? = null
)

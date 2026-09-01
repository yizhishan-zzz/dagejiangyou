package com.community.micrologistics.dto.admin

import com.community.micrologistics.enums.AccountStatus
import com.community.micrologistics.enums.SystemRole
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.TaskType
import com.community.micrologistics.enums.UserMode
import java.math.BigDecimal
import java.time.OffsetDateTime
import java.util.UUID

data class AdminOverviewResponse(
    val totalUsers: Long,
    val activeUsers: Long,
    val suspendedUsers: Long,
    val openTasks: Long,
    val inProgressTasks: Long,
    val completedTasks: Long
)

data class AdminUserResponse(
    val userId: UUID,
    val phoneNumber: String,
    val displayName: String,
    val activeMode: UserMode,
    val systemRole: SystemRole,
    val accountStatus: AccountStatus,
    val creditScore: BigDecimal,
    val communityName: String?,
    val communityVerified: Boolean,
    val createdAt: OffsetDateTime
)

data class AdminTaskResponse(
    val taskId: UUID,
    val creatorId: UUID,
    val runnerId: UUID?,
    val title: String,
    val taskType: TaskType,
    val status: TaskStatus,
    val suggestedTip: BigDecimal,
    val createdAt: OffsetDateTime
)

data class UpdateAccountStatusRequest(
    val accountStatus: AccountStatus
)

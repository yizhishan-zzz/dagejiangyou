package com.community.micrologistics.service

import com.community.micrologistics.dto.admin.AdminOverviewResponse
import com.community.micrologistics.dto.admin.AdminTaskResponse
import com.community.micrologistics.dto.admin.AdminUserResponse
import com.community.micrologistics.enums.AccountStatus
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.TaskRepository
import com.community.micrologistics.repository.UserRepository
import com.community.micrologistics.repository.VisitLogRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.OffsetDateTime
import java.util.UUID

@Service
class AdminService(
    private val userRepository: UserRepository,
    private val taskRepository: TaskRepository,
    private val visitLogRepository: VisitLogRepository
) {
    @Transactional(readOnly = true)
    fun overview(): AdminOverviewResponse {
        val startOfToday = OffsetDateTime.now().withHour(0).withMinute(0).withSecond(0).withNano(0)
        return AdminOverviewResponse(
            totalUsers = userRepository.count(),
            activeUsers = userRepository.countByAccountStatus(AccountStatus.ACTIVE),
            suspendedUsers = userRepository.countByAccountStatus(AccountStatus.SUSPENDED),
            openTasks = taskRepository.countByStatus(TaskStatus.OPEN),
            inProgressTasks = listOf(TaskStatus.ACCEPTED, TaskStatus.PICKED_UP, TaskStatus.ARRIVED)
                .sumOf(taskRepository::countByStatus),
            completedTasks = taskRepository.countByStatus(TaskStatus.COMPLETED),
            totalVisits = visitLogRepository.count(),
            todayVisits = visitLogRepository.countByCreatedAtGreaterThanEqual(startOfToday)
        )
    }

    @Transactional(readOnly = true)
    fun listUsers(): List<AdminUserResponse> = userRepository.findTop100ByOrderByCreatedAtDesc().map { user ->
        AdminUserResponse(
            userId = user.id,
            phoneNumber = user.phoneNumber,
            displayName = user.displayName,
            activeMode = user.activeMode,
            systemRole = user.systemRole,
            accountStatus = user.accountStatus,
            creditScore = user.creditScore,
            communityName = user.communityName,
            communityVerified = user.communityVerified,
            createdAt = user.createdAt
        )
    }

    @Transactional(readOnly = true)
    fun listTasks(): List<AdminTaskResponse> = taskRepository.findTop100ByOrderByCreatedAtDesc().map { task ->
        AdminTaskResponse(
            taskId = task.id,
            creatorId = task.creatorId,
            runnerId = task.runnerId,
            title = task.title,
            taskType = task.taskType,
            status = task.status,
            suggestedTip = task.suggestedTip,
            createdAt = task.createdAt
        )
    }

    @Transactional
    fun updateAccountStatus(operatorId: UUID, userId: UUID, status: AccountStatus): AdminUserResponse {
        if (operatorId == userId && status != AccountStatus.ACTIVE) {
            throw InvalidOperationException("管理员不能停用当前登录账号")
        }
        val user = userRepository.findByIdForUpdate(userId)
            ?: throw ResourceNotFoundException("User $userId was not found")
        user.accountStatus = status
        val saved = userRepository.save(user)
        return AdminUserResponse(
            userId = saved.id,
            phoneNumber = saved.phoneNumber,
            displayName = saved.displayName,
            activeMode = saved.activeMode,
            systemRole = saved.systemRole,
            accountStatus = saved.accountStatus,
            creditScore = saved.creditScore,
            communityName = saved.communityName,
            communityVerified = saved.communityVerified,
            createdAt = saved.createdAt
        )
    }
}

package com.community.micrologistics.service

import com.community.micrologistics.dto.task.CreateTaskRequest
import com.community.micrologistics.dto.task.NearbyTaskResponse
import com.community.micrologistics.dto.task.TaskAcceptResponse
import com.community.micrologistics.dto.task.TaskConfirmResponse
import com.community.micrologistics.dto.task.TaskDetailResponse
import com.community.micrologistics.dto.task.TaskResponse
import com.community.micrologistics.dto.task.TaskStatusUpdateRequest
import com.community.micrologistics.dto.task.TaskStatusUpdateResponse
import com.community.micrologistics.entity.OrderEntity
import com.community.micrologistics.entity.TaskEntity
import com.community.micrologistics.enums.OrderStatus
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.exception.TaskNotFoundException
import com.community.micrologistics.repository.OrderRepository
import com.community.micrologistics.repository.TaskRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.OffsetDateTime
import java.util.UUID

@Service
class TaskService(
    private val taskRepository: TaskRepository,
    private val orderRepository: OrderRepository,
    private val userService: UserService,
    private val pricingService: PricingService,
    private val geofenceService: GeofenceService,
    private val walletService: WalletService
) {
    @Transactional
    fun createTask(userId: UUID, request: CreateTaskRequest): TaskResponse {
        val creator = userService.requireMode(userId, UserMode.CREATOR)
        geofenceService.validateTaskWithinRadius(
            request.pickupLatitude,
            request.pickupLongitude,
            request.dropoffLatitude,
            request.dropoffLongitude
        )

        val suggestedTip = pricingService.calculateSuggestedTip(request)
        val task = TaskEntity(
            creatorId = userId,
            communityId = creator.communityId,
            taskType = request.taskType,
            status = TaskStatus.OPEN,
            title = request.title.trim(),
            description = request.description.trim(),
            pickupLatitude = request.pickupLatitude,
            pickupLongitude = request.pickupLongitude,
            dropoffLatitude = request.dropoffLatitude,
            dropoffLongitude = request.dropoffLongitude,
            pickupFloor = request.pickupFloor,
            dropoffFloor = request.dropoffFloor,
            pickupHasElevator = request.pickupHasElevator,
            dropoffHasElevator = request.dropoffHasElevator,
            weightKg = request.weightKg,
            weatherSurcharge = request.weatherSurcharge,
            baseFee = request.baseFee,
            suggestedTip = suggestedTip,
            escrowAmount = suggestedTip,
            isPublic = request.isPublic,
            taskCode = generateTaskCode().takeIf { !request.isPublic }
        )

        val savedTask = taskRepository.save(task)
        walletService.freezeCreatorEscrow(userId, suggestedTip, savedTask.id)
        return savedTask.toTaskResponse()
    }

    @Transactional(readOnly = true)
    fun findNearbyTasks(userId: UUID, latitude: Double, longitude: Double): List<NearbyTaskResponse> {
        val viewer = userService.findUser(userId)
        geofenceService.validateCoordinate(latitude, longitude)
        val latitudeDelta = GeofenceService.MAX_SERVICE_RADIUS_METERS / 111_320.0
        val longitudeDelta = GeofenceService.MAX_SERVICE_RADIUS_METERS /
            (111_320.0 * kotlin.math.cos(Math.toRadians(latitude)).coerceAtLeast(0.1))
        return taskRepository.findOpenTasksInBoundingBox(
            status = TaskStatus.OPEN,
            minLatitude = latitude - latitudeDelta,
            maxLatitude = latitude + latitudeDelta,
            minLongitude = (longitude - longitudeDelta).coerceAtLeast(-180.0),
            maxLongitude = (longitude + longitudeDelta).coerceAtMost(180.0),
            pageable = org.springframework.data.domain.Pageable.ofSize(MAX_NEARBY_RESULTS)
        )
            .filter { task ->
                task.creatorId != userId &&
                    (viewer.systemRole.name == "ADMIN" ||
                        (task.communityId != null && task.communityId == viewer.communityId))
            }
            .map { task ->
                val distance = geofenceService.distanceMeters(
                    latitude,
                    longitude,
                    task.pickupLatitude,
                    task.pickupLongitude
                )
                task to distance
            }
            .filter { (_, distance) -> distance <= GeofenceService.MAX_SERVICE_RADIUS_METERS }
            .sortedBy { (_, distance) -> distance }
            .map { (task, distance) ->
                NearbyTaskResponse(
                    taskId = task.id,
                    title = task.title,
                    description = task.description,
                    taskType = task.taskType,
                    status = task.status,
                    suggestedTip = task.suggestedTip,
                    distanceMeters = distance,
                    pickupFloor = task.pickupFloor,
                    dropoffFloor = task.dropoffFloor
                )
            }
    }

    @Transactional(readOnly = true)
    fun getTask(userId: UUID, taskId: UUID): TaskDetailResponse {
        val task = taskRepository.findById(taskId).orElseThrow { TaskNotFoundException(taskId) }
        val viewer = userService.findUser(userId)
        if (viewer.systemRole.name != "ADMIN" && task.communityId != viewer.communityId) {
            throw TaskNotFoundException(taskId)
        }
        if (viewer.systemRole.name != "ADMIN" && !task.isPublic &&
            task.creatorId != userId && task.runnerId != userId
        ) {
            throw TaskNotFoundException(taskId)
        }
        return task.toDetailResponse(userId)
    }

    @Transactional(readOnly = true)
    fun listMyTasks(userId: UUID): List<TaskDetailResponse> {
        val user = userService.findUser(userId)
        val tasks = when (user.activeMode) {
            UserMode.CREATOR -> taskRepository.findAllByCreatorIdOrderByCreatedAtDesc(userId)
            UserMode.RUNNER -> taskRepository.findAllByRunnerIdOrderByCreatedAtDesc(userId)
        }
        return tasks.map { it.toDetailResponse(userId) }
    }
    @Transactional
    fun acceptTask(
        userId: UUID,
        taskId: UUID,
        latitude: Double,
        longitude: Double
    ): TaskAcceptResponse {
        val runner = userService.requireMode(userId, UserMode.RUNNER)
        val task = getTaskForUpdate(taskId)

        if (task.creatorId == userId) {
            throw InvalidOperationException("A user cannot accept a task they created")
        }
        if (runner.systemRole.name != "ADMIN" &&
            (task.communityId == null || task.communityId != runner.communityId)
        ) {
            throw InvalidOperationException("Only users in the task community can accept this task")
        }
        if (task.status != TaskStatus.OPEN || task.runnerId != null) {
            throw InvalidOperationException("Task $taskId is no longer available for acceptance")
        }
        geofenceService.validatePointWithinRadius(
            sourceLatitude = latitude,
            sourceLongitude = longitude,
            targetLatitude = task.pickupLatitude,
            targetLongitude = task.pickupLongitude
        )

        task.runnerId = userId
        task.status = TaskStatus.ACCEPTED
        task.acceptedAt = OffsetDateTime.now()
        taskRepository.save(task)

        val order = orderRepository.findByTaskId(task.id) ?: orderRepository.save(
            OrderEntity(
                taskId = task.id,
                creatorId = task.creatorId,
                runnerId = userId,
                status = OrderStatus.ACCEPTED,
                grossAmount = task.escrowAmount
            )
        )

        return TaskAcceptResponse(
            taskId = task.id,
            orderId = order.id,
            status = task.status,
            runnerId = userId
        )
    }

    @Transactional
    fun acceptTaskByCode(
        userId: UUID,
        rawTaskCode: String,
        latitude: Double,
        longitude: Double
    ): TaskAcceptResponse {
        userService.requireMode(userId, UserMode.RUNNER)
        val taskCode = rawTaskCode.trim().uppercase()
        val task = taskRepository.findByTaskCode(taskCode)
            ?: throw TaskNotFoundException("Private task code is invalid or expired")
        return acceptTask(userId, task.id, latitude, longitude)
    }

    @Transactional
    fun updateTaskStatus(
        userId: UUID,
        taskId: UUID,
        request: TaskStatusUpdateRequest
    ): TaskStatusUpdateResponse {
        userService.requireMode(userId, UserMode.RUNNER)
        val task = getTaskForUpdate(taskId)
        if (task.runnerId != userId) {
            throw InvalidOperationException("Only the assigned runner can update task status")
        }

        val nextStatus = request.targetStatus
        val isValidTransition = when (task.status) {
            TaskStatus.ACCEPTED -> nextStatus == TaskStatus.PICKED_UP
            TaskStatus.PICKED_UP -> nextStatus == TaskStatus.ARRIVED
            else -> false
        }

        if (!isValidTransition) {
            throw InvalidOperationException("Invalid task status transition from ${task.status} to $nextStatus")
        }

        task.status = nextStatus
        if (nextStatus == TaskStatus.ARRIVED) {
            task.photoProofToken = request.proofToken?.takeIf { it.isNotBlank() }
                ?: "proof-${task.id}-${System.currentTimeMillis()}"
        }
        taskRepository.save(task)

        val order = orderRepository.findByTaskId(task.id)
            ?: throw InvalidOperationException("Order for task ${task.id} does not exist")
        order.status = when (nextStatus) {
            TaskStatus.PICKED_UP -> OrderStatus.PICKED_UP
            TaskStatus.ARRIVED -> OrderStatus.ARRIVED
            else -> order.status
        }
        orderRepository.save(order)

        return TaskStatusUpdateResponse(
            taskId = task.id,
            status = task.status,
            proofToken = task.photoProofToken
        )
    }

    @Transactional
    fun confirmTask(userId: UUID, taskId: UUID): TaskConfirmResponse {
        userService.requireMode(userId, UserMode.CREATOR)
        val task = getTaskForUpdate(taskId)
        if (task.creatorId != userId) {
            throw InvalidOperationException("Only the creator can confirm this task")
        }
        if (task.status != TaskStatus.ARRIVED) {
            throw InvalidOperationException("Task must be ARRIVED before confirmation")
        }

        val order = orderRepository.findByTaskId(task.id)
            ?: throw InvalidOperationException("Order for task ${task.id} does not exist")
        val settlement = walletService.releaseEscrowToRunner(
            creatorId = task.creatorId,
            runnerId = task.runnerId
                ?: throw InvalidOperationException("Task ${task.id} has no assigned runner"),
            grossAmount = order.grossAmount,
            referenceId = order.id
        )

        task.status = TaskStatus.COMPLETED
        task.completedAt = OffsetDateTime.now()
        taskRepository.save(task)

        order.status = OrderStatus.COMPLETED
        order.platformFee = settlement.platformFee
        order.runnerPayout = settlement.runnerPayout
        order.settledAt = OffsetDateTime.now()
        orderRepository.save(order)

        return TaskConfirmResponse(
            taskId = task.id,
            orderId = order.id,
            grossAmount = settlement.grossAmount,
            platformFee = settlement.platformFee,
            runnerPayout = settlement.runnerPayout
        )
    }

    @Transactional
    fun cancelTask(userId: UUID, taskId: UUID): TaskDetailResponse {
        userService.requireMode(userId, UserMode.CREATOR)
        val task = getTaskForUpdate(taskId)
        if (task.creatorId != userId) {
            throw InvalidOperationException("Only the creator can cancel this task")
        }
        if (task.status != TaskStatus.OPEN || task.runnerId != null) {
            throw InvalidOperationException("Only an unaccepted task can be cancelled")
        }

        walletService.refundCreatorEscrow(userId, task.escrowAmount, task.id)
        task.status = TaskStatus.CANCELLED
        return taskRepository.save(task).toDetailResponse(userId)
    }

    private fun getTaskForUpdate(taskId: UUID): TaskEntity =
        taskRepository.findByIdForUpdate(taskId) ?: throw TaskNotFoundException(taskId)

    companion object {
        private const val MAX_NEARBY_RESULTS = 200
        private const val TASK_CODE_LENGTH = 8
        private const val TASK_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        private val taskCodeRandom = SecureRandom()
    }

    private fun generateTaskCode(): String {
        repeat(32) {
            val code = buildString(TASK_CODE_LENGTH) {
                repeat(TASK_CODE_LENGTH) {
                    append(TASK_CODE_ALPHABET[taskCodeRandom.nextInt(TASK_CODE_ALPHABET.length)])
                }
            }
            if (!taskRepository.existsByTaskCode(code)) return code
        }
        throw IllegalStateException("Could not allocate a unique private task code")
    }

    private fun TaskEntity.toTaskResponse(): TaskResponse =
        TaskResponse(
            taskId = id,
            creatorId = creatorId,
            runnerId = runnerId,
            taskType = taskType,
            status = status,
            title = title,
            description = description,
            suggestedTip = suggestedTip,
            escrowAmount = escrowAmount,
            photoProofToken = photoProofToken,
            isPublic = isPublic,
            taskCode = taskCode
        )

    private fun TaskEntity.toDetailResponse(userId: UUID): TaskDetailResponse {
        val creator = creatorId == userId
        val runner = runnerId == userId
        val canSeePreciseLocation = creator || runner
        return TaskDetailResponse(
            taskId = id,
            creatorId = creatorId,
            runnerId = runnerId,
            taskType = taskType,
            status = status,
            title = title,
            description = description,
            suggestedTip = suggestedTip,
            escrowAmount = escrowAmount,
            pickupFloor = pickupFloor,
            dropoffFloor = dropoffFloor,
            pickupHasElevator = pickupHasElevator,
            dropoffHasElevator = dropoffHasElevator,
            weightKg = weightKg,
            pickupLatitude = pickupLatitude.takeIf { canSeePreciseLocation },
            pickupLongitude = pickupLongitude.takeIf { canSeePreciseLocation },
            dropoffLatitude = dropoffLatitude.takeIf { canSeePreciseLocation },
            dropoffLongitude = dropoffLongitude.takeIf { canSeePreciseLocation },
            photoProofToken = photoProofToken.takeIf { canSeePreciseLocation },
            isPublic = isPublic,
            taskCode = taskCode.takeIf { creator || runner },
            isCreator = creator,
            isRunner = runner,
            createdAt = createdAt,
            acceptedAt = acceptedAt,
            completedAt = completedAt
        )
    }
}

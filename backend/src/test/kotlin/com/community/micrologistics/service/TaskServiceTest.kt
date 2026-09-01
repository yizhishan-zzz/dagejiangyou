package com.community.micrologistics.service

import com.community.micrologistics.dto.task.CreateTaskRequest
import com.community.micrologistics.entity.OrderEntity
import com.community.micrologistics.entity.TaskEntity
import com.community.micrologistics.entity.UserEntity
import com.community.micrologistics.entity.WalletEntity
import com.community.micrologistics.enums.OrderStatus
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.TaskType
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.enums.WalletType
import com.community.micrologistics.exception.GeofenceViolationException
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.repository.OrderRepository
import com.community.micrologistics.repository.TaskRepository
import com.community.micrologistics.repository.UserRepository
import com.community.micrologistics.repository.WalletRepository
import com.community.micrologistics.repository.WalletTransactionRepository
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.mock
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import java.math.BigDecimal
import java.time.OffsetDateTime
import java.util.Optional
import java.util.UUID

class TaskServiceTest {
    private lateinit var taskRepository: TaskRepository
    private lateinit var orderRepository: OrderRepository
    private lateinit var userRepository: UserRepository
    private lateinit var walletRepository: WalletRepository
    private lateinit var walletTransactionRepository: WalletTransactionRepository

    private lateinit var walletService: WalletService
    private lateinit var userService: UserService
    private lateinit var taskService: TaskService

    @BeforeEach
    fun setUp() {
        taskRepository = mock(TaskRepository::class.java)
        orderRepository = mock(OrderRepository::class.java)
        userRepository = mock(UserRepository::class.java)
        walletRepository = mock(WalletRepository::class.java)
        walletTransactionRepository = mock(WalletTransactionRepository::class.java)

        walletService = WalletService(walletRepository, walletTransactionRepository)
        userService = UserService(userRepository, walletService)
        taskService = TaskService(
            taskRepository = taskRepository,
            orderRepository = orderRepository,
            userService = userService,
            pricingService = PricingService(),
            geofenceService = GeofenceService(),
            walletService = walletService
        )
    }

    @Test
    fun `createTask freezes creator escrow using suggested tip`() {
        val creatorId = UUID.randomUUID()
        val creator = UserEntity(
            id = creatorId,
            phoneNumber = "13800000000",
            displayName = "creator",
            activeMode = UserMode.CREATOR
        )
        val creatorWallet = WalletEntity(
            userId = creatorId,
            walletType = WalletType.CREATOR,
            availableBalance = BigDecimal("100.00"),
            frozenBalance = BigDecimal.ZERO
        )
        val request = CreateTaskRequest(
            title = "Pick up my parcel",
            description = "Deliver a package from gate to building B",
            taskType = TaskType.PACKAGE_PICKUP,
            baseFee = BigDecimal("2.00"),
            weightKg = BigDecimal("2.00"),
            weatherSurcharge = BigDecimal("0.40"),
            pickupFloor = 3,
            dropoffFloor = 4,
            pickupHasElevator = false,
            dropoffHasElevator = false,
            pickupLatitude = 31.2304,
            pickupLongitude = 121.4737,
            dropoffLatitude = 31.2310,
            dropoffLongitude = 121.4740
        )

        `when`(userRepository.findById(creatorId)).thenReturn(Optional.of(creator))
        `when`(
            walletRepository.findByUserIdAndWalletTypeForUpdate(creatorId, WalletType.CREATOR)
        ).thenReturn(creatorWallet)
        `when`(walletRepository.save(any(WalletEntity::class.java))).thenAnswer { it.arguments[0] as WalletEntity }
        `when`(taskRepository.save(any(TaskEntity::class.java))).thenAnswer { it.arguments[0] as TaskEntity }

        val response = taskService.createTask(creatorId, request)

        assertEquals(BigDecimal("6.50"), response.suggestedTip)
        assertEquals(BigDecimal("93.50"), creatorWallet.availableBalance)
        assertEquals(BigDecimal("6.50"), creatorWallet.frozenBalance)
        assertEquals(BigDecimal("6.50"), response.escrowAmount)
        assertEquals(TaskStatus.OPEN, response.status)

        verify(taskRepository, times(1)).save(any(TaskEntity::class.java))
        verify(walletRepository, times(1)).save(creatorWallet)
    }

    @Test
    fun `confirmTask releases frozen escrow and credits runner payout`() {
        val creatorId = UUID.randomUUID()
        val runnerId = UUID.randomUUID()
        val taskId = UUID.randomUUID()
        val orderId = UUID.randomUUID()

        val creator = UserEntity(
            id = creatorId,
            phoneNumber = "13800000000",
            displayName = "creator",
            activeMode = UserMode.CREATOR
        )
        val task = TaskEntity(
            id = taskId,
            creatorId = creatorId,
            runnerId = runnerId,
            taskType = TaskType.ERRAND,
            status = TaskStatus.ARRIVED,
            title = "Buy snacks downstairs",
            description = "Need a quick delivery",
            suggestedTip = BigDecimal("10.00"),
            escrowAmount = BigDecimal("10.00")
        )
        val order = OrderEntity(
            id = orderId,
            taskId = taskId,
            creatorId = creatorId,
            runnerId = runnerId,
            status = OrderStatus.ARRIVED,
            grossAmount = BigDecimal("10.00")
        )
        val creatorWallet = WalletEntity(
            userId = creatorId,
            walletType = WalletType.CREATOR,
            availableBalance = BigDecimal("12.00"),
            frozenBalance = BigDecimal("10.00")
        )
        val runnerWallet = WalletEntity(
            userId = runnerId,
            walletType = WalletType.RUNNER,
            availableBalance = BigDecimal.ZERO,
            frozenBalance = BigDecimal.ZERO
        )

        `when`(userRepository.findById(creatorId)).thenReturn(Optional.of(creator))
        `when`(taskRepository.findByIdForUpdate(taskId)).thenReturn(task)
        `when`(orderRepository.findByTaskId(taskId)).thenReturn(order)
        `when`(
            walletRepository.findByUserIdAndWalletTypeForUpdate(creatorId, WalletType.CREATOR)
        ).thenReturn(creatorWallet)
        `when`(
            walletRepository.findByUserIdAndWalletTypeForUpdate(runnerId, WalletType.RUNNER)
        ).thenReturn(runnerWallet)
        `when`(walletRepository.save(any(WalletEntity::class.java))).thenAnswer { it.arguments[0] as WalletEntity }
        `when`(taskRepository.save(any(TaskEntity::class.java))).thenAnswer { it.arguments[0] as TaskEntity }
        `when`(orderRepository.save(any(OrderEntity::class.java))).thenAnswer { it.arguments[0] as OrderEntity }

        val response = taskService.confirmTask(creatorId, taskId)

        assertEquals(BigDecimal("0.00"), creatorWallet.frozenBalance)
        assertEquals(BigDecimal("9.50"), runnerWallet.availableBalance)
        assertEquals(BigDecimal("0.50"), response.platformFee)
        assertEquals(BigDecimal("9.50"), response.runnerPayout)
        assertEquals(TaskStatus.COMPLETED, task.status)
        assertEquals(OrderStatus.COMPLETED, order.status)
        assertTrue(task.completedAt?.isBefore(OffsetDateTime.now().plusSeconds(1)) == true)

        verify(walletRepository, times(2)).save(any(WalletEntity::class.java))
        verify(taskRepository, times(1)).save(task)
        verify(orderRepository, times(1)).save(order)
    }

    @Test
    fun `acceptTask rejects a runner outside the 500 meter service radius`() {
        val runnerId = UUID.randomUUID()
        val taskId = UUID.randomUUID()
        val communityId = UUID.randomUUID()
        val task = TaskEntity(
            id = taskId,
            creatorId = UUID.randomUUID(),
            communityId = communityId,
            taskType = TaskType.ERRAND,
            status = TaskStatus.OPEN,
            pickupLatitude = 31.2304,
            pickupLongitude = 121.4737,
            dropoffLatitude = 31.2310,
            dropoffLongitude = 121.4740
        )
        val runner = UserEntity(
            id = runnerId,
            phoneNumber = "13800000000",
            displayName = "runner",
            activeMode = UserMode.RUNNER,
            communityId = communityId
        )

        `when`(userRepository.findById(runnerId)).thenReturn(Optional.of(runner))
        `when`(taskRepository.findByIdForUpdate(taskId)).thenReturn(task)

        assertThrows(GeofenceViolationException::class.java) {
            taskService.acceptTask(
                userId = runnerId,
                taskId = taskId,
                latitude = 31.2400,
                longitude = 121.4800
            )
        }

        assertEquals(TaskStatus.OPEN, task.status)
        verify(taskRepository, times(0)).save(any(TaskEntity::class.java))
    }

    @Test
    fun `nearby tasks exclude creator own tasks and other communities`() {
        val userId = UUID.randomUUID()
        val communityId = UUID.randomUUID()
        val otherCommunityId = UUID.randomUUID()
        val user = UserEntity(
            id = userId,
            phoneNumber = "13800000000",
            displayName = "runner",
            activeMode = UserMode.RUNNER,
            communityId = communityId
        )
        val ownTask = TaskEntity(
            creatorId = userId,
            communityId = communityId,
            title = "自己的任务",
            pickupLatitude = 31.2304,
            pickupLongitude = 121.4737,
            dropoffLatitude = 31.2305,
            dropoffLongitude = 121.4738
        )
        val sameCommunityTask = TaskEntity(
            creatorId = UUID.randomUUID(),
            communityId = communityId,
            title = "同社区任务",
            pickupLatitude = 31.2306,
            pickupLongitude = 121.4738,
            dropoffLatitude = 31.2307,
            dropoffLongitude = 121.4739
        )
        val otherCommunityTask = TaskEntity(
            creatorId = UUID.randomUUID(),
            communityId = otherCommunityId,
            title = "其他社区任务",
            pickupLatitude = 31.2306,
            pickupLongitude = 121.4738,
            dropoffLatitude = 31.2307,
            dropoffLongitude = 121.4739
        )

        `when`(userRepository.findById(userId)).thenReturn(Optional.of(user))
        val latitude = 31.2304
        val longitude = 121.4737
        val latitudeDelta = GeofenceService.MAX_SERVICE_RADIUS_METERS / 111_320.0
        val longitudeDelta = GeofenceService.MAX_SERVICE_RADIUS_METERS /
            (111_320.0 * kotlin.math.cos(Math.toRadians(latitude)).coerceAtLeast(0.1))
        `when`(
            taskRepository.findOpenTasksInBoundingBox(
                status = TaskStatus.OPEN,
                minLatitude = latitude - latitudeDelta,
                maxLatitude = latitude + latitudeDelta,
                minLongitude = longitude - longitudeDelta,
                maxLongitude = longitude + longitudeDelta,
                pageable = org.springframework.data.domain.Pageable.ofSize(200)
            )
        ).thenReturn(listOf(ownTask, sameCommunityTask, otherCommunityTask))

        val nearby = taskService.findNearbyTasks(userId, latitude, longitude)

        assertEquals(listOf("同社区任务"), nearby.map { it.title })
    }

    @Test
    fun `acceptTask rejects a runner from another community before changing task`() {
        val runnerId = UUID.randomUUID()
        val taskId = UUID.randomUUID()
        val runner = UserEntity(
            id = runnerId,
            phoneNumber = "13800000000",
            displayName = "runner",
            activeMode = UserMode.RUNNER,
            communityId = UUID.randomUUID()
        )
        val task = TaskEntity(
            id = taskId,
            creatorId = UUID.randomUUID(),
            communityId = UUID.randomUUID(),
            status = TaskStatus.OPEN,
            title = "社区任务",
            pickupLatitude = 31.2304,
            pickupLongitude = 121.4737,
            dropoffLatitude = 31.2305,
            dropoffLongitude = 121.4738
        )

        `when`(userRepository.findById(runnerId)).thenReturn(Optional.of(runner))
        `when`(taskRepository.findByIdForUpdate(taskId)).thenReturn(task)

        assertThrows(InvalidOperationException::class.java) {
            taskService.acceptTask(runnerId, taskId, 31.2304, 121.4737)
        }

        assertEquals(TaskStatus.OPEN, task.status)
        verify(taskRepository, times(0)).save(any(TaskEntity::class.java))
        verify(orderRepository, times(0)).save(any(OrderEntity::class.java))
    }
}

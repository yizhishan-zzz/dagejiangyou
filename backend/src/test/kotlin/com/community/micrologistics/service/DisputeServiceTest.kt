package com.community.micrologistics.service

import com.community.micrologistics.dto.dispute.CreateDisputeRequest
import com.community.micrologistics.dto.dispute.ResolveDisputeRequest
import com.community.micrologistics.entity.DisputeTicketEntity
import com.community.micrologistics.entity.TaskEntity
import com.community.micrologistics.entity.UserEntity
import com.community.micrologistics.enums.DisputeStatus
import com.community.micrologistics.enums.SystemRole
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.enums.TaskType
import com.community.micrologistics.repository.DisputeTicketRepository
import com.community.micrologistics.repository.TaskRepository
import com.community.micrologistics.repository.UserRepository
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import java.util.Optional
import java.util.UUID

class DisputeServiceTest {
    private lateinit var disputeRepository: DisputeTicketRepository
    private lateinit var taskRepository: TaskRepository
    private lateinit var userRepository: UserRepository
    private lateinit var disputeService: DisputeService

    @BeforeEach
    fun setUp() {
        disputeRepository = mock(DisputeTicketRepository::class.java)
        taskRepository = mock(TaskRepository::class.java)
        userRepository = mock(UserRepository::class.java)
        disputeService = DisputeService(disputeRepository, taskRepository, userRepository)
    }

    @Test
    fun `participant can open a dispute with optional proof`() {
        val creatorId = UUID.randomUUID()
        val runnerId = UUID.randomUUID()
        val task = TaskEntity(
            creatorId = creatorId,
            runnerId = runnerId,
            taskType = TaskType.ERRAND,
            status = TaskStatus.COMPLETED,
            title = "社区帮办"
        )
        val creator = UserEntity(
            id = creatorId,
            phoneNumber = "13800000000",
            displayName = "creator"
        )
        val request = CreateDisputeRequest(
            taskId = task.id,
            reason = "服务异常",
            description = "实际交付与约定不一致",
            proofToken = "proof-123"
        )

        `when`(taskRepository.findById(task.id)).thenReturn(Optional.of(task))
        `when`(disputeRepository.existsByTaskIdAndOpenedBy(task.id, creatorId)).thenReturn(false)
        `when`(userRepository.findById(creatorId)).thenReturn(Optional.of(creator))
        `when`(disputeRepository.save(any(DisputeTicketEntity::class.java))).thenAnswer { it.arguments[0] }

        val response = disputeService.create(creatorId, request)

        assertEquals(DisputeStatus.OPEN, response.status)
        assertEquals(runnerId, response.againstUserId)
        assertEquals("proof-123", response.proofToken)
    }

    @Test
    fun `only an active administrator can resolve a dispute`() {
        val adminId = UUID.randomUUID()
        val dispute = DisputeTicketEntity()
        val admin = UserEntity(
            id = adminId,
            phoneNumber = "13800000099",
            displayName = "admin",
            systemRole = SystemRole.ADMIN
        )

        `when`(userRepository.findById(adminId)).thenReturn(Optional.of(admin))
        `when`(disputeRepository.findByIdForUpdate(dispute.id)).thenReturn(dispute)
        `when`(disputeRepository.save(any(DisputeTicketEntity::class.java))).thenAnswer { it.arguments[0] }

        val response = disputeService.resolve(
            adminId,
            dispute.id,
            ResolveDisputeRequest(DisputeStatus.RESOLVED, "已核实并完成处理")
        )

        assertEquals(DisputeStatus.RESOLVED, response.status)
        assertEquals(adminId, response.resolvedBy)
    }

    @Test
    fun `non administrator cannot resolve a dispute`() {
        val userId = UUID.randomUUID()
        val user = UserEntity(
            id = userId,
            phoneNumber = "13800000000",
            displayName = "user"
        )
        `when`(userRepository.findById(userId)).thenReturn(Optional.of(user))

        assertThrows(RuntimeException::class.java) {
            disputeService.resolve(
                userId,
                UUID.randomUUID(),
                ResolveDisputeRequest(DisputeStatus.REJECTED, "信息不足")
            )
        }
    }
}

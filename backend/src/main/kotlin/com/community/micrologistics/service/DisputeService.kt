package com.community.micrologistics.service

import com.community.micrologistics.dto.dispute.CreateDisputeRequest
import com.community.micrologistics.dto.dispute.DisputeResponse
import com.community.micrologistics.dto.dispute.ResolveDisputeRequest
import com.community.micrologistics.entity.DisputeTicketEntity
import com.community.micrologistics.enums.AccountStatus
import com.community.micrologistics.enums.DisputeStatus
import com.community.micrologistics.enums.SystemRole
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.DisputeTicketRepository
import com.community.micrologistics.repository.TaskRepository
import com.community.micrologistics.repository.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.OffsetDateTime
import java.util.UUID

@Service
class DisputeService(
    private val disputeRepository: DisputeTicketRepository,
    private val taskRepository: TaskRepository,
    private val userRepository: UserRepository
) {
    @Transactional
    fun create(userId: UUID, request: CreateDisputeRequest): DisputeResponse {
        val task = taskRepository.findById(request.taskId)
            .orElseThrow { ResourceNotFoundException("Task ${request.taskId} was not found") }
        val againstUserId = when (userId) {
            task.creatorId -> task.runnerId
            task.runnerId -> task.creatorId
            else -> null
        } ?: throw InvalidOperationException("Only task participants can open a dispute")

        if (task.status == TaskStatus.CANCELLED) {
            throw InvalidOperationException("A cancelled task cannot open a dispute")
        }
        if (disputeRepository.existsByTaskIdAndOpenedBy(task.id, userId)) {
            throw InvalidOperationException("You have already opened a dispute for this task")
        }

        userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException("User $userId was not found") }
        return disputeRepository.save(
            DisputeTicketEntity(
                taskId = task.id,
                openedBy = userId,
                againstUserId = againstUserId,
                reason = request.reason.trim(),
                description = request.description.trim(),
                proofToken = request.proofToken?.trim()?.takeIf { it.isNotEmpty() }
            )
        ).toResponse()
    }

    @Transactional(readOnly = true)
    fun listMine(userId: UUID): List<DisputeResponse> =
        disputeRepository.findAllByOpenedByOrAgainstUserIdOrderByCreatedAtDesc(userId, userId)
            .map { it.toResponse() }

    @Transactional(readOnly = true)
    fun listForAdmin(): List<DisputeResponse> =
        disputeRepository.findAllByStatusInOrderByCreatedAtAsc(
            listOf(DisputeStatus.OPEN, DisputeStatus.UNDER_REVIEW)
        ).map { it.toResponse() }

    @Transactional
    fun resolve(adminId: UUID, disputeId: UUID, request: ResolveDisputeRequest): DisputeResponse {
        if (request.status == DisputeStatus.OPEN) {
            throw InvalidOperationException("A dispute cannot be reopened by an administrator")
        }
        val admin = userRepository.findById(adminId)
            .orElseThrow { ResourceNotFoundException("User $adminId was not found") }
        if (admin.systemRole != SystemRole.ADMIN || admin.accountStatus != AccountStatus.ACTIVE) {
            throw InvalidOperationException("Only an active administrator can process disputes")
        }
        val dispute = disputeRepository.findByIdForUpdate(disputeId)
            ?: throw ResourceNotFoundException("Dispute $disputeId was not found")
        if (dispute.status == DisputeStatus.RESOLVED || dispute.status == DisputeStatus.REJECTED) {
            throw InvalidOperationException("Dispute $disputeId has already been closed")
        }
        dispute.status = request.status
        dispute.resolutionNote = request.resolutionNote.trim()
        if (request.status == DisputeStatus.UNDER_REVIEW) {
            dispute.resolvedBy = null
            dispute.resolvedAt = null
        } else {
            dispute.resolvedBy = adminId
            dispute.resolvedAt = OffsetDateTime.now()
        }
        return disputeRepository.save(dispute).toResponse()
    }

    private fun DisputeTicketEntity.toResponse() = DisputeResponse(
        disputeId = id,
        taskId = taskId,
        openedBy = openedBy,
        againstUserId = againstUserId,
        reason = reason,
        description = description,
        proofToken = proofToken,
        status = status,
        resolutionNote = resolutionNote,
        resolvedBy = resolvedBy,
        resolvedAt = resolvedAt,
        createdAt = createdAt
    )
}

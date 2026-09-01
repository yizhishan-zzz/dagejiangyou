package com.community.micrologistics.service

import com.community.micrologistics.dto.review.CreateReviewRequest
import com.community.micrologistics.dto.review.ReviewResponse
import com.community.micrologistics.entity.ReviewEntity
import com.community.micrologistics.enums.TaskStatus
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.ReviewRepository
import com.community.micrologistics.repository.TaskRepository
import com.community.micrologistics.repository.UserRepository
import com.community.micrologistics.util.MoneyUtils
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.OffsetDateTime
import java.util.UUID

@Service
class ReviewService(
    private val reviewRepository: ReviewRepository,
    private val taskRepository: TaskRepository,
    private val userRepository: UserRepository,
    private val userService: UserService
) {
    @Transactional
    fun createReview(userId: UUID, request: CreateReviewRequest): ReviewResponse {
        val task = taskRepository.findById(request.taskId)
            .orElseThrow { ResourceNotFoundException("Task ${request.taskId} was not found") }
        if (task.status != TaskStatus.COMPLETED) {
            throw InvalidOperationException("Reviews are available after task completion")
        }
        val runnerId = task.runnerId
            ?: throw InvalidOperationException("Completed task has no assigned runner")
        val targetId = when (userId) {
            task.creatorId -> runnerId
            runnerId -> task.creatorId
            else -> throw InvalidOperationException("Only task participants can submit a review")
        }
        if (reviewRepository.existsByTaskIdAndFromUserId(task.id, userId)) {
            throw InvalidOperationException("You have already reviewed this task")
        }

        userService.findUser(userId)
        val saved = reviewRepository.save(
            ReviewEntity(
                taskId = task.id,
                fromUserId = userId,
                toUserId = targetId,
                rating = request.rating,
                comment = request.comment?.trim()?.takeIf { it.isNotEmpty() }
            )
        )

        val since = OffsetDateTime.now().minusDays(180)
        val average = reviewRepository.averageRatingForUserSince(targetId, since)
            ?: request.rating.toDouble()
        val creditScore = MoneyUtils.scale(
            BigDecimal.valueOf(average * 20.0).coerceIn(BigDecimal.ZERO, BigDecimal("100.00"))
        )
        val target = userRepository.findByIdForUpdate(targetId)
            ?: throw ResourceNotFoundException("User $targetId was not found")
        target.creditScore = creditScore
        userRepository.save(target)

        return saved.toResponse(creditScore)
    }

    @Transactional(readOnly = true)
    fun listTaskReviews(userId: UUID, taskId: UUID): List<ReviewResponse> {
        val task = taskRepository.findById(taskId)
            .orElseThrow { ResourceNotFoundException("Task $taskId was not found") }
        if (task.creatorId != userId && task.runnerId != userId) {
            throw InvalidOperationException("Only task participants can view reviews")
        }
        return reviewRepository.findAllByTaskIdOrderByCreatedAtAsc(taskId)
            .map { it.toResponse(null) }
    }

    private fun ReviewEntity.toResponse(targetCreditScore: BigDecimal?) = ReviewResponse(
        reviewId = id,
        taskId = taskId,
        fromUserId = fromUserId,
        toUserId = toUserId,
        rating = rating,
        comment = comment,
        createdAt = createdAt,
        targetCreditScore = targetCreditScore
    )
}

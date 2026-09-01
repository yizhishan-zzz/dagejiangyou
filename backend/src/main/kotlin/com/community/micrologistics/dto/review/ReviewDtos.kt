package com.community.micrologistics.dto.review

import jakarta.validation.constraints.Max
import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.OffsetDateTime
import java.util.UUID

data class CreateReviewRequest(
    @field:NotNull
    val taskId: UUID,

    @field:Min(1)
    @field:Max(5)
    val rating: Int,

    @field:Size(max = 500)
    val comment: String? = null
)

data class ReviewResponse(
    val reviewId: UUID,
    val taskId: UUID,
    val fromUserId: UUID,
    val toUserId: UUID,
    val rating: Int,
    val comment: String?,
    val createdAt: OffsetDateTime,
    val targetCreditScore: java.math.BigDecimal?
)

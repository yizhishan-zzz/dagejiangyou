package com.community.micrologistics.controller

import com.community.micrologistics.dto.review.CreateReviewRequest
import com.community.micrologistics.dto.review.ReviewResponse
import com.community.micrologistics.security.AppPrincipal
import com.community.micrologistics.service.ReviewService
import jakarta.validation.Valid
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/api/v1/reviews")
class ReviewController(
    private val reviewService: ReviewService
) {
    @PostMapping
    fun createReview(
        @AuthenticationPrincipal principal: AppPrincipal,
        @Valid @RequestBody request: CreateReviewRequest
    ): ReviewResponse = reviewService.createReview(principal.userId, request)

    @GetMapping("/tasks/{taskId}")
    fun listTaskReviews(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable taskId: UUID
    ): List<ReviewResponse> = reviewService.listTaskReviews(principal.userId, taskId)
}

package com.community.micrologistics.controller

import com.community.micrologistics.dto.dispute.CreateDisputeRequest
import com.community.micrologistics.dto.dispute.DisputeResponse
import com.community.micrologistics.security.AppPrincipal
import com.community.micrologistics.service.DisputeService
import jakarta.validation.Valid
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/disputes")
class DisputeController(
    private val disputeService: DisputeService
) {
    @PostMapping
    fun create(
        @AuthenticationPrincipal principal: AppPrincipal,
        @Valid @RequestBody request: CreateDisputeRequest
    ): DisputeResponse = disputeService.create(principal.userId, request)

    @GetMapping("/mine")
    fun mine(@AuthenticationPrincipal principal: AppPrincipal): List<DisputeResponse> =
        disputeService.listMine(principal.userId)
}

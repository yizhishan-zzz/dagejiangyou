package com.community.micrologistics.controller

import com.community.micrologistics.dto.admin.AdminOverviewResponse
import com.community.micrologistics.dto.admin.AdminTaskResponse
import com.community.micrologistics.dto.admin.AdminUserResponse
import com.community.micrologistics.dto.ad.AdSlotResponse
import com.community.micrologistics.dto.admin.UpdateAccountStatusRequest
import com.community.micrologistics.dto.dispute.DisputeResponse
import com.community.micrologistics.dto.dispute.ResolveDisputeRequest
import com.community.micrologistics.security.AppPrincipal
import com.community.micrologistics.service.AdminService
import com.community.micrologistics.service.AdSlotService
import com.community.micrologistics.service.DisputeService
import jakarta.validation.Valid
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/api/v1/admin")
class AdminController(
    private val adminService: AdminService,
    private val disputeService: DisputeService,
    private val adSlotService: AdSlotService
) {
    @GetMapping("/overview")
    fun overview(): AdminOverviewResponse = adminService.overview()

    @GetMapping("/users")
    fun users(): List<AdminUserResponse> = adminService.listUsers()

    @GetMapping("/tasks")
    fun tasks(): List<AdminTaskResponse> = adminService.listTasks()

    @PatchMapping("/users/{id}/status")
    fun updateUserStatus(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateAccountStatusRequest
    ): AdminUserResponse = adminService.updateAccountStatus(principal.userId, id, request.accountStatus)

    @GetMapping("/disputes")
    fun disputes(): List<DisputeResponse> = disputeService.listForAdmin()

    @GetMapping("/ad-slots")
    fun adSlots(): List<AdSlotResponse> = adSlotService.listAll()

    @PatchMapping("/disputes/{id}")
    fun resolveDispute(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID,
        @Valid @RequestBody request: ResolveDisputeRequest
    ): DisputeResponse = disputeService.resolve(principal.userId, id, request)
}

package com.community.micrologistics.controller

import com.community.micrologistics.dto.pool.JoinPoolRequest
import com.community.micrologistics.dto.pool.CreatePoolRequest
import com.community.micrologistics.dto.pool.PoolJoinResponse
import com.community.micrologistics.dto.pool.PoolShowcaseResponse
import com.community.micrologistics.service.PoolService
import com.community.micrologistics.security.AppPrincipal
import jakarta.validation.Valid
import org.springframework.validation.annotation.Validated
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.security.core.annotation.AuthenticationPrincipal
import java.util.UUID

@Validated
@RestController
@RequestMapping("/api/v1/pools")
class PoolController(
    private val poolService: PoolService
) {
    @PostMapping
    fun createPool(
        @AuthenticationPrincipal principal: AppPrincipal,
        @Valid @RequestBody request: CreatePoolRequest
    ): PoolShowcaseResponse = poolService.createPool(principal.userId, request)

    @GetMapping("/showcase")
    fun showcasePools(
        @AuthenticationPrincipal principal: AppPrincipal
    ): List<PoolShowcaseResponse> = poolService.listShowcasePools(principal.userId)

    @PostMapping("/{id}/join")
    fun joinPool(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID,
        @Valid @RequestBody request: JoinPoolRequest
    ): PoolJoinResponse = poolService.joinPool(principal.userId, id, request)
}

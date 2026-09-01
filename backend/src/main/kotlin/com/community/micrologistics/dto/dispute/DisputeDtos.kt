package com.community.micrologistics.dto.dispute

import com.community.micrologistics.enums.DisputeStatus
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.OffsetDateTime
import java.util.UUID

data class CreateDisputeRequest(
    @field:NotNull
    val taskId: UUID,

    @field:NotBlank
    @field:Size(max = 64)
    val reason: String,

    @field:NotBlank
    @field:Size(max = 1000)
    val description: String,

    @field:Size(max = 128)
    val proofToken: String? = null
)

data class ResolveDisputeRequest(
    @field:NotNull
    val status: DisputeStatus,

    @field:NotBlank
    @field:Size(max = 1000)
    val resolutionNote: String
)

data class DisputeResponse(
    val disputeId: UUID,
    val taskId: UUID,
    val openedBy: UUID,
    val againstUserId: UUID,
    val reason: String,
    val description: String,
    val proofToken: String?,
    val status: DisputeStatus,
    val resolutionNote: String?,
    val resolvedBy: UUID?,
    val resolvedAt: OffsetDateTime?,
    val createdAt: OffsetDateTime
)

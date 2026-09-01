package com.community.micrologistics.dto.chat

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.NotNull
import jakarta.validation.constraints.Size
import java.time.OffsetDateTime
import java.util.UUID

data class SendChatMessageRequest(
    @field:NotNull
    val receiverId: UUID,

    val taskId: UUID? = null,

    @field:NotBlank
    @field:Size(max = 2000)
    val body: String
)

data class ChatMessageResponse(
    val messageId: UUID,
    val taskId: UUID?,
    val senderId: UUID,
    val receiverId: UUID,
    val body: String,
    val readAt: OffsetDateTime?,
    val createdAt: OffsetDateTime
)

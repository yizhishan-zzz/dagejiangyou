package com.community.micrologistics.controller

import com.community.micrologistics.dto.chat.ChatMessageResponse
import com.community.micrologistics.dto.chat.SendChatMessageRequest
import com.community.micrologistics.security.AppPrincipal
import com.community.micrologistics.service.ChatService
import jakarta.validation.Valid
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PatchMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/api/v1/chats")
class ChatController(
    private val chatService: ChatService
) {
    @GetMapping
    fun listMessages(
        @AuthenticationPrincipal principal: AppPrincipal,
        @RequestParam(required = false) taskId: UUID?,
        @RequestParam(required = false) peerId: UUID?
    ): List<ChatMessageResponse> = chatService.listMessages(principal.userId, taskId, peerId)

    @PostMapping
    fun sendMessage(
        @AuthenticationPrincipal principal: AppPrincipal,
        @Valid @RequestBody request: SendChatMessageRequest
    ): ChatMessageResponse = chatService.sendMessage(principal.userId, request)

    @PatchMapping("/{id}/read")
    fun markRead(
        @AuthenticationPrincipal principal: AppPrincipal,
        @PathVariable id: UUID
    ): ChatMessageResponse = chatService.markRead(principal.userId, id)
}

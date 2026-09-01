package com.community.micrologistics.service

import com.community.micrologistics.dto.chat.ChatMessageResponse
import com.community.micrologistics.dto.chat.SendChatMessageRequest
import com.community.micrologistics.entity.ChatEntity
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.ChatRepository
import com.community.micrologistics.repository.TaskRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.OffsetDateTime
import java.util.UUID

@Service
class ChatService(
    private val chatRepository: ChatRepository,
    private val taskRepository: TaskRepository,
    private val userService: UserService
) {
    @Transactional(readOnly = true)
    fun listMessages(userId: UUID, taskId: UUID?, peerId: UUID?): List<ChatMessageResponse> {
        userService.findUser(userId)
        val messages = if (taskId != null) {
            val task = taskRepository.findById(taskId)
                .orElseThrow { ResourceNotFoundException("Task $taskId was not found") }
            ensureTaskParty(task.creatorId, task.runnerId, userId)
            chatRepository.findTaskConversation(taskId, userId)
        } else {
            val peer = peerId ?: throw InvalidOperationException("taskId or peerId is required")
            if (peer == userId) throw InvalidOperationException("A user cannot chat with themselves")
            userService.findUser(peer)
            chatRepository.findDirectConversation(userId, peer)
        }
        return messages.map { it.toResponse() }
    }

    @Transactional
    fun sendMessage(userId: UUID, request: SendChatMessageRequest): ChatMessageResponse {
        if (userId == request.receiverId) {
            throw InvalidOperationException("A user cannot chat with themselves")
        }
        val sender = userService.findUser(userId)
        val receiver = userService.findUser(request.receiverId)
        if (request.taskId == null &&
            (sender.communityId == null || sender.communityId != receiver.communityId)
        ) {
            throw InvalidOperationException("Only users in the same community can start a direct conversation")
        }

        request.taskId?.let { taskId ->
            val task = taskRepository.findById(taskId)
                .orElseThrow { ResourceNotFoundException("Task $taskId was not found") }
            ensureTaskParty(task.creatorId, task.runnerId, userId)
            ensureTaskParty(task.creatorId, task.runnerId, request.receiverId)
        }

        return chatRepository.save(
            ChatEntity(
                taskId = request.taskId,
                senderId = userId,
                receiverId = request.receiverId,
                body = request.body.trim()
            )
        ).toResponse()
    }

    @Transactional
    fun markRead(userId: UUID, messageId: UUID): ChatMessageResponse {
        val message = chatRepository.findById(messageId)
            .orElseThrow { ResourceNotFoundException("Message $messageId was not found") }
        if (message.receiverId != userId) {
            throw InvalidOperationException("Only the receiver can mark a message as read")
        }
        message.readAt = message.readAt ?: OffsetDateTime.now()
        return chatRepository.save(message).toResponse()
    }

    private fun ensureTaskParty(creatorId: UUID, runnerId: UUID?, userId: UUID) {
        if (creatorId != userId && runnerId != userId) {
            throw InvalidOperationException("Only the task participants can access this conversation")
        }
    }

    private fun ChatEntity.toResponse() = ChatMessageResponse(
        messageId = id,
        taskId = taskId,
        senderId = senderId,
        receiverId = receiverId,
        body = body,
        readAt = readAt,
        createdAt = createdAt
    )
}

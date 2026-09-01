package com.community.micrologistics.repository

import com.community.micrologistics.entity.ChatEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface ChatRepository : JpaRepository<ChatEntity, UUID> {
    @Query(
        "select c from ChatEntity c " +
            "where c.taskId = :taskId and (c.senderId = :userId or c.receiverId = :userId) " +
            "order by c.createdAt asc"
    )
    fun findTaskConversation(
        @Param("taskId") taskId: UUID,
        @Param("userId") userId: UUID
    ): List<ChatEntity>

    @Query(
        "select c from ChatEntity c " +
            "where c.taskId is null " +
            "and ((c.senderId = :userId and c.receiverId = :peerId) " +
            "or (c.senderId = :peerId and c.receiverId = :userId)) " +
            "order by c.createdAt asc"
    )
    fun findDirectConversation(
        @Param("userId") userId: UUID,
        @Param("peerId") peerId: UUID
    ): List<ChatEntity>
}

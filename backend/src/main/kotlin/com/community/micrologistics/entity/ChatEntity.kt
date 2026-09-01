package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.time.OffsetDateTime
import java.util.UUID

@Entity
@Table(name = "chats")
class ChatEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "task_id")
    var taskId: UUID? = null,

    @Column(name = "sender_id", nullable = false)
    var senderId: UUID = UUID.randomUUID(),

    @Column(name = "receiver_id", nullable = false)
    var receiverId: UUID = UUID.randomUUID(),

    @Column(name = "body", nullable = false, length = 2000)
    var body: String = "",

    @Column(name = "read_at")
    var readAt: OffsetDateTime? = null
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

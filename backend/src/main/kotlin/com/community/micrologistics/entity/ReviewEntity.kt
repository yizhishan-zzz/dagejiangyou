package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import jakarta.persistence.Version
import java.util.UUID

@Entity
@Table(
    name = "reviews",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_review_task_from", columnNames = ["task_id", "from_user_id"])
    ]
)
class ReviewEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "task_id", nullable = false)
    var taskId: UUID = UUID.randomUUID(),

    @Column(name = "from_user_id", nullable = false)
    var fromUserId: UUID = UUID.randomUUID(),

    @Column(name = "to_user_id", nullable = false)
    var toUserId: UUID = UUID.randomUUID(),

    @Column(name = "rating", nullable = false)
    var rating: Int = 5,

    @Column(name = "comment", length = 500)
    var comment: String? = null
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

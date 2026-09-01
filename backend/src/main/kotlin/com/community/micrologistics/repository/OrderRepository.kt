package com.community.micrologistics.repository

import com.community.micrologistics.entity.OrderEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface OrderRepository : JpaRepository<OrderEntity, UUID> {
    fun findByTaskId(taskId: UUID): OrderEntity?
}

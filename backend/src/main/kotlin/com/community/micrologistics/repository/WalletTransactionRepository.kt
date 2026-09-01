package com.community.micrologistics.repository

import com.community.micrologistics.entity.WalletTransactionEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface WalletTransactionRepository : JpaRepository<WalletTransactionEntity, UUID> {
    fun existsByIdempotencyKey(idempotencyKey: String): Boolean
}

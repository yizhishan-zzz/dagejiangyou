package com.community.micrologistics.repository

import com.community.micrologistics.entity.WalletEntity
import com.community.micrologistics.enums.WalletType
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface WalletRepository : JpaRepository<WalletEntity, UUID> {
    fun findByUserIdAndWalletType(userId: UUID, walletType: WalletType): WalletEntity?

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query(
        "select w from WalletEntity w " +
            "where w.userId = :userId and w.walletType = :walletType"
    )
    fun findByUserIdAndWalletTypeForUpdate(
        @Param("userId") userId: UUID,
        @Param("walletType") walletType: WalletType
    ): WalletEntity?
}

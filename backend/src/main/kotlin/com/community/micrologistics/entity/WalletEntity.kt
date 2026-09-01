package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.WalletType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import jakarta.persistence.Version
import java.math.BigDecimal
import java.util.UUID

@Entity
@Table(
    name = "wallets",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_wallet_user_type", columnNames = ["user_id", "wallet_type"])
    ]
)
class WalletEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "user_id", nullable = false)
    var userId: UUID = UUID.randomUUID(),

    @Enumerated(EnumType.STRING)
    @Column(name = "wallet_type", nullable = false)
    var walletType: WalletType = WalletType.CREATOR,

    @Column(name = "available_balance", nullable = false, precision = 12, scale = 2)
    var availableBalance: BigDecimal = BigDecimal.ZERO,

    @Column(name = "frozen_balance", nullable = false, precision = 12, scale = 2)
    var frozenBalance: BigDecimal = BigDecimal.ZERO
) : AuditableEntity() {
    @Version
    @Column(name = "version", nullable = false)
    var version: Long = 0
}

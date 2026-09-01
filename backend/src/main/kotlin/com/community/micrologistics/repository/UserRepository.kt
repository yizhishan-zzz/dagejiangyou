package com.community.micrologistics.repository

import com.community.micrologistics.entity.UserEntity
import com.community.micrologistics.enums.AccountStatus
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface UserRepository : JpaRepository<UserEntity, UUID> {
    fun findByPhoneNumber(phoneNumber: String): UserEntity?
    fun findTop100ByOrderByCreatedAtDesc(): List<UserEntity>
    fun countByAccountStatus(accountStatus: AccountStatus): Long

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from UserEntity u where u.id = :id")
    fun findByIdForUpdate(@Param("id") id: UUID): UserEntity?
}

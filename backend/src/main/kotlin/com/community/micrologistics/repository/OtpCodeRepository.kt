package com.community.micrologistics.repository

import com.community.micrologistics.entity.OtpCodeEntity
import com.community.micrologistics.enums.OtpPurpose
import jakarta.persistence.LockModeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface OtpCodeRepository : JpaRepository<OtpCodeEntity, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from OtpCodeEntity o where o.id = :id")
    fun findByIdForUpdate(@Param("id") id: UUID): OtpCodeEntity?

    fun findTopByPhoneNumberAndPurposeOrderByCreatedAtDesc(
        phoneNumber: String,
        purpose: OtpPurpose
    ): OtpCodeEntity?
}

package com.community.micrologistics.entity

import com.community.micrologistics.entity.base.AuditableEntity
import com.community.micrologistics.enums.OtpPurpose
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.OffsetDateTime
import java.util.UUID

@Entity
@Table(name = "auth_otp_codes")
class OtpCodeEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "phone_number", nullable = false)
    var phoneNumber: String = "",

    @Enumerated(EnumType.STRING)
    @Column(name = "purpose", nullable = false)
    var purpose: OtpPurpose = OtpPurpose.LOGIN,

    @Column(name = "otp_code", nullable = false, length = 6)
    var otpCode: String = "",

    @Column(name = "expires_at", nullable = false)
    var expiresAt: OffsetDateTime = OffsetDateTime.now().plusMinutes(5),

    @Column(name = "consumed_at")
    var consumedAt: OffsetDateTime? = null
) : AuditableEntity()

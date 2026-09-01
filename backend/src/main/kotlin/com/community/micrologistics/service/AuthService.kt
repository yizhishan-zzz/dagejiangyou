package com.community.micrologistics.service

import com.community.micrologistics.dto.auth.AuthSessionResponse
import com.community.micrologistics.dto.auth.LoginRequest
import com.community.micrologistics.dto.auth.PasswordLoginRequest
import com.community.micrologistics.dto.auth.RefreshTokenRequest
import com.community.micrologistics.dto.auth.RegisterRequest
import com.community.micrologistics.dto.auth.SendOtpRequest
import com.community.micrologistics.dto.auth.SendOtpResponse
import com.community.micrologistics.entity.OtpCodeEntity
import com.community.micrologistics.entity.RefreshTokenEntity
import com.community.micrologistics.entity.UserEntity
import com.community.micrologistics.enums.AccountStatus
import com.community.micrologistics.enums.OtpPurpose
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.exception.AuthenticationException
import com.community.micrologistics.exception.InvalidOperationException
import com.community.micrologistics.repository.OtpCodeRepository
import com.community.micrologistics.repository.RefreshTokenRepository
import com.community.micrologistics.repository.UserRepository
import com.community.micrologistics.security.JwtService
import com.community.micrologistics.util.CommunityIdentity
import org.springframework.beans.factory.annotation.Value
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom
import java.time.OffsetDateTime
import java.util.Base64
import java.util.UUID

@Service
class AuthService(
    private val otpCodeRepository: OtpCodeRepository,
    private val refreshTokenRepository: RefreshTokenRepository,
    private val userRepository: UserRepository,
    private val walletService: WalletService,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService,
    @Value("\${app.auth.refresh-token-days:30}") private val refreshTokenDays: Long,
    @Value("\${app.auth.otp.expose-code:false}") private val exposeOtpCode: Boolean
) {
    @Transactional
    fun sendOtp(request: SendOtpRequest): SendOtpResponse {
        val phone = request.phoneNumber.trim()
        val registered = userRepository.findByPhoneNumber(phone) != null
        val otpCode = generateOtp()
        val expiresAt = OffsetDateTime.now().plusMinutes(5)
        val otpRecord = otpCodeRepository.save(
            OtpCodeEntity(
                phoneNumber = phone,
                purpose = request.purpose,
                otpCode = otpCode,
                expiresAt = expiresAt
            )
        )

        // Replace this development response with an SMS provider before enabling OTP in production.
        return SendOtpResponse(
            requestId = otpRecord.id,
            phoneNumber = phone,
            purpose = request.purpose,
            otpCode = otpCode.takeIf { exposeOtpCode },
            expiresAt = expiresAt,
            registered = registered
        )
    }

    @Transactional
    fun register(request: RegisterRequest): AuthSessionResponse {
        val phone = request.phoneNumber.trim()
        if (userRepository.findByPhoneNumber(phone) != null) {
            throw InvalidOperationException("该手机号已注册，请直接登录")
        }
        validatePasswordStrength(request.password)

        val displayName = request.displayName.trim()
        val savedUser = userRepository.save(
            UserEntity(
                phoneNumber = phone,
                displayName = displayName,
                avatarEmoji = displayName.firstOrNull()?.toString() ?: "邻",
                bio = "刚加入打个酱油，期待和邻里互相搭把手。",
                passwordHash = passwordEncoder.encode(request.password),
                activeMode = UserMode.CREATOR,
                creditScore = BigDecimal("90.00"),
                creatorEnabled = true,
                runnerEnabled = true,
                communityName = request.communityName?.trim()?.ifBlank { null },
                communityId = CommunityIdentity.idFor(request.communityName),
                buildingName = request.buildingName?.trim()?.ifBlank { null },
                roomMask = request.buildingName?.trim()?.takeIf { it.isNotBlank() }?.let { "$it-***" },
                notificationsEnabled = true,
                privacyMasked = true,
                communityVerified = false
            )
        )
        walletService.createDefaultWalletsForUser(savedUser.id)
        return issueSession(savedUser)
    }

    @Transactional
    fun login(request: LoginRequest): AuthSessionResponse {
        val phone = request.phoneNumber.trim()
        validateOtp(request.requestId, phone, request.otpCode, OtpPurpose.LOGIN)
        val user = userRepository.findByPhoneNumber(phone)
            ?: throw AuthenticationException("该手机号尚未注册，请先创建账号")
        ensureActive(user)
        return issueSession(user)
    }

    @Transactional
    fun loginWithPassword(request: PasswordLoginRequest): AuthSessionResponse {
        val phone = request.phoneNumber.trim()
        val user = userRepository.findByPhoneNumber(phone)
            ?: throw AuthenticationException("手机号或密码错误")
        ensureActive(user)
        if (user.passwordHash.isNullOrBlank() || !passwordEncoder.matches(request.password, user.passwordHash)) {
            throw AuthenticationException("手机号或密码错误")
        }
        return issueSession(user)
    }

    @Transactional
    fun refresh(request: RefreshTokenRequest): AuthSessionResponse {
        val storedToken = refreshTokenRepository.findByTokenHashForUpdate(hashToken(request.refreshToken))
            ?: throw AuthenticationException("登录凭证无效，请重新登录")
        val now = OffsetDateTime.now()
        if (storedToken.revokedAt != null || storedToken.expiresAt.isBefore(now)) {
            throw AuthenticationException("登录凭证已失效，请重新登录")
        }

        val user = userRepository.findById(storedToken.userId)
            .orElseThrow { AuthenticationException("账号不存在，请重新登录") }
        ensureActive(user)

        storedToken.revokedAt = now
        val newRefresh = createRefreshToken(user.id)
        storedToken.replacedByTokenId = newRefresh.second.id
        refreshTokenRepository.save(storedToken)
        refreshTokenRepository.save(newRefresh.second)
        return user.toSession(newRefresh.first)
    }

    @Transactional
    fun logout(request: RefreshTokenRequest) {
        val storedToken = refreshTokenRepository.findByTokenHashForUpdate(hashToken(request.refreshToken)) ?: return
        if (storedToken.revokedAt == null) {
            storedToken.revokedAt = OffsetDateTime.now()
            refreshTokenRepository.save(storedToken)
        }
    }

    @Transactional
    fun validateOtp(requestId: UUID, phoneNumber: String, otpCode: String, purpose: OtpPurpose): OtpCodeEntity {
        val otpRecord = otpCodeRepository.findByIdForUpdate(requestId)
            ?: throw AuthenticationException("验证码请求不存在，请重新获取")
        if (otpRecord.phoneNumber != phoneNumber || otpRecord.purpose != purpose) {
            throw AuthenticationException("验证码与当前操作不匹配")
        }
        if (otpRecord.consumedAt != null) throw AuthenticationException("验证码已使用，请重新获取")
        if (otpRecord.expiresAt.isBefore(OffsetDateTime.now())) throw AuthenticationException("验证码已过期")
        if (otpRecord.otpCode != otpCode.trim()) throw AuthenticationException("验证码错误")

        otpRecord.consumedAt = OffsetDateTime.now()
        return otpCodeRepository.save(otpRecord)
    }

    private fun issueSession(user: UserEntity): AuthSessionResponse {
        val refresh = createRefreshToken(user.id)
        refreshTokenRepository.save(refresh.second)
        return user.toSession(refresh.first)
    }

    private fun createRefreshToken(userId: UUID): Pair<String, RefreshTokenEntity> {
        val rawToken = ByteArray(48).also(secureRandom::nextBytes)
            .let { Base64.getUrlEncoder().withoutPadding().encodeToString(it) }
        return rawToken to RefreshTokenEntity(
            userId = userId,
            tokenHash = hashToken(rawToken),
            expiresAt = OffsetDateTime.now().plusDays(refreshTokenDays)
        )
    }

    private fun UserEntity.toSession(refreshToken: String): AuthSessionResponse = AuthSessionResponse(
        userId = id,
        displayName = displayName,
        avatarEmoji = avatarEmoji,
        phoneNumber = phoneNumber,
        currentMode = activeMode,
        creditScore = creditScore,
        communityName = communityName,
        buildingName = buildingName,
        accessToken = jwtService.createAccessToken(this),
        refreshToken = refreshToken,
        expiresInSeconds = jwtService.accessTokenSeconds
    )

    private fun ensureActive(user: UserEntity) {
        if (user.accountStatus != AccountStatus.ACTIVE) {
            throw AuthenticationException("当前账号不可用，请联系客服")
        }
    }

    private fun validatePasswordStrength(password: String) {
        if (password.none(Char::isLetter) || password.none(Char::isDigit)) {
            throw InvalidOperationException("密码至少需要包含一个字母和一个数字")
        }
    }

    private fun hashToken(rawToken: String): String = MessageDigest.getInstance("SHA-256")
        .digest(rawToken.toByteArray(StandardCharsets.UTF_8))
        .joinToString("") { "%02x".format(it) }

    private fun generateOtp(): String = (100000 + secureRandom.nextInt(900000)).toString()

    companion object {
        private val secureRandom = SecureRandom()
    }
}

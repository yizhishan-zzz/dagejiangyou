package com.community.micrologistics.controller

import com.community.micrologistics.dto.auth.AuthSessionResponse
import com.community.micrologistics.dto.auth.LoginRequest
import com.community.micrologistics.dto.auth.PasswordLoginRequest
import com.community.micrologistics.dto.auth.RegisterRequest
import com.community.micrologistics.dto.auth.RefreshTokenRequest
import com.community.micrologistics.dto.auth.SendOtpRequest
import com.community.micrologistics.dto.auth.SendOtpResponse
import com.community.micrologistics.dto.user.ToggleModeResponse
import com.community.micrologistics.dto.user.UpdateUserSettingsRequest
import com.community.micrologistics.dto.user.UserProfileResponse
import com.community.micrologistics.service.AuthService
import com.community.micrologistics.service.UserService
import com.community.micrologistics.security.AppPrincipal
import jakarta.validation.Valid
import org.springframework.validation.annotation.Validated
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.security.core.annotation.AuthenticationPrincipal
import java.util.UUID

@Validated
@RestController
@RequestMapping("/api/v1/users")
class UserController(
    private val authService: AuthService,
    private val userService: UserService
) {
    @PostMapping("/auth/send-otp")
    fun sendOtp(@Valid @RequestBody request: SendOtpRequest): SendOtpResponse =
        authService.sendOtp(request)

    @PostMapping("/auth/register")
    fun register(@Valid @RequestBody request: RegisterRequest): AuthSessionResponse =
        authService.register(request)

    @PostMapping("/auth/login")
    fun login(@Valid @RequestBody request: LoginRequest): AuthSessionResponse =
        authService.login(request)

    @PostMapping("/auth/password-login")
    fun passwordLogin(@Valid @RequestBody request: PasswordLoginRequest): AuthSessionResponse =
        authService.loginWithPassword(request)

    @PostMapping("/auth/refresh")
    fun refresh(@Valid @RequestBody request: RefreshTokenRequest): AuthSessionResponse =
        authService.refresh(request)

    @PostMapping("/auth/logout")
    fun logout(@Valid @RequestBody request: RefreshTokenRequest) {
        authService.logout(request)
    }

    @PostMapping("/auth/toggle-mode")
    fun toggleMode(@AuthenticationPrincipal principal: AppPrincipal): ToggleModeResponse =
        userService.toggleMode(principal.userId)

    @GetMapping("/profile")
    fun getProfile(@AuthenticationPrincipal principal: AppPrincipal): UserProfileResponse =
        userService.getProfile(principal.userId)

    @PutMapping("/profile/settings")
    fun updateSettings(
        @AuthenticationPrincipal principal: AppPrincipal,
        @Valid @RequestBody request: UpdateUserSettingsRequest
    ): UserProfileResponse = userService.updateSettings(principal.userId, request)
}

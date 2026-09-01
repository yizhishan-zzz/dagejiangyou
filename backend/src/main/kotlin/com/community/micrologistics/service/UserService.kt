package com.community.micrologistics.service

import com.community.micrologistics.dto.user.ToggleModeResponse
import com.community.micrologistics.dto.user.UpdateUserSettingsRequest
import com.community.micrologistics.dto.user.UserProfileResponse
import com.community.micrologistics.entity.UserEntity
import com.community.micrologistics.enums.UserMode
import com.community.micrologistics.enums.WalletType
import com.community.micrologistics.exception.InvalidRoleException
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.UserRepository
import com.community.micrologistics.repository.CommunityRepository
import com.community.micrologistics.repository.CommunityBuildingRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class UserService(
    private val userRepository: UserRepository,
    private val walletService: WalletService,
    private val communityRepository: CommunityRepository? = null,
    private val buildingRepository: CommunityBuildingRepository? = null
) {
    @Transactional
    fun toggleMode(userId: UUID): ToggleModeResponse {
        val user = getUserForUpdate(userId)
        val previousMode = user.activeMode
        val nextMode = when (user.activeMode) {
            UserMode.CREATOR -> UserMode.RUNNER
            UserMode.RUNNER -> UserMode.CREATOR
        }

        ensureModeEnabled(user, nextMode)
        user.activeMode = nextMode
        userRepository.save(user)

        return ToggleModeResponse(
            userId = user.id,
            previousMode = previousMode,
            currentMode = nextMode
        )
    }

    @Transactional(readOnly = true)
    fun getProfile(userId: UUID): UserProfileResponse {
        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException("User $userId was not found") }
        return toProfileResponse(user)
    }

    @Transactional
    fun updateSettings(userId: UUID, request: UpdateUserSettingsRequest): UserProfileResponse {
        val user = getUserForUpdate(userId)

        request.displayName
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { user.displayName = it }
        request.avatarEmoji
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { user.avatarEmoji = it.take(8) }
        request.bio?.trim()?.let { user.bio = it.take(160) }
        request.communityId?.let { communityId ->
            val community = communityRepository?.findByIdAndActiveTrue(communityId)
                ?: throw InvalidRoleException("Selected community is unavailable")
            val communityChanged = user.communityId != community.id
            user.communityId = community.id
            user.communityName = community.name
            if (communityChanged) {
                user.communityVerified = false
                user.buildingName = null
            }
        }
        request.buildingId?.let { buildingId ->
            val building = buildingRepository?.findByIdAndActiveTrue(buildingId)
                ?: throw InvalidRoleException("Selected building is unavailable")
            if (building.communityId != user.communityId) {
                throw InvalidRoleException("Selected building does not belong to this community")
            }
            user.buildingName = building.name
        }
        if (request.buildingId == null) {
            request.buildingName?.trim()?.let { user.buildingName = it.ifBlank { null }?.take(64) }
        }
        request.roomMask?.trim()?.let { user.roomMask = it.ifBlank { null }?.take(32) }
        request.notificationsEnabled?.let { user.notificationsEnabled = it }
        request.privacyMasked?.let { user.privacyMasked = it }
        if ((request.latitude == null) != (request.longitude == null)) {
            throw InvalidRoleException("Latitude and longitude must be updated together")
        }
        if (request.latitude != null && request.longitude != null) {
            user.locationLatitude = request.latitude
            user.locationLongitude = request.longitude
        }

        val savedUser = userRepository.save(user)
        return toProfileResponse(savedUser)
    }

    @Transactional(readOnly = true)
    fun requireMode(userId: UUID, expectedMode: UserMode): UserEntity {
        val user = userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException("User $userId was not found") }
        if (user.activeMode != expectedMode) {
            throw InvalidRoleException("User $userId must be in $expectedMode mode to perform this operation")
        }
        ensureModeEnabled(user, expectedMode)
        return user
    }

    @Transactional(readOnly = true)
    fun findUser(userId: UUID): UserEntity =
        userRepository.findById(userId)
            .orElseThrow { ResourceNotFoundException("User $userId was not found") }

    private fun getUserForUpdate(userId: UUID): UserEntity =
        userRepository.findByIdForUpdate(userId)
            ?: throw ResourceNotFoundException("User $userId was not found")

    private fun ensureModeEnabled(user: UserEntity, mode: UserMode) {
        val isEnabled = when (mode) {
            UserMode.CREATOR -> user.creatorEnabled
            UserMode.RUNNER -> user.runnerEnabled
        }
        if (!isEnabled) {
            throw InvalidRoleException("User ${user.id} cannot switch to $mode mode")
        }
    }

    private fun toProfileResponse(user: UserEntity): UserProfileResponse {
        val creatorWallet = walletService.getWalletOrZero(user.id, WalletType.CREATOR)
        val runnerWallet = walletService.getWalletOrZero(user.id, WalletType.RUNNER)

        return UserProfileResponse(
            userId = user.id,
            displayName = user.displayName,
            avatarEmoji = user.avatarEmoji,
            bio = user.bio,
            phoneNumber = user.phoneNumber,
            currentMode = user.activeMode,
            creditScore = user.creditScore,
            communityName = user.communityName,
            buildingName = user.buildingName,
            roomMask = user.roomMask,
            notificationsEnabled = user.notificationsEnabled,
            privacyMasked = user.privacyMasked,
            communityVerified = user.communityVerified,
            latitude = user.locationLatitude,
            longitude = user.locationLongitude,
            creatorWalletBalance = creatorWallet.availableBalance,
            creatorFrozenBalance = creatorWallet.frozenBalance,
            runnerWalletBalance = runnerWallet.availableBalance,
            runnerFrozenBalance = runnerWallet.frozenBalance
        )
    }
}

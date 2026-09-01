package com.community.micrologistics.dto.user

import com.community.micrologistics.enums.UserMode
import java.util.UUID

data class ToggleModeResponse(
    val userId: UUID,
    val previousMode: UserMode,
    val currentMode: UserMode
)

package com.community.micrologistics.security

import com.community.micrologistics.enums.SystemRole
import java.util.UUID

data class AppPrincipal(
    val userId: UUID,
    val role: SystemRole
)

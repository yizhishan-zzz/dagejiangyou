package com.community.micrologistics.util

import java.nio.charset.StandardCharsets
import java.util.Locale
import java.util.UUID

object CommunityIdentity {
    fun idFor(name: String?): UUID? {
        val normalized = name?.trim()?.lowercase(Locale.ROOT)?.takeIf { it.isNotEmpty() } ?: return null
        return UUID.nameUUIDFromBytes("community:$normalized".toByteArray(StandardCharsets.UTF_8))
    }
}

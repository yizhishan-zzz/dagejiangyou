package com.community.micrologistics.util

import java.nio.charset.StandardCharsets
import java.security.MessageDigest

object PasswordUtils {
    fun hash(rawPassword: String): String =
        MessageDigest.getInstance("SHA-256")
            .digest(rawPassword.toByteArray(StandardCharsets.UTF_8))
            .joinToString(separator = "") { byte -> "%02x".format(byte) }

    fun matches(rawPassword: String, storedHash: String?): Boolean {
        if (storedHash.isNullOrBlank()) {
            return false
        }
        return hash(rawPassword) == storedHash
    }
}

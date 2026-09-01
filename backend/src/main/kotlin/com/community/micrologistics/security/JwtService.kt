package com.community.micrologistics.security

import com.community.micrologistics.entity.UserEntity
import io.jsonwebtoken.JwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.nio.charset.StandardCharsets
import java.time.Instant
import java.util.Date
import java.util.UUID

@Service
class JwtService(
    @Value("\${app.auth.jwt-secret}") secret: String,
    @Value("\${app.auth.access-token-minutes:30}") private val accessTokenMinutes: Long
) {
    private val signingKey = Keys.hmacShaKeyFor(
        secret.toByteArray(StandardCharsets.UTF_8).also {
            require(it.size >= 32) { "app.auth.jwt-secret must contain at least 32 bytes" }
        }
    )

    val accessTokenSeconds: Long
        get() = accessTokenMinutes * 60

    fun createAccessToken(user: UserEntity): String {
        val issuedAt = Instant.now()
        return Jwts.builder()
            .subject(user.id.toString())
            .claim("role", user.systemRole.name)
            .claim("mode", user.activeMode.name)
            .issuedAt(Date.from(issuedAt))
            .expiration(Date.from(issuedAt.plusSeconds(accessTokenSeconds)))
            .signWith(signingKey)
            .compact()
    }

    fun parseUserId(token: String): UUID? = try {
        val claims = Jwts.parser()
            .verifyWith(signingKey)
            .build()
            .parseSignedClaims(token)
            .payload
        UUID.fromString(claims.subject)
    } catch (_: JwtException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }
}

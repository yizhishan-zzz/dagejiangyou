package com.community.micrologistics.security

import com.community.micrologistics.enums.AccountStatus
import com.community.micrologistics.repository.UserRepository
import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.http.HttpHeaders
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
class JwtAuthenticationFilter(
    private val jwtService: JwtService,
    private val userRepository: UserRepository
) : OncePerRequestFilter() {
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        val bearer = request.getHeader(HttpHeaders.AUTHORIZATION)
        val token = bearer?.takeIf { it.startsWith("Bearer ", ignoreCase = true) }?.substring(7)?.trim()

        if (!token.isNullOrBlank() && SecurityContextHolder.getContext().authentication == null) {
            val userId = jwtService.parseUserId(token)
            val user = userId?.let { userRepository.findById(it).orElse(null) }
            if (user != null && user.accountStatus == AccountStatus.ACTIVE) {
                val principal = AppPrincipal(user.id, user.systemRole)
                val authentication = UsernamePasswordAuthenticationToken(
                    principal,
                    null,
                    listOf(SimpleGrantedAuthority("ROLE_${user.systemRole.name}"))
                )
                SecurityContextHolder.getContext().authentication = authentication
            }
        }

        filterChain.doFilter(request, response)
    }
}

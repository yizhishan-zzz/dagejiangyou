package com.community.micrologistics.config

import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class CorsConfig(
    @Value(
        "\${app.cors.allowed-origin-patterns:http://127.0.0.1:4100,http://localhost:4100,http://192.168.10.5:4100}"
    )
    private val allowedOriginPatternsProperty: String
) : WebMvcConfigurer {

    override fun addCorsMappings(registry: CorsRegistry) {
        val allowedOriginPatterns = allowedOriginPatternsProperty
            .split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .toTypedArray()

        registry.addMapping("/api/**")
            .allowedOriginPatterns(*allowedOriginPatterns)
            .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .exposedHeaders("*")
            .maxAge(3600)
    }
}

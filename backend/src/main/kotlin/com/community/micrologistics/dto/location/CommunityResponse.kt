package com.community.micrologistics.dto.location

import java.util.UUID

data class CommunityResponse(
    val id: UUID,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val serviceRadiusMeters: Int,
    val distanceMeters: Double?
)

package com.community.micrologistics.dto.location

import java.util.UUID

data class CommunityBuildingResponse(
    val id: UUID,
    val communityId: UUID,
    val name: String,
    val latitude: Double,
    val longitude: Double
)

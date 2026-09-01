package com.community.micrologistics.controller

import com.community.micrologistics.dto.location.CommunityBuildingResponse
import com.community.micrologistics.dto.location.CommunityResponse
import com.community.micrologistics.service.CommunityDirectoryService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/api/v1/locations")
class LocationController(
    private val communityDirectoryService: CommunityDirectoryService
) {
    @GetMapping("/communities")
    fun communities(
        @RequestParam(required = false) latitude: Double?,
        @RequestParam(required = false) longitude: Double?
    ): List<CommunityResponse> = communityDirectoryService.listCommunities(latitude, longitude)

    @GetMapping("/communities/{communityId}/buildings")
    fun buildings(@PathVariable communityId: UUID): List<CommunityBuildingResponse> =
        communityDirectoryService.listBuildings(communityId)
}

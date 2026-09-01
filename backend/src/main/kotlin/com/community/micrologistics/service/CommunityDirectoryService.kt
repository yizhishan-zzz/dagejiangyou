package com.community.micrologistics.service

import com.community.micrologistics.dto.location.CommunityBuildingResponse
import com.community.micrologistics.dto.location.CommunityResponse
import com.community.micrologistics.exception.ResourceNotFoundException
import com.community.micrologistics.repository.CommunityBuildingRepository
import com.community.micrologistics.repository.CommunityRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

@Service
class CommunityDirectoryService(
    private val communityRepository: CommunityRepository,
    private val buildingRepository: CommunityBuildingRepository
) {
    @Transactional(readOnly = true)
    fun listCommunities(latitude: Double?, longitude: Double?): List<CommunityResponse> {
        val hasLocation = latitude != null && longitude != null
        return communityRepository.findAllByActiveTrueOrderByNameAsc()
            .map { community ->
                val distance = if (hasLocation) {
                    distanceMeters(latitude!!, longitude!!, community.latitude, community.longitude)
                } else {
                    null
                }
                community to distance
            }
            .sortedWith(compareBy<Pair<com.community.micrologistics.entity.CommunityEntity, Double?>> {
                it.second ?: Double.MAX_VALUE
            }.thenBy { it.first.name })
            .take(MAX_COMMUNITIES)
            .map { (community, distance) ->
                CommunityResponse(
                    id = community.id,
                    name = community.name,
                    latitude = community.latitude,
                    longitude = community.longitude,
                    serviceRadiusMeters = community.serviceRadiusMeters,
                    distanceMeters = distance
                )
            }
    }

    @Transactional(readOnly = true)
    fun listBuildings(communityId: UUID): List<CommunityBuildingResponse> {
        if (communityRepository.findByIdAndActiveTrue(communityId) == null) {
            throw ResourceNotFoundException("Community $communityId was not found")
        }
        return buildingRepository.findAllByCommunityIdAndActiveTrueOrderBySortOrderAsc(communityId)
            .map {
                CommunityBuildingResponse(
                    id = it.id,
                    communityId = it.communityId,
                    name = it.name,
                    latitude = it.latitude,
                    longitude = it.longitude
                )
            }
    }

    private fun distanceMeters(
        latitudeA: Double,
        longitudeA: Double,
        latitudeB: Double,
        longitudeB: Double
    ): Double {
        val latitudeRadians = Math.toRadians(latitudeB - latitudeA)
        val longitudeRadians = Math.toRadians(longitudeB - longitudeA)
        val a = sin(latitudeRadians / 2) * sin(latitudeRadians / 2) +
            cos(Math.toRadians(latitudeA)) * cos(Math.toRadians(latitudeB)) *
            sin(longitudeRadians / 2) * sin(longitudeRadians / 2)
        return 6_371_000.0 * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    companion object {
        private const val MAX_COMMUNITIES = 60
    }
}

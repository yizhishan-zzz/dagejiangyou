package com.community.micrologistics.service

import com.community.micrologistics.entity.CommunityBuildingEntity
import com.community.micrologistics.entity.CommunityEntity
import com.community.micrologistics.repository.CommunityBuildingRepository
import com.community.micrologistics.repository.CommunityRepository
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import java.util.UUID

class CommunityDirectoryServiceTest {
    private val communityRepository = mock(CommunityRepository::class.java)
    private val buildingRepository = mock(CommunityBuildingRepository::class.java)
    private val service = CommunityDirectoryService(communityRepository, buildingRepository)

    @Test
    fun `communities are ordered by distance from selected point`() {
        val far = CommunityEntity(UUID.randomUUID(), "远社区", 31.2400, 121.4800)
        val near = CommunityEntity(UUID.randomUUID(), "近社区", 31.2305, 121.4738)
        `when`(communityRepository.findAllByActiveTrueOrderByNameAsc())
            .thenReturn(listOf(far, near))

        val result = service.listCommunities(31.2304, 121.4737)

        assertEquals(listOf("近社区", "远社区"), result.map { it.name })
    }

    @Test
    fun `buildings come from the selected community`() {
        val communityId = UUID.randomUUID()
        val community = CommunityEntity(communityId, "春和里社区", 31.2304, 121.4737)
        val building = CommunityBuildingEntity(
            UUID.randomUUID(),
            communityId,
            "7号楼",
            31.2310,
            121.4743,
            7
        )
        `when`(communityRepository.findByIdAndActiveTrue(communityId)).thenReturn(community)
        `when`(buildingRepository.findAllByCommunityIdAndActiveTrueOrderBySortOrderAsc(communityId))
            .thenReturn(listOf(building))

        val result = service.listBuildings(communityId)

        assertEquals(1, result.size)
        assertEquals(communityId, result.single().communityId)
        assertEquals("7号楼", result.single().name)
    }
}

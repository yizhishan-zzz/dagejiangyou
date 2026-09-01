package com.community.micrologistics.repository

import com.community.micrologistics.entity.CommunityBuildingEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface CommunityBuildingRepository : JpaRepository<CommunityBuildingEntity, UUID> {
    fun findAllByCommunityIdAndActiveTrueOrderBySortOrderAsc(communityId: UUID): List<CommunityBuildingEntity>
    fun findByIdAndActiveTrue(id: UUID): CommunityBuildingEntity?
}

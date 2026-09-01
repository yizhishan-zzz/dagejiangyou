package com.community.micrologistics.repository

import com.community.micrologistics.entity.AdSlotEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface AdSlotRepository : JpaRepository<AdSlotEntity, UUID> {
    fun findAllByPlacementAndActiveTrueOrderBySortOrderAsc(placement: String): List<AdSlotEntity>
}

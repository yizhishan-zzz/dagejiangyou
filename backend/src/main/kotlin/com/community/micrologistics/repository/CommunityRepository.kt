package com.community.micrologistics.repository

import com.community.micrologistics.entity.CommunityEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface CommunityRepository : JpaRepository<CommunityEntity, UUID> {
    fun findAllByActiveTrueOrderByNameAsc(): List<CommunityEntity>
    fun findByIdAndActiveTrue(id: UUID): CommunityEntity?
}

package com.community.micrologistics.service

import com.community.micrologistics.dto.ad.AdSlotResponse
import com.community.micrologistics.entity.AdSlotEntity
import com.community.micrologistics.repository.AdSlotRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.OffsetDateTime

@Service
class AdSlotService(
    private val adSlotRepository: AdSlotRepository
) {
    @Transactional(readOnly = true)
    fun listActive(placement: String): List<AdSlotResponse> {
        val now = OffsetDateTime.now()
        return adSlotRepository.findAllByPlacementAndActiveTrueOrderBySortOrderAsc(placement.trim().uppercase())
            .filter { slot ->
                (slot.startsAt == null || !slot.startsAt!!.isAfter(now)) &&
                    (slot.endsAt == null || slot.endsAt!!.isAfter(now))
            }
            .map { it.toResponse() }
    }

    @Transactional(readOnly = true)
    fun listAll(): List<AdSlotResponse> = adSlotRepository.findAll()
        .sortedWith(compareBy<AdSlotEntity> { it.placement }.thenBy { it.sortOrder })
        .map { it.toResponse() }

    private fun AdSlotEntity.toResponse() = AdSlotResponse(
        id = id,
        placement = placement,
        label = label,
        title = title,
        subtitle = subtitle,
        actionLabel = actionLabel,
        actionRoute = actionRoute,
        accentHex = accentHex,
        imageUrl = imageUrl
    )
}

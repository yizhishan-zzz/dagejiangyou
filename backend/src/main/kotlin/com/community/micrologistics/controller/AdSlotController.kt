package com.community.micrologistics.controller

import com.community.micrologistics.dto.ad.AdSlotResponse
import com.community.micrologistics.service.AdSlotService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/v1/ad-slots")
class AdSlotController(
    private val adSlotService: AdSlotService
) {
    @GetMapping
    fun listActive(
        @RequestParam(defaultValue = "HOME_TOP") placement: String
    ): List<AdSlotResponse> = adSlotService.listActive(placement)
}

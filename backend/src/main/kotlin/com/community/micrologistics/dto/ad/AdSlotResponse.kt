package com.community.micrologistics.dto.ad

import java.util.UUID

data class AdSlotResponse(
    val id: UUID,
    val placement: String,
    val label: String,
    val title: String,
    val subtitle: String,
    val actionLabel: String,
    val actionRoute: String,
    val accentHex: String,
    val imageUrl: String?
)

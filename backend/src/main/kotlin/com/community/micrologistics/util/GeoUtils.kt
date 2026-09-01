package com.community.micrologistics.util

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

object GeoUtils {
    private const val EarthRadiusMeters = 6371000.0

    fun haversineDistanceMeters(
        sourceLatitude: Double,
        sourceLongitude: Double,
        targetLatitude: Double,
        targetLongitude: Double
    ): Double {
        val latitudeDelta = Math.toRadians(targetLatitude - sourceLatitude)
        val longitudeDelta = Math.toRadians(targetLongitude - sourceLongitude)
        val lat1 = Math.toRadians(sourceLatitude)
        val lat2 = Math.toRadians(targetLatitude)

        val a = sin(latitudeDelta / 2).pow(2.0) +
            cos(lat1) * cos(lat2) * sin(longitudeDelta / 2).pow(2.0)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return EarthRadiusMeters * c
    }
}

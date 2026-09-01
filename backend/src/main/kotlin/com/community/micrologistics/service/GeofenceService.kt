package com.community.micrologistics.service

import com.community.micrologistics.exception.GeofenceViolationException
import com.community.micrologistics.util.GeoUtils
import org.springframework.stereotype.Service

@Service
class GeofenceService {
    companion object {
        const val MAX_SERVICE_RADIUS_METERS = 500.0
    }

    fun validateTaskWithinRadius(
        pickupLatitude: Double,
        pickupLongitude: Double,
        dropoffLatitude: Double,
        dropoffLongitude: Double
    ) {
        validateCoordinate(pickupLatitude, pickupLongitude)
        validateCoordinate(dropoffLatitude, dropoffLongitude)
        val distance = GeoUtils.haversineDistanceMeters(
            pickupLatitude,
            pickupLongitude,
            dropoffLatitude,
            dropoffLongitude
        )
        if (distance > MAX_SERVICE_RADIUS_METERS) {
            throw GeofenceViolationException(
                "Task exceeds the 500-meter service radius with distance %.2f meters".format(distance)
            )
        }
    }

    fun validateCoordinate(latitude: Double, longitude: Double) {
        if (
            !latitude.isFinite() ||
            !longitude.isFinite() ||
            latitude !in -90.0..90.0 ||
            longitude !in -180.0..180.0
        ) {
            throw GeofenceViolationException("定位坐标无效，请重新获取当前位置")
        }
    }

    fun validatePointWithinRadius(
        sourceLatitude: Double,
        sourceLongitude: Double,
        targetLatitude: Double,
        targetLongitude: Double
    ) {
        validateCoordinate(sourceLatitude, sourceLongitude)
        validateCoordinate(targetLatitude, targetLongitude)
        val distance = distanceMeters(sourceLatitude, sourceLongitude, targetLatitude, targetLongitude)
        if (distance > MAX_SERVICE_RADIUS_METERS) {
            throw GeofenceViolationException("当前位置距离任务取货点超过 500 米")
        }
    }

    fun distanceMeters(
        sourceLatitude: Double,
        sourceLongitude: Double,
        targetLatitude: Double,
        targetLongitude: Double
    ): Double = GeoUtils.haversineDistanceMeters(
        sourceLatitude,
        sourceLongitude,
        targetLatitude,
        targetLongitude
    )
}

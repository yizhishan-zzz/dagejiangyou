package com.community.micrologistics.util

import java.math.BigDecimal
import java.math.RoundingMode

object MoneyUtils {
    fun scale(value: BigDecimal): BigDecimal = value.setScale(2, RoundingMode.HALF_UP)
}

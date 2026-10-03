package com.dosemate.app.util

import android.content.Context
import android.content.res.Configuration
import com.dosemate.app.R
import com.dosemate.app.data.db.FoodRelation
import com.dosemate.app.data.db.MedicineEntity
import java.time.Duration
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

object LocaleHelper {
    /** Returns a context whose resources use [language] ("en", "kn" or "system"). */
    fun wrap(base: Context, language: String): Context {
        if (language == "system" || language.isBlank()) return base
        val locale = Locale.forLanguageTag(language)
        val config = Configuration(base.resources.configuration)
        config.setLocale(locale)
        config.setLayoutDirection(locale)
        return base.createConfigurationContext(config)
    }

    fun locale(language: String): Locale =
        if (language == "system" || language.isBlank()) Locale.getDefault() else Locale.forLanguageTag(language)
}

object TimeFormat {
    private val h12 = DateTimeFormatter.ofPattern("h:mm a")
    private val h24 = DateTimeFormatter.ofPattern("HH:mm")

    fun time(time: LocalTime, use24h: Boolean, locale: Locale = Locale.getDefault()): String =
        (if (use24h) h24 else h12).withLocale(locale).format(time)

    fun date(date: LocalDate, locale: Locale = Locale.getDefault()): String =
        DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM).withLocale(locale).format(date)

    fun shortDate(date: LocalDate, locale: Locale = Locale.getDefault()): String =
        DateTimeFormatter.ofPattern("d MMM", locale).format(date)

    fun dayMonthYear(date: LocalDate): String = DateTimeFormatter.ofPattern("dd-MM-yyyy").format(date)

    /** "2h 05m" or "12m 30s" style countdown. */
    fun countdown(duration: Duration): String {
        val total = duration.seconds.coerceAtLeast(0)
        val days = total / 86_400
        val hours = (total % 86_400) / 3600
        val minutes = (total % 3600) / 60
        val seconds = total % 60
        return when {
            days > 0 -> "${days}d ${hours}h"
            hours > 0 -> "%dh %02dm".format(hours, minutes)
            else -> "%dm %02ds".format(minutes, seconds)
        }
    }
}

fun Context.foodLabel(food: FoodRelation): String = when (food) {
    FoodRelation.NONE -> ""
    FoodRelation.BEFORE -> getString(R.string.food_before)
    FoodRelation.AFTER -> getString(R.string.food_after)
    FoodRelation.WITH -> getString(R.string.food_with)
}

fun formatAmount(amount: Double): String =
    if (amount % 1.0 == 0.0) amount.toLong().toString() else "%.1f".format(amount).trimEnd('0').trimEnd('.')

/** "1 tablet · After food" */
fun Context.doseLine(m: MedicineEntity): String =
    listOf("${formatAmount(m.doseAmount)} ${m.doseUnit}".trim(), foodLabel(m.food))
        .filter { it.isNotBlank() }
        .joinToString(" · ")

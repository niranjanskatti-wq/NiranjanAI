package com.niranjan.smriti

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.provider.CalendarContract
import java.util.Calendar
import java.util.TimeZone

/** Writes Smriti's dates into a calendar on the phone (e.g. Google Calendar). */
object PhoneCalendar {
    fun calendars(cr: ContentResolver): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.IS_PRIMARY,
        )
        cr.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ?",
            arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString()),
            null,
        )?.use { c ->
            while (c.moveToNext()) {
                out.add(
                    mapOf(
                        "id" to c.getLong(0),
                        "name" to (c.getString(1) ?: ""),
                        "account" to (c.getString(2) ?: ""),
                        "primary" to (c.getInt(3) == 1),
                    ),
                )
            }
        }
        return out
    }

    /** Adds or updates one all-day event; returns its id. */
    fun upsert(cr: ContentResolver, a: Map<String, Any?>): Long {
        val start = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear()
            set((a["year"] as Number).toInt(), (a["month"] as Number).toInt() - 1, (a["day"] as Number).toInt())
        }.timeInMillis
        val rrule = a["rrule"] as String?
        val v = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, (a["calendarId"] as Number).toLong())
            put(CalendarContract.Events.TITLE, a["title"] as String)
            put(CalendarContract.Events.DESCRIPTION, a["description"] as String? ?: "")
            put(CalendarContract.Events.DTSTART, start)
            put(CalendarContract.Events.ALL_DAY, 1)
            put(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            if (rrule == null) {
                put(CalendarContract.Events.DTEND, start + 86_400_000L)
                putNull(CalendarContract.Events.RRULE)
                putNull(CalendarContract.Events.DURATION)
            } else {
                put(CalendarContract.Events.RRULE, rrule)
                put(CalendarContract.Events.DURATION, "P1D")
                putNull(CalendarContract.Events.DTEND)
            }
        }
        val existing = (a["eventId"] as Number?)?.toLong()
        if (existing != null) {
            val uri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, existing)
            if (cr.update(uri, v, null, null) > 0) return existing
        }
        val uri = cr.insert(CalendarContract.Events.CONTENT_URI, v) ?: throw IllegalStateException("Calendar refused the event")
        return ContentUris.parseId(uri)
    }

    fun delete(cr: ContentResolver, ids: List<Long>) {
        for (id in ids) {
            cr.delete(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id), null, null)
        }
    }
}

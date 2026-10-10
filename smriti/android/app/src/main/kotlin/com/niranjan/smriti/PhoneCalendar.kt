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

    /**
     * Dates worth importing: repeating events (yearly or monthly) and one-time
     * all-day events in the next two years. Meetings and past events are left out.
     */
    fun importable(cr: ContentResolver): List<Map<String, Any?>> {
        val names = mutableMapOf<Long, Pair<String, String>>()
        cr.query(
            CalendarContract.Calendars.CONTENT_URI,
            arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.OWNER_ACCOUNT,
            ),
            null, null, null,
        )?.use { c ->
            while (c.moveToNext()) names[c.getLong(0)] = Pair(c.getString(1) ?: "", c.getString(2) ?: "")
        }
        val now = System.currentTimeMillis()
        val until = now + 2L * 366 * 86_400_000L
        val out = mutableListOf<Map<String, Any?>>()
        cr.query(
            CalendarContract.Events.CONTENT_URI,
            arrayOf(
                CalendarContract.Events._ID,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.DTSTART,
                CalendarContract.Events.RRULE,
                CalendarContract.Events.ALL_DAY,
                CalendarContract.Events.CALENDAR_ID,
                CalendarContract.Events.DESCRIPTION,
            ),
            "${CalendarContract.Events.DELETED} = 0",
            null, null,
        )?.use { c ->
            while (c.moveToNext()) {
                val title = c.getString(1)?.trim() ?: continue
                if (title.isEmpty()) continue
                val start = c.getLong(2)
                val rrule = c.getString(3)
                val allDay = c.getInt(4) == 1
                val repeating = rrule != null && (rrule.contains("FREQ=YEARLY") || rrule.contains("FREQ=MONTHLY"))
                if (!repeating && !(allDay && start in now - 86_400_000L..until)) continue
                val cal = Calendar.getInstance(if (allDay) TimeZone.getTimeZone("UTC") else TimeZone.getDefault())
                cal.timeInMillis = start
                val (calName, owner) = names[c.getLong(5)] ?: Pair("", "")
                out.add(
                    mapOf(
                        "id" to c.getLong(0),
                        "title" to title,
                        "year" to cal.get(Calendar.YEAR),
                        "month" to cal.get(Calendar.MONTH) + 1,
                        "day" to cal.get(Calendar.DAY_OF_MONTH),
                        "rrule" to rrule,
                        "calendar" to calName,
                        "owner" to owner,
                        "description" to (c.getString(6) ?: ""),
                    ),
                )
            }
        }
        return out
    }

    fun delete(cr: ContentResolver, ids: List<Long>) {
        for (id in ids) {
            cr.delete(ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id), null, null)
        }
    }
}

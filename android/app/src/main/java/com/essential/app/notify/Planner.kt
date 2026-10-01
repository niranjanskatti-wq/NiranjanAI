package com.essential.app.notify

import com.essential.app.core.Days
import com.essential.app.core.TimeUtil
import com.essential.app.data.Cat
import com.essential.app.data.Repo
import java.time.DayOfWeek
import java.time.LocalDate

/**
 * Computes every local reminder for the coming days. The alarm system only ever arms the
 * next one; when it fires, the due events are handled and the next one is armed.
 */
object Planner {
    object K {
        const val CHECKIN = "checkin"; const val BLOCK = "block"; const val REVIEW = "review"
        const val WIND = "wind"; const val SLEEP = "sleep"; const val BACKUP = "backup"; const val UNCOMMIT = "uncommit"
        const val OBSTACLE = "obstacle"; const val REPORT = "report"; const val SPRINT_END = "sprint_end"; const val FOLLOW_UP = "follow_up"
        const val REFRESH = "refresh"
    }

    data class Ev(val at: Long, val kind: String, val date: LocalDate, val hour: Int = -1, val text: String = "", val blockTitle: String = "")

    fun events(repo: Repo, fromMs: Long, days: Int = 2): List<Ev> {
        val s = repo.settings
        val out = ArrayList<Ev>()
        val today = TimeUtil.logicalDate(TimeUtil.at(fromMs), repo.dayStart())
        for (i in -1..days) {
            val date = today.plusDays(i.toLong())
            val day = Days.resolve(repo, date)
            fun at(min: Int) = day.at(min).toInstant().toEpochMilli()
            if (s.bool("n_checkin")) day.hours.forEach { h ->
                out.add(Ev(day.slotEnd(h).toInstant().toEpochMilli(), K.CHECKIN, date, h))
            }
            for (b in day.blocks) {
                out.add(Ev(at(b.start), K.REFRESH, date))
                if (s.bool("n_block") && b.category != Cat.SLEEP)
                    out.add(Ev(at(b.start) - 5 * 60_000L, K.BLOCK, date, blockTitle = b.title, text = TimeUtil.fmtTime(b.start)))
            }
            if (s.bool("n_review")) out.add(Ev(at(s.reviewTime(day.mode)), K.REVIEW, date))
            if (s.bool("n_wind")) out.add(Ev(at(day.sleep) - 15 * 60_000L, K.WIND, date))
            if (s.bool("n_sleep")) out.add(Ev(at(day.wake) + 15 * 60_000L, K.SLEEP, date))
            if (date.dayOfWeek == DayOfWeek.SUNDAY) {
                if (s.bool("n_tools")) {
                    out.add(Ev(at(12 * 60), K.OBSTACLE, date))
                    out.add(Ev(at(19 * 60), K.REPORT, date))
                }
                if (s.bool("n_backup") || s.bool("backup_auto")) out.add(Ev(at(19 * 60 + 30), K.BACKUP, date))
            }
            if (s.bool("n_tools")) {
                if (date.dayOfMonth == 1) out.add(Ev(at(7 * 60 + 40), K.UNCOMMIT, date))
                if (date.dayOfMonth == 15) out.add(Ev(at(7 * 60 + 40), K.FOLLOW_UP, date))
            }
            // Sprint end: morning after the last sprint day.
            val yesterdaySprint = repo.activeSprint(date.minusDays(1))
            if (yesterdaySprint != null && yesterdaySprint.end == date.minusDays(1))
                out.add(Ev(at(day.wake) + 20 * 60_000L, K.SPRINT_END, date, text = yesterdaySprint.goal))
        }
        return out.filter { it.at > fromMs }.sortedBy { it.at }
    }

    fun inQuietHours(repo: Repo, millis: Long): Boolean {
        val s = repo.settings
        if (!s.bool("quiet_enabled")) return false
        val m = TimeUtil.minuteOfDay(TimeUtil.at(millis))
        val a = s.int("quiet_start"); val b = s.int("quiet_end")
        return if (a <= b) m in a until b else (m >= a || m < b)
    }
}

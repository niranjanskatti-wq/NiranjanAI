// Background jobs that run while the app is open: reminder notifications and the weekly backup.
import { useEffect } from 'react'
import { db } from '@/db'
import { dateKey, timeToMinutes } from '@/lib/date'
import { notify } from '@/lib/notify'
import type { Settings } from '@/lib/settings'
import { isBackupDue, runBackup } from '@/lib/backup'
import { isEveningReviewDue, isWeeklyReviewDue } from '@/lib/reviews'

const FIRED_KEY = 'deepwork.reminders'

function firedMap(): Record<string, string> {
  try {
    return JSON.parse(localStorage.getItem(FIRED_KEY) || '{}')
  } catch {
    return {}
  }
}
function markFired(kind: string, stamp: string) {
  const m = firedMap()
  m[kind] = stamp
  try {
    localStorage.setItem(FIRED_KEY, JSON.stringify(m))
  } catch {
    /* ignore */
  }
}

export function useReminders(settings: Settings) {
  useEffect(() => {
    if (!settings.modules.notifications) return
    const check = async () => {
      const now = new Date()
      const today = dateKey(now)
      const mins = now.getHours() * 60 + now.getMinutes()
      const fired = firedMap()
      const n = settings.notifications
      // Fire within a 2-hour window after the scheduled time so a reminder isn't lost if the app
      // was opened a little late, but don't nag about something long past.
      const inWindow = (t: string) => mins >= timeToMinutes(t) && mins < timeToMinutes(t) + 120

      if (n.morning.enabled && settings.modules.priorities && fired.morning !== today && inWindow(n.morning.time)) {
        markFired('morning', today)
        const prios = (await db.tasks.where('priority_date').equals(today).toArray()).filter((t) => t.is_priority)
        if (prios.length === 0) await notify(settings, 'morning', 'Plan your day', `Pick your ${settings.priorities.label.toLowerCase()} for today.`)
        else await notify(settings, 'morning', 'Good morning', `You have ${prios.length} priorities lined up. Start with the first one.`)
      }
      if (n.evening.enabled && settings.modules.eveningReview && fired.evening !== today && inWindow(settings.eveningReview.time)) {
        if (await isEveningReviewDue(settings, now)) {
          markFired('evening', today)
          await notify(settings, 'evening', 'Evening review', 'Two minutes to look back at today and pick tomorrow’s priorities.')
        }
      }
      if (n.weekly.enabled && settings.modules.weeklyReview && fired.weekly !== today && now.getDay() === settings.weeklyReview.day && inWindow(settings.weeklyReview.time)) {
        if (await isWeeklyReviewDue(settings, now)) {
          markFired('weekly', today)
          await notify(settings, 'weekly', 'Weekly review', 'Take ten minutes to review your week.')
        }
      }
    }
    void check()
    const iv = setInterval(() => void check(), 30_000)
    return () => clearInterval(iv)
  }, [settings])
}

export function useAutoBackup(settings: Settings) {
  const due = isBackupDue(settings)
  useEffect(() => {
    if (!due) return
    let cancelled = false
    const attempt = () => {
      if (cancelled || !navigator.onLine) return
      const last = settings.backup.lastAttemptAt ?? 0
      if (Date.now() - last < 10 * 60_000 && settings.backup.needsReconnect) return
      void runBackup({ interactive: false })
    }
    const t = setTimeout(attempt, 2500)
    window.addEventListener('online', attempt)
    return () => {
      cancelled = true
      clearTimeout(t)
      window.removeEventListener('online', attempt)
    }
    // Only re-run when "due" flips or connection state changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [due, settings.backup.connected])
}

import { db } from '@/db'
import { dateKey, timeToMinutes } from './date'
import type { Settings } from './settings'
import { addDays, startOfDay } from 'date-fns'

export async function isEveningReviewDue(settings: Settings, now = new Date()) {
  if (!settings.modules.eveningReview) return false
  const mins = now.getHours() * 60 + now.getMinutes()
  if (mins < timeToMinutes(settings.eveningReview.time)) return false
  const today = dateKey(now)
  const existing = await db.reviews.where('date').equals(today).filter((r) => r.type === 'daily').count()
  return existing === 0
}

/** Start of the current weekly-review period (the most recent review day at review time). */
export function weeklyPeriodStart(settings: Settings, now = new Date()) {
  const d = startOfDay(now)
  const diff = (d.getDay() - settings.weeklyReview.day + 7) % 7
  const day = addDays(d, -diff)
  const t = timeToMinutes(settings.weeklyReview.time)
  day.setHours(Math.floor(t / 60), t % 60, 0, 0)
  if (day.getTime() > now.getTime()) return addDays(day, -7)
  return day
}

export async function isWeeklyReviewDue(settings: Settings, now = new Date()) {
  if (!settings.modules.weeklyReview) return false
  const start = weeklyPeriodStart(settings, now)
  // Only nag within 3 days of the review day.
  if (now.getTime() - start.getTime() > 3 * 86400000) return false
  const existing = await db.reviews.where('created_at').aboveOrEqual(start.getTime() - 12 * 3600000).filter((r) => r.type === 'weekly').count()
  return existing === 0
}

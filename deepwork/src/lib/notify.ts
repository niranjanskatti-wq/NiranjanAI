// Notifications. On Android they are real scheduled notifications (they fire even when Deepwork
// is closed). On the web they're shown through the service worker while the app is open.
// Both respect the master switch, per-reminder toggles and quiet hours.
import { addDays, startOfDay } from 'date-fns'
import { db } from '@/db'
import { dateKey, inTimeRange, timeToMinutes } from './date'
import type { Settings } from './settings'
import { isNative } from './native'
import { weeklyPeriodStart } from './reviews'

export type NotifyKind = 'morning' | 'evening' | 'weekly' | 'breakOver' | 'sessionComplete'
export type PermissionState = NotificationPermission | 'unsupported'

export function notificationsSupported() {
  return isNative || (typeof window !== 'undefined' && 'Notification' in window)
}

async function localNotifications() {
  return (await import('@capacitor/local-notifications')).LocalNotifications
}

export async function getPermission(): Promise<PermissionState> {
  if (isNative) {
    const LN = await localNotifications()
    const p = await LN.checkPermissions()
    return p.display === 'granted' ? 'granted' : p.display === 'denied' ? 'denied' : 'default'
  }
  return notificationsSupported() ? Notification.permission : 'unsupported'
}

export async function requestPermission(): Promise<PermissionState> {
  if (isNative) {
    const LN = await localNotifications()
    const p = await LN.requestPermissions()
    return p.display === 'granted' ? 'granted' : p.display === 'denied' ? 'denied' : 'default'
  }
  if (!notificationsSupported()) return 'unsupported'
  try {
    return await Notification.requestPermission()
  } catch {
    return Notification.permission
  }
}

/** Android 12+: exact alarms let timer alerts fire on the second. */
export async function exactAlarmStatus(): Promise<'granted' | 'denied' | 'unsupported'> {
  if (!isNative) return 'unsupported'
  try {
    const LN = await localNotifications()
    const r = await LN.checkExactNotificationSetting()
    return r.exact_alarm === 'granted' ? 'granted' : 'denied'
  } catch {
    return 'unsupported'
  }
}

export async function openExactAlarmSettings() {
  const LN = await localNotifications()
  await LN.changeExactNotificationSetting()
}

export function kindEnabled(settings: Settings, kind: NotifyKind): boolean {
  const n = settings.notifications
  if (!settings.modules.notifications) return false
  switch (kind) {
    case 'morning':
      return n.morning.enabled && settings.modules.priorities
    case 'evening':
      return n.evening.enabled && settings.modules.eveningReview
    case 'weekly':
      return n.weekly.enabled && settings.modules.weeklyReview
    case 'breakOver':
      return n.breakOver && settings.modules.breaks
    case 'sessionComplete':
      return n.sessionComplete
  }
}

export function inQuietHours(settings: Settings, at = new Date()) {
  const q = settings.notifications.quietHours
  return q.enabled && inTimeRange(at, q.start, q.end)
}

const SMALL_ICON = 'ic_stat_deepwork'
let immediateId = 5000

export async function notify(settings: Settings, kind: NotifyKind, title: string, body: string, opts: { force?: boolean } = {}) {
  if (!opts.force && (!kindEnabled(settings, kind) || inQuietHours(settings))) return false
  if ((await getPermission()) !== 'granted') return false
  if (isNative) {
    const LN = await localNotifications()
    await LN.schedule({ notifications: [{ id: immediateId++, title, body, smallIcon: SMALL_ICON }] })
    return true
  }
  const options: NotificationOptions = { body, icon: '/pwa-192.png', badge: '/pwa-192.png', tag: kind }
  try {
    const reg = 'serviceWorker' in navigator ? await navigator.serviceWorker.getRegistration() : undefined
    if (reg) {
      await reg.showNotification(title, options)
      return true
    }
    new Notification(title, options)
    return true
  } catch {
    try {
      new Notification(title, options)
      return true
    } catch {
      return false
    }
  }
}

// ------------------------------------------------------------ Android scheduled notifications

export const TIMER_NOTIFICATION_ID = 1001

/** Schedule (or clear) the alert for the running timer — fires even if the app is closed. */
export async function scheduleTimerAlert(settings: Settings, at: number | null, kind: 'sessionComplete' | 'breakOver') {
  if (!isNative) return
  const LN = await localNotifications()
  await LN.cancel({ notifications: [{ id: TIMER_NOTIFICATION_ID }] }).catch(() => {})
  if (at === null || at <= Date.now()) return
  if (!kindEnabled(settings, kind) || inQuietHours(settings, new Date(at))) return
  if ((await getPermission()) !== 'granted') return
  const title = kind === 'sessionComplete' ? 'Session complete' : 'Break is over'
  const body = kind === 'sessionComplete' ? 'Nice work. Open Deepwork to note what you got done.' : 'Ready for the next session?'
  await LN.schedule({ notifications: [{ id: TIMER_NOTIFICATION_ID, title, body, smallIcon: SMALL_ICON, schedule: { at: new Date(at), allowWhileIdle: true } }] })
}

const REMINDER_BASE = 3000

function at(day: Date, time: string) {
  const d = new Date(day)
  const m = timeToMinutes(time)
  d.setHours(Math.floor(m / 60), m % 60, 0, 0)
  return d
}

/** Re-plan the next week of reminders. Called on launch, on resume, and whenever settings or reviews change. */
export async function rescheduleReminders(settings: Settings) {
  if (!isNative) return
  const LN = await localNotifications()
  const pending = await LN.getPending().catch(() => ({ notifications: [] as { id: number }[] }))
  const ours = pending.notifications.filter((n) => n.id >= REMINDER_BASE && n.id < REMINDER_BASE + 1000)
  if (ours.length) await LN.cancel({ notifications: ours.map((n) => ({ id: n.id })) })
  if (!settings.modules.notifications || (await getPermission()) !== 'granted') return

  const now = new Date()
  const today = startOfDay(now)
  const list: { id: number; title: string; body: string; at: Date }[] = []
  const eveningDoneToday = (await db.reviews.where('date').equals(dateKey(now)).filter((r) => r.type === 'daily').count()) > 0

  for (let i = 0; i < 7; i++) {
    const day = addDays(today, i)
    if (kindEnabled(settings, 'morning')) {
      list.push({ id: REMINDER_BASE + i, title: 'Plan your day', body: `Pick today's ${settings.priorities.label.toLowerCase()} and start your first session.`, at: at(day, settings.notifications.morning.time) })
    }
    if (kindEnabled(settings, 'evening') && !(i === 0 && eveningDoneToday)) {
      list.push({ id: REMINDER_BASE + 100 + i, title: 'Evening review', body: 'Two minutes to look back at today and pick tomorrow’s priorities.', at: at(day, settings.eveningReview.time) })
    }
  }
  if (kindEnabled(settings, 'weekly')) {
    const periodStart = weeklyPeriodStart(settings, now)
    const doneThisPeriod = (await db.reviews.where('created_at').aboveOrEqual(periodStart.getTime() - 12 * 3600000).filter((r) => r.type === 'weekly').count()) > 0
    for (let w = 0; w < 3; w++) {
      const d = addDays(today, ((settings.weeklyReview.day - today.getDay() + 7) % 7) + 7 * w)
      const when = at(d, settings.weeklyReview.time)
      if (doneThisPeriod && when.getTime() - periodStart.getTime() < 7 * 86400000) continue
      list.push({ id: REMINDER_BASE + 200 + w, title: 'Weekly review', body: 'Take ten minutes to review your week.', at: when })
    }
  }
  const future = list.filter((n) => n.at.getTime() > Date.now() + 30_000 && !inQuietHours(settings, n.at))
  if (future.length) {
    await LN.schedule({
      notifications: future.map((n) => ({ id: n.id, title: n.title, body: n.body, smallIcon: SMALL_ICON, schedule: { at: n.at, allowWhileIdle: true } })),
    })
  }
}

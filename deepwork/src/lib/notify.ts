// Local notifications. Uses the service worker when available so notifications show even when the
// tab is in the background. Respects the master switch, per-reminder toggles and quiet hours.
import { inTimeRange } from './date'
import type { Settings } from './settings'

export type NotifyKind = 'morning' | 'evening' | 'weekly' | 'breakOver' | 'sessionComplete'

export function notificationsSupported() {
  return typeof window !== 'undefined' && 'Notification' in window
}

export function permission(): NotificationPermission | 'unsupported' {
  return notificationsSupported() ? Notification.permission : 'unsupported'
}

export async function requestPermission(): Promise<NotificationPermission | 'unsupported'> {
  if (!notificationsSupported()) return 'unsupported'
  try {
    return await Notification.requestPermission()
  } catch {
    return Notification.permission
  }
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

export function inQuietHours(settings: Settings, now = new Date()) {
  const q = settings.notifications.quietHours
  return q.enabled && inTimeRange(now, q.start, q.end)
}

export async function notify(settings: Settings, kind: NotifyKind, title: string, body: string, opts: { force?: boolean } = {}) {
  if (!opts.force && (!kindEnabled(settings, kind) || inQuietHours(settings))) return false
  if (permission() !== 'granted') return false
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

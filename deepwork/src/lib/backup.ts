// Weekly backup scheduling. A PWA can't run reliably in the background, so the backup runs the
// next time the app is opened (online) once it's due. Failures while offline retry silently.
import { addDays, startOfDay } from 'date-fns'
import { readSettings, updateSettings } from '@/state/settings'
import type { Settings } from './settings'
import { backupFilename, buildBackup } from './data'
import { DriveAuthError, DriveConfigError, pruneBackups, requestToken, uploadBackup, validToken } from './drive'

/** Most recent occurrence of the configured backup weekday at 00:00 that is <= now. */
export function lastScheduled(day: number, now = new Date()) {
  const d = startOfDay(now)
  const diff = (d.getDay() - day + 7) % 7
  return addDays(d, -diff)
}

export function isBackupDue(s: Settings, now = new Date()) {
  if (!s.modules.backup || !s.backup.connected) return false
  if (!s.backup.lastBackupAt) return true
  return s.backup.lastBackupAt < lastScheduled(s.backup.day, now).getTime()
}

export function nextBackupDate(s: Settings, now = new Date()): Date {
  if (isBackupDue(s, now)) return now
  return addDays(lastScheduled(s.backup.day, now), 7)
}

let running = false

export type BackupOutcome = 'ok' | 'needs-auth' | 'offline' | 'error' | 'busy' | 'disabled'

export async function runBackup({ interactive }: { interactive: boolean }): Promise<{ outcome: BackupOutcome; message?: string }> {
  if (running) return { outcome: 'busy' }
  const s = await readSettings()
  if (!s.modules.backup || !s.backup.connected) return { outcome: 'disabled' }
  running = true
  try {
    let token = validToken()
    if (!token) {
      if (!interactive) {
        await updateSettings((d) => {
          d.backup.needsReconnect = true
        })
        return { outcome: 'needs-auth' }
      }
      token = await requestToken('')
    }
    const file = await buildBackup()
    await uploadBackup(token, backupFilename(), JSON.stringify(file))
    await pruneBackups(token, s.backup.retention)
    await updateSettings((d) => {
      d.backup.lastBackupAt = Date.now()
      d.backup.lastAttemptAt = Date.now()
      d.backup.lastError = null
      d.backup.needsReconnect = false
    })
    return { outcome: 'ok' }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    if (!navigator.onLine || e instanceof TypeError) {
      // Offline or network failure: retry silently next time the app opens online.
      await updateSettings((d) => {
        d.backup.lastAttemptAt = Date.now()
      })
      return { outcome: 'offline', message: 'You appear to be offline. The backup will retry automatically.' }
    }
    if (e instanceof DriveAuthError) {
      await updateSettings((d) => {
        d.backup.needsReconnect = true
        d.backup.lastAttemptAt = Date.now()
        d.backup.lastError = message
      })
      return { outcome: 'needs-auth', message }
    }
    await updateSettings((d) => {
      d.backup.lastAttemptAt = Date.now()
      d.backup.lastError = e instanceof DriveConfigError ? message : message
    })
    return { outcome: 'error', message }
  } finally {
    running = false
  }
}

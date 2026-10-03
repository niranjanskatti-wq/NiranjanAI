import { addDays, format, parse, startOfDay, startOfWeek, differenceInCalendarDays } from 'date-fns'

export const DAY_NAMES = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
export const DAY_SHORT = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

export function dateKey(d: Date | number = new Date()): string {
  return format(d, 'yyyy-MM-dd')
}

export function parseDateKey(key: string): Date {
  return parse(key, 'yyyy-MM-dd', new Date())
}

export function todayKey() {
  return dateKey(new Date())
}

export function tomorrowKey() {
  return dateKey(addDays(new Date(), 1))
}

export function timeToMinutes(t: string): number {
  const [h, m] = t.split(':').map(Number)
  return (h || 0) * 60 + (m || 0)
}

export function minutesToTime(min: number): string {
  const m = ((min % 1440) + 1440) % 1440
  return `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`
}

export function formatClock(t: string): string {
  const mins = timeToMinutes(t)
  const h = Math.floor(mins / 60)
  const m = mins % 60
  const suffix = h >= 12 ? 'pm' : 'am'
  const h12 = h % 12 === 0 ? 12 : h % 12
  return m === 0 ? `${h12} ${suffix}` : `${h12}:${String(m).padStart(2, '0')} ${suffix}`
}

export function formatHour(h: number): string {
  const suffix = h >= 12 && h < 24 ? 'pm' : 'am'
  const h12 = h % 12 === 0 ? 12 : h % 12
  return `${h12} ${suffix}`
}

/** "1h 25m", "45m", "0m" */
export function formatDuration(seconds: number): string {
  const totalMin = Math.round(seconds / 60)
  const h = Math.floor(totalMin / 60)
  const m = totalMin % 60
  if (h === 0) return `${m}m`
  if (m === 0) return `${h}h`
  return `${h}h ${m}m`
}

/** Timer display: mm:ss or h:mm:ss; or without seconds. */
export function formatTimer(seconds: number, hideSeconds = false): string {
  const s = Math.max(0, Math.floor(seconds))
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  if (hideSeconds) {
    const totalMin = Math.ceil(s / 60)
    const hh = Math.floor(totalMin / 60)
    const mm = totalMin % 60
    return hh > 0 ? `${hh}h ${String(mm).padStart(2, '0')}m` : `${mm}m`
  }
  const mm = String(m).padStart(h > 0 ? 2 : 2, '0')
  const ss = String(sec).padStart(2, '0')
  return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`
}

export function relativeDays(ts: number): string {
  const d = differenceInCalendarDays(new Date(), ts)
  if (d <= 0) return 'today'
  if (d === 1) return 'yesterday'
  if (d < 7) return `${d} days ago`
  if (d < 14) return '1 week ago'
  if (d < 60) return `${Math.floor(d / 7)} weeks ago`
  return format(ts, 'MMM d, yyyy')
}

export function greeting(now = new Date()): string {
  const h = now.getHours()
  if (h < 5) return 'Good night'
  if (h < 12) return 'Good morning'
  if (h < 18) return 'Good afternoon'
  return 'Good evening'
}

export function isWeekend(d: Date) {
  const day = d.getDay()
  return day === 0 || day === 6
}

/** Is the current local time inside [start, end) — handles ranges that wrap past midnight. */
export function inTimeRange(now: Date, start: string, end: string) {
  const n = now.getHours() * 60 + now.getMinutes()
  const s = timeToMinutes(start)
  const e = timeToMinutes(end)
  if (s === e) return false
  return s < e ? n >= s && n < e : n >= s || n < e
}

export function weekStart(d: Date = new Date(), weekStartsOn: 0 | 1 = 1) {
  return startOfWeek(d, { weekStartsOn })
}

export function lastNDays(n: number, end = new Date()): Date[] {
  const out: Date[] = []
  const e = startOfDay(end)
  for (let i = n - 1; i >= 0; i--) out.push(addDays(e, -i))
  return out
}

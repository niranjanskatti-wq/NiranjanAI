// On-device, rule-based statistics. No network, no AI — just arithmetic over local records.
import { addDays, differenceInCalendarDays, startOfDay } from 'date-fns'
import type { Distraction, Project, Session, Task, TimeBlock } from '@/db/types'
import { DAY_NAMES, dateKey, formatHour, isWeekend, lastNDays } from './date'
import type { InsightCardId, Settings } from './settings'
import { pluralize, sum } from './utils'

export const COUNTED = (s: Session) => s.result !== 'interrupted'

export interface DayStats {
  focusSec: number
  sessions: number // completed (non-interrupted) sessions
  allSessions: number
  tasksDone: number
  distractions: number
}

export function buildDayIndex(sessions: Session[], tasks: Task[], distractions: Distraction[]) {
  const map = new Map<string, DayStats>()
  const get = (k: string) => {
    let v = map.get(k)
    if (!v) map.set(k, (v = { focusSec: 0, sessions: 0, allSessions: 0, tasksDone: 0, distractions: 0 }))
    return v
  }
  for (const s of sessions) {
    const d = get(dateKey(s.started_at))
    d.focusSec += s.actual_duration
    d.allSessions++
    if (COUNTED(s)) d.sessions++
  }
  for (const t of tasks) if (t.status === 'done' && t.completed_at) get(dateKey(t.completed_at)).tasksDone++
  for (const x of distractions) get(dateKey(x.timestamp)).distractions++
  return map
}

export const EMPTY_DAY: DayStats = { focusSec: 0, sessions: 0, allSessions: 0, tasksDone: 0, distractions: 0 }

export function goalProgress(settings: Settings, day: DayStats) {
  const { type, target } = settings.dailyGoal
  const value = type === 'minutes' ? Math.round(day.focusSec / 60) : type === 'sessions' ? day.sessions : day.tasksDone
  const unit = type === 'minutes' ? 'min' : type === 'sessions' ? 'sessions' : 'tasks'
  return { value, target, unit, ratio: target > 0 ? Math.min(1, value / target) : 0 }
}

// ---------------------------------------------------------------- Streaks

export function dayQualifies(settings: Settings, d: DayStats | undefined): boolean {
  if (!d) return false
  const { countsAs, amount } = settings.streaks
  if (countsAs === 'session') return d.sessions >= Math.max(1, amount)
  if (countsAs === 'minutes') return d.focusSec / 60 >= Math.max(1, amount)
  return d.tasksDone >= Math.max(1, amount)
}

export function streakRuleLabel(settings: Settings) {
  const { countsAs, amount } = settings.streaks
  const unit =
    countsAs === 'session' ? pluralize(Math.max(1, amount), 'session') : countsAs === 'minutes' ? `${amount} focus minutes` : pluralize(Math.max(1, amount), 'task')
  const rule = settings.streaks.rule === 'strict' ? 'every day' : settings.streaks.rule === 'weekdays' ? 'every weekday' : 'never missing twice'
  return `${unit}, ${rule}`
}

export interface StreakInfo {
  current: number
  best: number
  todayDone: boolean
  atRisk: boolean // never-miss-twice: yesterday was missed
}

export function computeStreak(settings: Settings, index: Map<string, DayStats>, today = new Date()): StreakInfo {
  const keys = [...index.keys()].sort()
  const todayStart = startOfDay(today)
  if (keys.length === 0) return { current: 0, best: 0, todayDone: false, atRisk: false }
  const first = startOfDay(new Date(keys[0] + 'T00:00:00'))
  const days = Math.max(0, differenceInCalendarDays(todayStart, first))
  const rule = settings.streaks.rule
  let s = 0
  let misses = 0
  let best = 0
  let prev = 0
  let prevMisses = 0
  let todayQ = false
  for (let i = 0; i <= days; i++) {
    const d = addDays(first, i)
    const q = dayQualifies(settings, index.get(dateKey(d)))
    prev = s
    prevMisses = misses
    if (q) {
      s++
      misses = 0
    } else if (rule === 'weekdays' && isWeekend(d)) {
      // weekends neither count nor break the streak
    } else if (rule === 'neverMissTwice') {
      misses++
      if (misses >= 2) s = 0
    } else {
      s = 0
    }
    if (i === days) todayQ = q
    best = Math.max(best, s)
  }
  // Today is still in progress: if it hasn't qualified yet, the streak stands at yesterday's value.
  const current = todayQ ? s : prev
  const atRisk = rule === 'neverMissTwice' && !todayQ && prevMisses === 1 && current > 0
  return { current, best, todayDone: todayQ, atRisk }
}

// ---------------------------------------------------------------- Planned vs done

export function plannedTasksForDay(day: string, tasks: Task[], blocks: TimeBlock[]) {
  const ids = new Set<string>()
  for (const t of tasks) if (t.is_priority && t.priority_date === day) ids.add(t.id)
  for (const b of blocks) if (b.date === day && b.task_id) ids.add(b.task_id)
  return tasks.filter((t) => ids.has(t.id))
}

export function plannedVsDone(day: string, tasks: Task[], blocks: TimeBlock[]) {
  const planned = plannedTasksForDay(day, tasks, blocks)
  const plannedIds = new Set(planned.map((t) => t.id))
  const done = planned.filter((t) => t.status === 'done')
  const unplannedDone = tasks.filter((t) => t.status === 'done' && t.completed_at && dateKey(t.completed_at) === day && !plannedIds.has(t.id))
  return { planned, done, unplannedDone }
}

// ---------------------------------------------------------------- Best focus time

export interface BestTime {
  startHour: number
  endHour: number
  rate: number
  count: number
}

export const BEST_TIME_MIN_SESSIONS = 8
export const BEST_TIME_MIN_BUCKET = 3

/** Two-hour window with the highest completion rate over the last 14 days. */
export function bestFocusTime(sessions: Session[], now = Date.now(), days = 14): BestTime | null {
  const since = startOfDay(addDays(now, -(days - 1))).getTime()
  const recent = sessions.filter((s) => s.started_at >= since)
  if (recent.length < BEST_TIME_MIN_SESSIONS) return null
  const buckets = new Map<number, { done: number; total: number }>()
  for (const s of recent) {
    const h = new Date(s.started_at).getHours()
    const b = Math.floor(h / 2) * 2
    const v = buckets.get(b) ?? { done: 0, total: 0 }
    v.total++
    if (s.result === 'done') v.done++
    buckets.set(b, v)
  }
  let best: BestTime | null = null
  for (const [h, v] of buckets) {
    if (v.total < BEST_TIME_MIN_BUCKET) continue
    const rate = v.done / v.total
    if (!best || rate > best.rate || (rate === best.rate && v.total > best.count)) best = { startHour: h, endHour: h + 2, rate, count: v.total }
  }
  return best
}

export function bestTimeLabel(b: BestTime) {
  return `${formatHour(b.startHour)} – ${formatHour(b.endHour % 24)}`
}

// ---------------------------------------------------------------- Range helpers

export function rangeStart(range: number, now = Date.now()): number {
  if (range === 0) return 0
  return startOfDay(addDays(now, -(range - 1))).getTime()
}

export function rangeDays(range: number, sessions: Session[], now = new Date()): Date[] {
  if (range > 0) return lastNDays(range, now)
  const first = sessions.reduce((m, s) => Math.min(m, s.started_at), now.getTime())
  const n = Math.min(730, Math.max(7, differenceInCalendarDays(now, first) + 1))
  return lastNDays(n, now)
}

export function completionRate(list: Session[]) {
  if (list.length === 0) return null
  return list.filter((s) => s.result === 'done').length / list.length
}

/** Focus minutes per weekday × hour, spreading each session over the hours it spanned. */
export function heatmap(sessions: Session[]) {
  const grid: number[][] = Array.from({ length: 7 }, () => Array(24).fill(0))
  for (const s of sessions) {
    let t = s.started_at
    const end = s.started_at + s.actual_duration * 1000
    let guard = 0
    while (t < end && guard++ < 48) {
      const d = new Date(t)
      const hourEnd = new Date(d)
      hourEnd.setMinutes(60, 0, 0)
      const chunk = Math.min(end, hourEnd.getTime()) - t
      grid[d.getDay()][d.getHours()] += chunk / 60000
      t += chunk
    }
  }
  return grid
}

// ---------------------------------------------------------------- Insight cards

export interface InsightCard {
  id: InsightCardId
  title: string
  body: string
  tone: 'neutral' | 'positive' | 'attention'
}

const PERIODS = [
  { label: 'before 10 am', test: (h: number) => h < 10 },
  { label: 'between 10 am and noon', test: (h: number) => h >= 10 && h < 12 },
  { label: 'between noon and 3 pm', test: (h: number) => h >= 12 && h < 15 },
  { label: 'after 3 pm', test: (h: number) => h >= 15 },
]

export function computeInsightCards(input: {
  settings: Settings
  sessions: Session[] // already filtered to range
  allSessions: Session[]
  distractions: Distraction[] // already filtered to range
  tasks: Task[]
  projects: Project[]
  range: number
  now?: number
}): InsightCard[] {
  const { settings, sessions, allSessions, distractions, tasks, projects, range } = input
  const now = input.now ?? Date.now()
  const cards: InsightCard[] = []
  const enabled = new Set(settings.insights.cards)
  const mod = settings.modules

  // When do interruptions happen?
  if (enabled.has('interruptionTime') && mod.distractions && distractions.length >= 5) {
    const counts = PERIODS.map((p) => distractions.filter((d) => p.test(new Date(d.timestamp).getHours())).length)
    const max = Math.max(...counts)
    const idx = counts.indexOf(max)
    const share = max / distractions.length
    if (share >= 0.4) {
      cards.push({
        id: 'interruptionTime',
        title: `Most interruptions happen ${PERIODS[idx].label}.`,
        body: `${Math.round(share * 100)}% of ${distractions.length} logged distractions. Consider protecting that window or scheduling lighter work there.`,
        tone: 'attention',
      })
    }
  }

  // Which session length finishes best?
  if (enabled.has('bestLength')) {
    const byLen = new Map<number, Session[]>()
    for (const s of sessions) {
      const m = Math.round(s.planned_duration / 60)
      const list = byLen.get(m) ?? []
      list.push(s)
      byLen.set(m, list)
    }
    const eligible = [...byLen.entries()].filter(([, l]) => l.length >= 3)
    if (eligible.length >= 2) {
      const ranked = eligible.map(([m, l]) => ({ m, rate: completionRate(l)!, n: l.length })).sort((a, b) => b.rate - a.rate || b.n - a.n)
      const top = ranked[0]
      cards.push({
        id: 'bestLength',
        title: `Your ${top.m}-minute sessions have the highest completion rate.`,
        body: `${Math.round(top.rate * 100)}% marked done across ${top.n} sessions, compared with ${Math.round(ranked[ranked.length - 1].rate * 100)}% for ${ranked[ranked.length - 1].m}-minute sessions.`,
        tone: 'positive',
      })
    }
  }

  // Planned priorities finished
  if (enabled.has('priorityCompletion') && mod.priorities) {
    const since = rangeStart(range, now)
    const start = dateKey(since || 0)
    const end = dateKey(now)
    const planned = tasks.filter((t) => t.is_priority && t.priority_date && t.priority_date >= start && t.priority_date <= end)
    if (planned.length >= 3) {
      const done = planned.filter((t) => t.status === 'done').length
      const pct = Math.round((done / planned.length) * 100)
      cards.push({
        id: 'priorityCompletion',
        title: `You finished ${pct}% of planned priorities ${range === 7 ? 'this week' : range === 0 ? 'overall' : `in the last ${range} days`}.`,
        body: `${done} of ${planned.length} priorities done.${pct < 60 ? ' Picking fewer priorities may help them actually get finished.' : ''}`,
        tone: pct >= 70 ? 'positive' : 'neutral',
      })
    }
  }

  // Top distraction
  if (enabled.has('topDistraction') && mod.distractions && distractions.length >= 3) {
    const counts = new Map<string, number>()
    for (const d of distractions) counts.set(d.reason, (counts.get(d.reason) ?? 0) + 1)
    const [reason, n] = [...counts.entries()].sort((a, b) => b[1] - a[1])[0]
    const perSession = sessions.length ? distractions.length / sessions.length : 0
    cards.push({
      id: 'topDistraction',
      title: `${reason} is your most common distraction.`,
      body: `${Math.round((n / distractions.length) * 100)}% of distractions. You average ${perSession.toFixed(1)} distractions per session.`,
      tone: 'attention',
    })
  }

  // Best weekday
  if (enabled.has('bestDay') && sessions.length >= 7) {
    const totals = Array(7).fill(0)
    const daysSeen: Set<string>[] = Array.from({ length: 7 }, () => new Set())
    for (const s of sessions) {
      const d = new Date(s.started_at)
      totals[d.getDay()] += s.actual_duration
      daysSeen[d.getDay()].add(dateKey(d))
    }
    const avg = totals.map((t, i) => (daysSeen[i].size ? t / daysSeen[i].size : 0))
    const best = avg.indexOf(Math.max(...avg))
    if (avg[best] > 0) {
      cards.push({
        id: 'bestDay',
        title: `${DAY_NAMES[best]}s are your most focused day.`,
        body: `You average ${Math.round(avg[best] / 60)} focus minutes on ${DAY_NAMES[best]}s.`,
        tone: 'positive',
      })
    }
  }

  // Trend: last 7 days vs previous 7
  if (enabled.has('trend')) {
    const thisStart = rangeStart(7, now)
    const prevStart = thisStart - 7 * 86400000
    const cur = sum(allSessions.filter((s) => s.started_at >= thisStart).map((s) => s.actual_duration))
    const prev = sum(allSessions.filter((s) => s.started_at >= prevStart && s.started_at < thisStart).map((s) => s.actual_duration))
    if (prev >= 1800 && cur > 0) {
      const change = (cur - prev) / prev
      const pct = Math.round(Math.abs(change) * 100)
      cards.push({
        id: 'trend',
        title:
          pct < 5
            ? 'Your focus time is steady compared with last week.'
            : `Focus time is ${change > 0 ? 'up' : 'down'} ${pct}% compared with the previous 7 days.`,
        body: `${Math.round(cur / 360) / 10} h in the last 7 days vs ${Math.round(prev / 360) / 10} h before.`,
        tone: change >= 0 ? 'positive' : 'neutral',
      })
    }
  }

  // Best focus time
  if (enabled.has('bestTime')) {
    const b = bestFocusTime(allSessions, now)
    if (b) {
      cards.push({
        id: 'bestTime',
        title: `Your best focus window is ${bestTimeLabel(b)}.`,
        body: `${Math.round(b.rate * 100)}% of ${b.count} sessions started then were marked done (last 14 days).`,
        tone: 'positive',
      })
    }
  }

  // Stuck by project
  if (enabled.has('stuckProject') && mod.tasks) {
    const taskProject = new Map(tasks.map((t) => [t.id, t.project_id]))
    const stuck = new Map<string, { stuck: number; total: number }>()
    for (const s of sessions) {
      const pid = s.task_id ? taskProject.get(s.task_id) : null
      if (!pid) continue
      const v = stuck.get(pid) ?? { stuck: 0, total: 0 }
      v.total++
      if (s.result === 'stuck') v.stuck++
      stuck.set(pid, v)
    }
    const worst = [...stuck.entries()].filter(([, v]) => v.total >= 4 && v.stuck >= 2).sort((a, b) => b[1].stuck / b[1].total - a[1].stuck / a[1].total)[0]
    if (worst) {
      const p = projects.find((x) => x.id === worst[0])
      if (p) {
        cards.push({
          id: 'stuckProject',
          title: `You get stuck most often on ${p.name}.`,
          body: `${worst[1].stuck} of ${worst[1].total} sessions ended stuck. Breaking those tasks into smaller next steps may help.`,
          tone: 'attention',
        })
      }
    }
  }

  return cards
}

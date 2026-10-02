// The focus-session engine. Timing is based on wall-clock timestamps (never on counting ticks), so
// it stays accurate when the tab is backgrounded or the screen locks. State is mirrored to
// localStorage so an in-progress session is restored when the app is reopened.
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { db, uid } from '@/db'
import type { SessionResult } from '@/db/types'
import { ambient, chime } from '@/lib/audio'
import { notify, scheduleTimerAlert } from '@/lib/notify'
import { Deepwork, isAndroid, isNative } from '@/lib/native'
import type { AmbientSound } from '@/lib/settings'
import { dateKey } from '@/lib/date'
import { useSettings } from './settings'

export type FocusPhase = 'idle' | 'running' | 'paused' | 'finished' | 'closed' | 'ended' | 'break' | 'breakOver'

export interface FocusState {
  phase: FocusPhase
  sessionId: string | null
  taskId: string | null
  plannedSec: number
  mode: 'countdown' | 'countup'
  startedAt: number
  pausedAt: number | null
  pausedMs: number
  endedAt: number | null
  actualSec: number
  endReason: string | null
  result: SessionResult | null
  breakKind: 'short' | 'long' | null
  breakStartedAt: number | null
  breakSec: number
  sound: AmbientSound | null
}

const KEY = 'deepwork.focus'

const IDLE: FocusState = {
  phase: 'idle',
  sessionId: null,
  taskId: null,
  plannedSec: 25 * 60,
  mode: 'countdown',
  startedAt: 0,
  pausedAt: null,
  pausedMs: 0,
  endedAt: null,
  actualSec: 0,
  endReason: null,
  result: null,
  breakKind: null,
  breakStartedAt: null,
  breakSec: 0,
  sound: null,
}

function load(): FocusState {
  try {
    const raw = localStorage.getItem(KEY)
    if (raw) return { ...IDLE, ...JSON.parse(raw) }
  } catch {
    /* ignore */
  }
  return IDLE
}

export function elapsedSec(s: FocusState, now = Date.now()): number {
  if (s.phase === 'finished' || s.phase === 'closed' || s.phase === 'ended' || s.phase === 'break' || s.phase === 'breakOver') return s.actualSec
  if (!s.startedAt) return 0
  const pausedExtra = s.pausedAt ? now - s.pausedAt : 0
  return Math.max(0, (now - s.startedAt - s.pausedMs - pausedExtra) / 1000)
}

export function breakElapsedSec(s: FocusState, now = Date.now()) {
  if (!s.breakStartedAt) return 0
  return Math.max(0, (now - s.breakStartedAt) / 1000)
}

interface FocusCtx {
  state: FocusState
  start: (opts: { taskId: string | null; minutes: number; sound?: AmbientSound | null }) => Promise<void>
  pause: () => void
  resume: () => void
  /** End before the timer completes. finishedEarly → go to session close, otherwise log as interrupted. */
  endEarly: (opts: { reason: string; finishedEarly: boolean }) => Promise<void>
  discard: () => Promise<void>
  close: (opts: { result: SessionResult; note: string; markTaskDone: boolean; nextSteps: string[] }) => Promise<void>
  startBreak: (kind: 'short' | 'long') => void
  skipBreak: () => void
  startNext: () => Promise<void>
  reset: () => void
  logDistraction: (reason: string, note: string) => Promise<void>
  setSound: (s: AmbientSound | null) => void
  suggestedBreak: () => Promise<'short' | 'long'>
}

const Ctx = createContext<FocusCtx | null>(null)

export function FocusProvider({ children }: { children: ReactNode }) {
  const { settings } = useSettings()
  const [state, setState] = useState<FocusState>(load)
  const stateRef = useRef(state)
  const settingsRef = useRef(settings)
  settingsRef.current = settings

  const commit = useCallback((next: FocusState) => {
    stateRef.current = next
    setState(next)
    try {
      if (next.phase === 'idle') localStorage.removeItem(KEY)
      else localStorage.setItem(KEY, JSON.stringify(next))
    } catch {
      /* ignore */
    }
  }, [])
  const patch = useCallback((p: Partial<FocusState>) => commit({ ...stateRef.current, ...p }), [commit])

  const saveSession = useCallback(async (s: FocusState, result: SessionResult, note: string) => {
    if (!s.sessionId) return
    await db.sessions.put({
      id: s.sessionId,
      task_id: s.taskId,
      planned_duration: s.plannedSec,
      actual_duration: Math.round(s.actualSec),
      started_at: s.startedAt,
      ended_at: s.endedAt ?? Date.now(),
      result,
      note,
    })
  }, [])

  // ------------------------------------------------------------ completion detection
  const finish = useCallback(async () => {
    const s = stateRef.current
    if (s.phase !== 'running') return
    const endedAt = s.startedAt + s.pausedMs + s.plannedSec * 1000
    const next: FocusState = { ...s, phase: 'finished', endedAt, actualSec: s.plannedSec, pausedAt: null }
    ambient.stop(1.2)
    const st = settingsRef.current
    chime('complete')
    // On Android the alert was already scheduled natively for this exact moment.
    if (!isNative) void notify(st, 'sessionComplete', 'Session complete', 'Nice work. Take a moment to note what you got done.')
    if (!st.modules.sessionClose) {
      commit({ ...next, phase: 'closed', result: 'done' })
      await saveSession(next, 'done', '')
    } else {
      commit(next)
    }
  }, [commit, saveSession])

  const breakDone = useCallback(async () => {
    const s = stateRef.current
    if (s.phase !== 'break') return
    commit({ ...s, phase: 'breakOver' })
    chime('break')
    const st = settingsRef.current
    if (!isNative) void notify(st, 'breakOver', 'Break is over', 'Ready for the next session?')
  }, [commit])

  useEffect(() => {
    const check = () => {
      const s = stateRef.current
      if (s.phase === 'running' && elapsedSec(s) >= s.plannedSec) void finish()
      if (s.phase === 'break' && breakElapsedSec(s) >= s.breakSec) void breakDone()
    }
    check()
    const iv = setInterval(check, 500)
    let to: ReturnType<typeof setTimeout> | undefined
    // An exact timeout as well, so the alert fires on time even if intervals are throttled.
    if (state.phase === 'running') to = setTimeout(check, Math.max(0, (state.plannedSec - elapsedSec(state)) * 1000 + 50))
    if (state.phase === 'break') to = setTimeout(check, Math.max(0, (state.breakSec - breakElapsedSec(state)) * 1000 + 50))
    const onVis = () => document.visibilityState === 'visible' && check()
    document.addEventListener('visibilitychange', onVis)
    return () => {
      clearInterval(iv)
      if (to) clearTimeout(to)
      document.removeEventListener('visibilitychange', onVis)
    }
  }, [state, finish, breakDone])

  // ------------------------------------------------------------ wake lock
  useEffect(() => {
    const want = settings.focus.wakeLock && (state.phase === 'running' || state.phase === 'paused' || state.phase === 'break')
    if (isNative) {
      void Deepwork.setKeepAwake({ on: want }).catch(() => {})
      return
    }
    if (!want || !('wakeLock' in navigator)) return
    let lock: WakeLockSentinel | null = null
    let cancelled = false
    const acquire = async () => {
      try {
        if (document.visibilityState !== 'visible') return
        lock = await navigator.wakeLock.request('screen')
        if (cancelled) void lock.release()
      } catch {
        /* not allowed (e.g. battery saver) — ignore */
      }
    }
    void acquire()
    const onVis = () => document.visibilityState === 'visible' && void acquire()
    document.addEventListener('visibilitychange', onVis)
    return () => {
      cancelled = true
      document.removeEventListener('visibilitychange', onVis)
      void lock?.release().catch(() => {})
    }
  }, [settings.focus.wakeLock, state.phase])

  // ------------------------------------------------------------ Android: timer alerts that fire even when the app is closed
  useEffect(() => {
    if (!isNative) return
    if (state.phase === 'running') void scheduleTimerAlert(settings, state.startedAt + state.pausedMs + state.plannedSec * 1000, 'sessionComplete')
    else if (state.phase === 'break' && state.breakStartedAt) void scheduleTimerAlert(settings, state.breakStartedAt + state.breakSec * 1000, 'breakOver')
    else void scheduleTimerAlert(settings, null, 'sessionComplete')
  }, [settings, state.phase, state.startedAt, state.pausedMs, state.plannedSec, state.breakStartedAt, state.breakSec])

  // ------------------------------------------------------------ Android: block distracting apps while focusing
  useEffect(() => {
    if (!isAndroid) return
    const b = settings.blocking
    const want = settings.modules.appBlocking && state.phase === 'running' && (b.mode === 'allow' || b.packages.length > 0)
    if (!want) {
      void Deepwork.stopBlocking().catch(() => {})
      return
    }
    const until = state.startedAt + state.pausedMs + state.plannedSec * 1000
    void (async () => {
      const task = state.taskId ? await db.tasks.get(state.taskId) : undefined
      await Deepwork.startBlocking({ until, mode: b.mode, packages: b.packages, taskTitle: task?.title ?? '' }).catch(() => {})
    })()
  }, [settings.modules.appBlocking, settings.blocking, state.phase, state.startedAt, state.pausedMs, state.plannedSec, state.taskId])

  // Attempts to open a blocked app are logged as distractions when you come back.
  useEffect(() => {
    if (!isAndroid) return
    const collect = async () => {
      if (document.visibilityState !== 'visible') return
      const { attempts } = await Deepwork.takeBlockedAttempts().catch(() => ({ attempts: [] }))
      const st = settingsRef.current
      const s = stateRef.current
      if (!attempts.length || !s.sessionId || !st.blocking.logAttempts || !st.modules.distractions) return
      await db.distractions.bulkPut(
        attempts
          .filter((a) => a.timestamp >= s.startedAt)
          .map((a) => ({ id: uid(), session_id: s.sessionId!, timestamp: a.timestamp, reason: 'Blocked app', note: `Tried to open ${a.label}` })),
      )
    }
    void collect()
    document.addEventListener('visibilitychange', collect)
    return () => document.removeEventListener('visibilitychange', collect)
  }, [])

  // ------------------------------------------------------------ ambient sound follows the phase
  useEffect(() => {
    const allowed = settings.modules.ambient && state.sound && settings.ambient.available.includes(state.sound)
    if (state.phase === 'running' && allowed) {
      // Browsers require a gesture before audio; play() is also called directly from start/resume.
      try {
        ambient.play(state.sound!, settings.ambient.volume)
      } catch {
        /* ignore */
      }
    } else if (ambient.playing) {
      ambient.stop()
    }
  }, [state.phase, state.sound, settings.modules.ambient, settings.ambient.available, settings.ambient.volume])

  useEffect(() => {
    ambient.setVolume(settings.ambient.volume)
  }, [settings.ambient.volume])

  // ------------------------------------------------------------ actions
  const start = useCallback<FocusCtx['start']>(
    async ({ taskId, minutes, sound }) => {
      const st = settingsRef.current
      const snd = sound !== undefined ? sound : stateRef.current.sound
      commit({
        ...IDLE,
        phase: 'running',
        sessionId: uid(),
        taskId,
        plannedSec: Math.round(minutes * 60),
        mode: st.focus.mode,
        startedAt: Date.now(),
        sound: st.modules.ambient ? snd : null,
      })
      if (st.modules.ambient && snd) ambient.play(snd, st.ambient.volume)
      if (taskId) {
        const t = await db.tasks.get(taskId)
        if (t && t.status === 'todo') await db.tasks.update(taskId, { status: 'in_progress' })
      }
    },
    [commit],
  )

  const pause = useCallback(() => {
    const s = stateRef.current
    if (s.phase !== 'running') return
    patch({ phase: 'paused', pausedAt: Date.now() })
  }, [patch])

  const resume = useCallback(() => {
    const s = stateRef.current
    if (s.phase !== 'paused' || !s.pausedAt) return
    patch({ phase: 'running', pausedMs: s.pausedMs + (Date.now() - s.pausedAt), pausedAt: null })
    const st = settingsRef.current
    if (st.modules.ambient && s.sound) ambient.play(s.sound, st.ambient.volume)
  }, [patch])

  const endEarly = useCallback<FocusCtx['endEarly']>(
    async ({ reason, finishedEarly }) => {
      const s = stateRef.current
      if (s.phase !== 'running' && s.phase !== 'paused') return
      const actual = elapsedSec(s)
      const ended: FocusState = { ...s, endedAt: Date.now(), actualSec: actual, pausedAt: null, endReason: reason }
      ambient.stop()
      if (finishedEarly) {
        if (settingsRef.current.modules.sessionClose) commit({ ...ended, phase: 'finished' })
        else {
          commit({ ...ended, phase: 'closed', result: 'done' })
          await saveSession(ended, 'done', '')
        }
      } else {
        commit({ ...ended, phase: 'ended', result: 'interrupted' })
        await saveSession(ended, 'interrupted', reason)
      }
    },
    [commit, saveSession],
  )

  const discard = useCallback(async () => {
    const s = stateRef.current
    ambient.stop()
    if (s.sessionId) await db.distractions.where('session_id').equals(s.sessionId).delete()
    commit({ ...IDLE, sound: s.sound })
  }, [commit])

  const close = useCallback<FocusCtx['close']>(
    async ({ result, note, markTaskDone, nextSteps }) => {
      const s = stateRef.current
      if (s.phase !== 'finished') return
      await saveSession(s, result, note)
      if (s.taskId && markTaskDone) await db.tasks.update(s.taskId, { status: 'done', completed_at: Date.now() })
      const steps = nextSteps.map((x) => x.trim()).filter(Boolean)
      if (steps.length) {
        const parent = s.taskId ? await db.tasks.get(s.taskId) : undefined
        const maxOrder = (await db.tasks.orderBy('order').last())?.order ?? 0
        const today = dateKey()
        const prioCount = await db.tasks.filter((t) => t.is_priority && t.priority_date === today).count()
        await db.tasks.bulkPut(
          steps.map((title, i) => ({
            id: uid(),
            title,
            project_id: parent?.project_id ?? null,
            estimate_sessions: 1,
            due_date: null,
            status: 'todo' as const,
            flagged: false,
            is_priority: settingsRef.current.modules.priorities && i === 0,
            priority_date: settingsRef.current.modules.priorities && i === 0 ? today : null,
            priority_order: prioCount + i,
            order: maxOrder + 1 + i,
            created_at: Date.now(),
            completed_at: null,
          })),
        )
      }
      commit({ ...s, phase: 'closed', result })
    },
    [commit, saveSession],
  )

  const suggestedBreak = useCallback(async (): Promise<'short' | 'long'> => {
    const st = settingsRef.current
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    const n = await db.sessions.where('started_at').aboveOrEqual(today.getTime()).filter((x) => x.result !== 'interrupted').count()
    return n > 0 && n % Math.max(1, st.breaks.longAfter) === 0 ? 'long' : 'short'
  }, [])

  const startBreak = useCallback(
    (kind: 'short' | 'long') => {
      const st = settingsRef.current
      patch({ phase: 'break', breakKind: kind, breakStartedAt: Date.now(), breakSec: (kind === 'long' ? st.breaks.long : st.breaks.short) * 60 })
    },
    [patch],
  )

  const skipBreak = useCallback(() => patch({ phase: 'breakOver' }), [patch])

  const startNext = useCallback(async () => {
    const s = stateRef.current
    let taskId = s.taskId
    if (taskId) {
      const t = await db.tasks.get(taskId)
      if (!t || t.status === 'done') taskId = null
    }
    if (!taskId && settingsRef.current.focus.requireTask) {
      commit({ ...IDLE, sound: s.sound })
      return
    }
    await start({ taskId, minutes: s.plannedSec / 60, sound: s.sound })
  }, [commit, start])

  // Auto-start next session after a break when configured.
  useEffect(() => {
    if (state.phase === 'breakOver' && settings.breaks.autoStartNext) {
      const t = setTimeout(() => void startNext(), 1500)
      return () => clearTimeout(t)
    }
  }, [state.phase, settings.breaks.autoStartNext, startNext])

  const reset = useCallback(() => {
    ambient.stop()
    commit({ ...IDLE, sound: stateRef.current.sound })
  }, [commit])

  const logDistraction = useCallback(async (reason: string, note: string) => {
    const s = stateRef.current
    if (!s.sessionId) return
    await db.distractions.put({ id: uid(), session_id: s.sessionId, timestamp: Date.now(), reason, note })
  }, [])

  const setSound = useCallback(
    (snd: AmbientSound | null) => {
      patch({ sound: snd })
      const st = settingsRef.current
      if (stateRef.current.phase === 'running') {
        if (snd && st.modules.ambient) ambient.play(snd, st.ambient.volume)
        else ambient.stop()
      }
    },
    [patch],
  )

  const value = useMemo<FocusCtx>(
    () => ({ state, start, pause, resume, endEarly, discard, close, startBreak, skipBreak, startNext, reset, logDistraction, setSound, suggestedBreak }),
    [state, start, pause, resume, endEarly, discard, close, startBreak, skipBreak, startNext, reset, logDistraction, setSound, suggestedBreak],
  )
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>
}

export function useFocus() {
  const ctx = useContext(Ctx)
  if (!ctx) throw new Error('useFocus must be used inside FocusProvider')
  return ctx
}

/** Re-render on every animation frame while `active` (for the smooth progress ring). */
export function useNow(active: boolean, fps = 30) {
  const [now, setNow] = useState(Date.now())
  useEffect(() => {
    if (!active) {
      setNow(Date.now())
      return
    }
    let raf = 0
    let last = 0
    const loop = (t: number) => {
      if (t - last >= 1000 / fps) {
        last = t
        setNow(Date.now())
      }
      raf = requestAnimationFrame(loop)
    }
    raf = requestAnimationFrame(loop)
    return () => cancelAnimationFrame(raf)
  }, [active, fps])
  return now
}

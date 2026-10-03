import {
  DndContext,
  DragOverlay,
  MouseSensor,
  TouchSensor,
  KeyboardSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core'
import { arrayMove, sortableKeyboardCoordinates } from '@dnd-kit/sortable'
import { format } from 'date-fns'
import { motion } from 'framer-motion'
import { ArrowRight, Cloud, CloudOff, Flame, NotebookPen, Play, RefreshCw, TriangleAlert } from 'lucide-react'
import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { Link, useNavigate } from 'react-router'
import { useLiveQuery } from 'dexie-react-hooks'
import { startOfDay } from 'date-fns'
import { db } from '@/db'
import { useSettings } from '@/state/settings'
import { useFocus } from '@/state/focus'
import { useDistractions, useProjects, useSessions, useTasks, useTimeBlocks } from '@/hooks/data'
import { Page } from '@/components/shared/Page'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { LoadingBlock } from '@/components/ui/empty'
import { ProgressBar } from '@/components/ui/progress'
import { toast } from '@/components/ui/toast'
import { buildDayIndex, computeStreak, EMPTY_DAY, goalProgress, streakRuleLabel } from '@/lib/stats'
import { formatDuration, greeting, isWeekend, relativeDays, todayKey } from '@/lib/date'
import { isEveningReviewDue, isWeeklyReviewDue } from '@/lib/reviews'
import { isBackupDue, runBackup } from '@/lib/backup'
import type { HomeSectionId } from '@/lib/settings'
import { cn, pluralize } from '@/lib/utils'
import { Priorities } from './Priorities'
import { Timeline, createBlock, moveBlock } from './Timeline'
import { useOnline } from '@/hooks/useMediaQuery'

export function TodayPage() {
  const { settings } = useSettings()
  const navigate = useNavigate()
  const { state: focus } = useFocus()
  const today = useDayKey()
  const tasks = useTasks()
  const projects = useProjects()
  const sessions = useSessions(0)
  const distractions = useDistractions(useMemo(() => startOfDay(new Date()).getTime(), [today]))
  const blocks = useTimeBlocks(today)
  const now = useMemo(() => new Date(), [today]) // eslint-disable-line react-hooks/exhaustive-deps

  const loading = !tasks || !projects || !sessions || !blocks || !distractions

  const index = useMemo(() => (sessions && tasks && distractions ? buildDayIndex(sessions, tasks, distractions) : new Map()), [sessions, tasks, distractions])
  const day = index.get(today) ?? EMPTY_DAY
  const streak = useMemo(() => computeStreak(settings, index), [settings, index])
  const priorities = useMemo(
    () => (tasks ?? []).filter((t) => t.is_priority && t.priority_date === today).sort((a, b) => a.priority_order - b.priority_order),
    [tasks, today],
  )
  const tray = useMemo(() => {
    const ids = new Set(priorities.map((t) => t.id))
    const list = [...priorities]
    for (const t of tasks ?? []) if (t.status !== 'done' && !ids.has(t.id) && (t.due_date === today || t.flagged)) list.push(t)
    return list.slice(0, 12)
  }, [priorities, tasks, today])

  const eveningDue = useLiveQuery(() => isEveningReviewDue(settings), [settings, today])
  const weeklyDue = useLiveQuery(() => isWeeklyReviewDue(settings), [settings, today])

  // ------------------------------------------------------------ drag & drop
  const sensors = useSensors(
    useSensor(MouseSensor, { activationConstraint: { distance: 6 } }),
    useSensor(TouchSensor, { activationConstraint: { delay: 180, tolerance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  )
  const [dragTitle, setDragTitle] = useState<string | null>(null)
  const onDragStart = (e: DragStartEvent) => setDragTitle((e.active.data.current?.title as string) ?? null)
  const onDragEnd = async (e: DragEndEvent) => {
    setDragTitle(null)
    const a = String(e.active.id)
    const o = e.over ? String(e.over.id) : null
    if (!o) return
    if (a.startsWith('prio:') && o.startsWith('prio:') && a !== o) {
      const ids = priorities.map((t) => `prio:${t.id}`)
      const next = arrayMove(priorities, ids.indexOf(a), ids.indexOf(o))
      await db.transaction('rw', db.tasks, async () => {
        for (const [i, t] of next.entries()) await db.tasks.update(t.id, { priority_order: i })
      })
      return
    }
    if (o.startsWith('slot:')) {
      if (!settings.modules.timeBlocks) return
      const minute = Number(o.slice(5))
      if (a.startsWith('block:')) await moveBlock(a.slice(6), minute)
      else {
        const taskId = a.replace(/^(prio|tray):/, '')
        await createBlock(minute, settings.timeBlocks.blockLength, taskId)
        toast('Scheduled', { kind: 'success', duration: 1800 })
      }
    }
  }

  const showTimeline = settings.modules.timeBlocks && (settings.timeBlocks.showWeekends || !isWeekend(now))

  const sections: Record<HomeSectionId, ReactNode> = {
    startFocus: (
      <StartFocusButton
        active={focus.phase !== 'idle'}
        onClick={() => navigate(priorities.find((t) => t.status !== 'done') && focus.phase === 'idle' ? `/focus?task=${priorities.find((t) => t.status !== 'done')!.id}` : '/focus')}
        next={focus.phase === 'idle' ? priorities.find((t) => t.status !== 'done')?.title : undefined}
      />
    ),
    summary: settings.modules.summary ? <SummaryStrip day={day} /> : null,
    streak: settings.modules.streaks ? <StreakCard current={streak.current} best={streak.best} todayDone={streak.todayDone} atRisk={streak.atRisk} rule={streakRuleLabel(settings)} /> : null,
    eveningReview: settings.modules.eveningReview && eveningDue ? (
      <ReviewCard to="/review/evening" title="Evening review" body="Two minutes: planned vs. done, one reflection, and tomorrow's priorities." />
    ) : null,
    weeklyReview: settings.modules.weeklyReview && weeklyDue ? (
      <ReviewCard to="/review/weekly" title="Weekly review" body="Ten minutes to look at your week and choose what's next." />
    ) : null,
    priorities: settings.modules.priorities ? <Priorities priorities={priorities} projects={projects ?? []} sessions={sessions ?? []} /> : null,
    timeline: showTimeline ? <Timeline blocks={blocks ?? []} tasks={tasks ?? []} projects={projects ?? []} tray={tray} /> : null,
    backup: settings.modules.backup ? <BackupIndicator /> : null,
  }

  return (
    <Page>
      <header className="mb-7 flex items-start justify-between gap-4">
        <div>
          <p className="text-sm font-medium text-muted">{format(now, 'EEEE, MMMM d')}</p>
          <h1 className="mt-1 text-[30px] font-semibold leading-tight tracking-tight sm:text-[36px]">{greeting()}</h1>
        </div>
        {(settings.modules.eveningReview || settings.modules.weeklyReview) && (
          <Button variant="ghost" size="icon" className="md:hidden" onClick={() => navigate('/reviews')} aria-label="Reviews">
            <NotebookPen />
          </Button>
        )}
      </header>

      {loading ? (
        <div className="space-y-4">
          <LoadingBlock className="h-14" />
          <LoadingBlock className="h-24" />
          <LoadingBlock className="h-48" />
        </div>
      ) : (
        <DndContext sensors={sensors} onDragStart={onDragStart} onDragEnd={(e) => void onDragEnd(e)} onDragCancel={() => setDragTitle(null)}>
          <div className="flex flex-col gap-d">
            {settings.appearance.homeLayout
              .filter((s) => s.visible && sections[s.id])
              .map((s, i) => (
                <motion.div key={s.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.03 * i, duration: 0.3 }}>
                  {sections[s.id]}
                </motion.div>
              ))}
          </div>
          <DragOverlay dropAnimation={null}>
            {dragTitle ? <div className="glass rounded-full border border-accent/50 px-3.5 py-2 text-sm font-medium shadow-xl">{dragTitle}</div> : null}
          </DragOverlay>
        </DndContext>
      )}
    </Page>
  )
}

/** Today's date key; changes at local midnight so the daily summary resets. */
function useDayKey() {
  const [key, setKey] = useState(todayKey())
  useEffect(() => {
    const iv = setInterval(() => {
      const k = todayKey()
      setKey((prev) => (prev !== k ? k : prev))
    }, 20_000)
    return () => clearInterval(iv)
  }, [])
  return key
}

function StartFocusButton({ onClick, active, next }: { onClick: () => void; active: boolean; next?: string }) {
  return (
    <motion.button
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className="group relative flex w-full items-center justify-between overflow-hidden rounded-[18px] bg-accent px-5 py-4 text-left text-accent-fg shadow-[0_12px_40px_-12px_var(--accent)] transition-[filter] hover:brightness-110"
    >
      <div className="min-w-0">
        <div className="text-lg font-semibold tracking-tight">{active ? 'Return to session' : 'Start focus'}</div>
        <div className="truncate text-sm opacity-80">{active ? 'Your session is still going' : next ? `Next: ${next}` : 'Pick a task and a duration'}</div>
      </div>
      <span className="flex size-11 shrink-0 items-center justify-center rounded-full bg-white/20 transition-transform group-hover:scale-105">
        <Play className="size-5 fill-current" />
      </span>
    </motion.button>
  )
}

function SummaryStrip({ day }: { day: typeof EMPTY_DAY }) {
  const { settings } = useSettings()
  const goal = goalProgress(settings, day)
  const items = [
    { label: 'Focus', value: formatDuration(day.focusSec) },
    { label: 'Tasks done', value: String(day.tasksDone), hide: !settings.modules.tasks && !settings.modules.priorities },
    { label: 'Sessions', value: String(day.sessions) },
  ].filter((i) => !i.hide)
  return (
    <Card className="!py-4">
      <div className="flex items-stretch gap-3 sm:gap-4">
        {items.map((i) => (
          <div key={i.label} className="min-w-0 flex-1">
            <div className="tabular whitespace-nowrap text-[19px] font-semibold tracking-tight sm:text-[22px]">{i.value}</div>
            <div className="text-xs text-muted">{i.label}</div>
          </div>
        ))}
        <div className="min-w-0 flex-[1.4]">
          <div className="tabular whitespace-nowrap text-[19px] font-semibold tracking-tight sm:text-[22px]">
            {goal.value}
            <span className="text-xs font-normal text-muted sm:text-sm">
              /{goal.target}
              <span className="hidden sm:inline"> {goal.unit}</span>
            </span>
          </div>
          <ProgressBar className="mt-1.5" value={goal.ratio} color={goal.ratio >= 1 ? 'var(--success)' : 'var(--accent)'} />
          <div className="mt-1 truncate text-xs text-muted">{goal.ratio >= 1 ? 'Goal reached' : `Goal (${goal.unit})`}</div>
        </div>
      </div>
    </Card>
  )
}

function StreakCard({ current, best, todayDone, atRisk, rule }: { current: number; best: number; todayDone: boolean; atRisk: boolean; rule: string }) {
  return (
    <Card className="flex items-center gap-4 !py-4">
      <div className={cn('flex size-11 shrink-0 items-center justify-center rounded-2xl', current > 0 ? 'bg-warning/12 text-warning' : 'bg-card-2 text-muted')}>
        <Flame className="size-5" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="text-[15px] font-semibold">
          <span className="tabular">{pluralize(current, 'day')}</span> streak
        </div>
        <div className="truncate text-xs text-muted">
          {atRisk ? "Missed yesterday — today keeps it alive." : todayDone ? 'Today counts. Nice.' : rule}
        </div>
      </div>
      <div className="text-right">
        <div className="tabular text-sm font-semibold">{best}</div>
        <div className="text-xs text-muted">best</div>
      </div>
    </Card>
  )
}

function ReviewCard({ to, title, body }: { to: string; title: string; body: string }) {
  return (
    <Link to={to} className="card pad group flex items-center gap-4 border-accent/30 transition-colors hover:border-accent/60">
      <div className="flex size-11 shrink-0 items-center justify-center rounded-2xl bg-accent-soft text-accent">
        <NotebookPen className="size-5" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="text-[15px] font-semibold">{title}</div>
        <div className="text-[13px] text-muted">{body}</div>
      </div>
      <ArrowRight className="size-4 shrink-0 text-muted transition-transform group-hover:translate-x-0.5" />
    </Link>
  )
}

function BackupIndicator() {
  const { settings } = useSettings()
  const online = useOnline()
  const [busy, setBusy] = useState(false)
  const b = settings.backup
  if (!b.connected) {
    return (
      <Link to="/settings/backup" className="flex items-center gap-2 px-1 text-[13px] text-muted hover:text-fg">
        <CloudOff className="size-3.5" /> Google Drive not connected
      </Link>
    )
  }
  const due = isBackupDue(settings)
  const label = b.lastBackupAt ? `Last backup: ${relativeDays(b.lastBackupAt)}` : 'No backup yet'
  const backupNow = async () => {
    setBusy(true)
    const r = await runBackup({ interactive: true })
    setBusy(false)
    if (r.outcome === 'ok') toast('Backed up to Google Drive', { kind: 'success' })
    else if (r.message) toast(r.message, { kind: 'error' })
  }
  return (
    <button
      onClick={() => void backupNow()}
      disabled={busy || !online}
      className="flex items-center gap-2 px-1 text-[13px] text-muted transition-colors hover:text-fg disabled:opacity-60"
      title="Back up now"
    >
      {busy ? <RefreshCw className="size-3.5 animate-spin" /> : b.needsReconnect || b.lastError ? <TriangleAlert className="size-3.5 text-warning" /> : <Cloud className="size-3.5" />}
      <span>
        {busy ? 'Backing up…' : b.needsReconnect ? 'Backup needs you to reconnect Google — tap to back up' : label}
        {!busy && !b.needsReconnect && due && online ? ' · due now, tap to back up' : ''}
        {!online && ' · offline'}
      </span>
    </button>
  )
}

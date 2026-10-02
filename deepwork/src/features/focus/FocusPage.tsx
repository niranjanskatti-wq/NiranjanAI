import { AnimatePresence, motion } from 'framer-motion'
import {
  ArrowLeft,
  CircleCheck,
  CloudRain,
  Coffee,
  Pause,
  Play,
  Plus,
  Square,
  Volume2,
  VolumeX,
  Waves,
  Wind,
  Zap,
  X,
  SkipForward,
} from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/db'
import { useSettings } from '@/state/settings'
import { breakElapsedSec, elapsedSec, useFocus, useNow } from '@/state/focus'
import { createTask, useProjects, useReasons, useTasks } from '@/hooks/data'
import { Button } from '@/components/ui/button'
import { Chip, ProjectDot } from '@/components/ui/chip'
import { Dialog } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Slider } from '@/components/ui/slider'
import { toast } from '@/components/ui/toast'
import { formatDuration, formatTimer, todayKey } from '@/lib/date'
import { AMBIENT_SOUNDS, type AmbientSound } from '@/lib/settings'
import { unlockAudio } from '@/lib/audio'
import { cn, pluralize } from '@/lib/utils'
import { ProgressRing, type RingStatus } from './ProgressRing'
import { SessionClose } from './SessionClose'
import type { Task } from '@/db/types'

const SOUND_ICONS: Record<AmbientSound, typeof CloudRain> = { rain: CloudRain, cafe: Coffee, white: Wind, brown: Waves }

export function FocusPage() {
  const { state } = useFocus()
  return (
    <div className="relative min-h-dvh">
      <AnimatePresence mode="wait">
        {state.phase === 'idle' ? (
          <motion.div key="setup" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <FocusSetup />
          </motion.div>
        ) : (
          <motion.div key="session" initial={{ opacity: 0, scale: 0.985 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3 }}>
            <FocusSession />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

// ======================================================================== setup

function useRequireTask() {
  const { settings } = useSettings()
  return settings.focus.requireTask && (settings.modules.tasks || settings.modules.priorities)
}

function FocusSetup() {
  const { settings } = useSettings()
  const { start, state } = useFocus()
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const tasks = useTasks()
  const projects = useProjects()
  const requireTask = useRequireTask()
  const [taskId, setTaskId] = useState<string | null>(params.get('task'))
  const [minutes, setMinutes] = useState<number>(Number(params.get('minutes')) || settings.focus.defaultDuration)
  const [custom, setCustom] = useState('')
  const [newTask, setNewTask] = useState('')
  const [sound, setSound] = useState<AmbientSound | null>(() =>
    state.sound ?? (settings.ambient.defaultOn && settings.ambient.available.includes(settings.ambient.defaultSound) ? settings.ambient.defaultSound : null),
  )

  const today = todayKey()
  const open = useMemo(() => {
    const list = (tasks ?? []).filter((t) => t.status !== 'done')
    const prio = (t: Task) => (t.is_priority && t.priority_date === today ? 0 : t.due_date === today ? 1 : t.flagged ? 2 : 3)
    return list.sort((a, b) => prio(a) - prio(b) || a.priority_order - b.priority_order || a.order - b.order)
  }, [tasks, today])
  const projectMap = new Map((projects ?? []).map((p) => [p.id, p]))
  const sessionsForTask = useLiveQuery(
    async () => (taskId ? (await db.sessions.where('task_id').equals(taskId).filter((s) => s.result !== 'interrupted').count()) : 0),
    [taskId],
  )
  const selected = open.find((t) => t.id === taskId)

  const canStart = (!requireTask || !!taskId) && minutes > 0
  const begin = async () => {
    unlockAudio()
    await start({ taskId: taskId ?? null, minutes, sound: settings.modules.ambient ? sound : null })
  }

  const addTask = async () => {
    const title = newTask.trim()
    if (!title) return
    const t = await createTask({ title })
    setTaskId(t.id)
    setNewTask('')
  }

  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-2xl flex-col px-4 pb-32 pt-6 safe-top sm:px-6 md:pb-12 md:pt-10">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-[28px] font-semibold tracking-tight sm:text-[32px]">Focus</h1>
          <p className="mt-1 text-sm text-muted">Pick one thing. Give it your full attention.</p>
        </div>
      </div>

      <section className="card pad mb-4">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-[15px] font-semibold">Task {requireTask ? '' : <span className="font-normal text-muted">(optional)</span>}</h2>
          {selected && settings.modules.tasks && selected.estimate_sessions ? (
            <span className="tabular text-xs text-muted">
              {sessionsForTask ?? 0}/{selected.estimate_sessions} sessions
            </span>
          ) : null}
        </div>
        <div className="max-h-[260px] space-y-1 overflow-y-auto pr-1">
          {!requireTask && (
            <TaskOption active={taskId === null} onClick={() => setTaskId(null)} title="Untitled session" subtitle="No task attached" />
          )}
          {open.map((t) => {
            const p = t.project_id ? projectMap.get(t.project_id) : undefined
            const isPrio = t.is_priority && t.priority_date === today
            return (
              <TaskOption
                key={t.id}
                active={taskId === t.id}
                onClick={() => setTaskId(t.id)}
                title={t.title}
                subtitle={[isPrio ? settings.priorities.label.replace(/s$/, '') : null, p?.name].filter(Boolean).join(' · ') || undefined}
                color={p?.color}
              />
            )
          })}
          {open.length === 0 && <p className="px-1 py-3 text-sm text-muted">No open tasks yet. Add one below.</p>}
        </div>
        <form
          className="mt-3 flex gap-2"
          onSubmit={(e) => {
            e.preventDefault()
            void addTask()
          }}
        >
          <Input value={newTask} onChange={(e) => setNewTask(e.target.value)} placeholder="New task…" aria-label="New task title" />
          <Button type="submit" variant="secondary" size="icon" disabled={!newTask.trim()} aria-label="Add task">
            <Plus />
          </Button>
        </form>
      </section>

      <section className="card pad mb-4">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-[15px] font-semibold">Duration</h2>
          <span className="text-xs text-muted">{settings.focus.mode === 'countdown' ? 'Countdown' : 'Count-up'}</span>
        </div>
        <div className="flex flex-wrap gap-2">
          {settings.focus.presets.map((m) => (
            <Chip
              key={m}
              active={minutes === m && !custom}
              onClick={() => {
                setMinutes(m)
                setCustom('')
              }}
              className="tabular h-10 px-4 text-sm"
            >
              {m} min
            </Chip>
          ))}
          {settings.focus.allowCustom && (
            <div className="flex items-center gap-2">
              <Input
                type="number"
                inputMode="numeric"
                min={1}
                max={300}
                value={custom}
                onChange={(e) => {
                  setCustom(e.target.value)
                  const n = Number(e.target.value)
                  if (n > 0 && n <= 300) setMinutes(n)
                }}
                placeholder="Custom"
                className={cn('tabular h-10 w-[104px] rounded-full', custom && 'border-accent/60')}
                aria-label="Custom minutes"
              />
            </div>
          )}
        </div>
      </section>

      {settings.modules.ambient && settings.ambient.available.length > 0 && (
        <section className="card pad mb-6">
          <h2 className="mb-3 text-[15px] font-semibold">Ambient sound</h2>
          <SoundPicker sound={sound} onChange={setSound} />
        </section>
      )}

      <div className="fixed inset-x-0 bottom-[calc(64px+env(safe-area-inset-bottom))] z-30 px-4 pb-3 pt-6 md:static md:p-0" style={{ background: 'linear-gradient(to top, var(--bg) 60%, transparent)' }}>
        <Button variant="primary" size="xl" className="w-full md:w-auto md:min-w-[240px]" disabled={!canStart} onClick={() => void begin()}>
          <Play className="fill-current" /> Start {minutes}-minute session
        </Button>
        {!canStart && requireTask && <p className="mt-2 text-center text-xs text-muted md:text-left">Choose a task to start. (You can allow untitled sessions in Settings.)</p>}
        {state.phase === 'idle' && params.get('task') && (
          <button className="mt-2 hidden text-sm text-muted hover:text-fg md:block" onClick={() => navigate(-1)}>
            Cancel
          </button>
        )}
      </div>
    </div>
  )
}

function TaskOption({ active, onClick, title, subtitle, color }: { active: boolean; onClick: () => void; title: string; subtitle?: string; color?: string }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex w-full items-center gap-3 rounded-[12px] border px-3 py-2.5 text-left transition-all active:scale-[0.99]',
        active ? 'border-accent/60 bg-accent-soft' : 'border-transparent hover:bg-card-2',
      )}
    >
      <span className={cn('flex size-4 shrink-0 items-center justify-center rounded-full border-2', active ? 'border-accent' : 'border-border')}>
        {active && <span className="size-2 rounded-full bg-accent" />}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-sm font-medium">{title}</span>
        {subtitle && (
          <span className="mt-0.5 flex items-center gap-1.5 text-xs text-muted">
            {color && <ProjectDot color={color} />}
            {subtitle}
          </span>
        )}
      </span>
    </button>
  )
}

function SoundPicker({ sound, onChange, compact }: { sound: AmbientSound | null; onChange: (s: AmbientSound | null) => void; compact?: boolean }) {
  const { settings, update } = useSettings()
  const [vol, setVol] = useState(settings.ambient.volume)
  useEffect(() => setVol(settings.ambient.volume), [settings.ambient.volume])
  return (
    <div>
      <div className="flex flex-wrap gap-2">
        <Chip active={!sound} onClick={() => onChange(null)}>
          <VolumeX className="size-3.5" /> Off
        </Chip>
        {AMBIENT_SOUNDS.filter((s) => settings.ambient.available.includes(s.id)).map((s) => {
          const Icon = SOUND_ICONS[s.id]
          return (
            <Chip
              key={s.id}
              active={sound === s.id}
              onClick={() => {
                unlockAudio()
                onChange(s.id)
              }}
            >
              <Icon className="size-3.5" /> {s.label}
            </Chip>
          )
        })}
      </div>
      <div className={cn('flex items-center gap-3', compact ? 'mt-4' : 'mt-5')}>
        <Volume2 className="size-4 shrink-0 text-muted" />
        <Slider
          aria-label="Volume"
          value={vol}
          onValueChange={setVol}
          onValueCommit={(v) => void update((s) => void (s.ambient.volume = v))}
        />
        <span className="tabular w-9 text-right text-xs text-muted">{Math.round(vol * 100)}%</span>
      </div>
    </div>
  )
}

// ======================================================================== session

function FocusSession() {
  const { state, pause, resume, reset, startBreak, skipBreak, startNext, setSound, suggestedBreak } = useFocus()
  const { settings } = useSettings()
  const navigate = useNavigate()
  const task = useLiveQuery(() => (state.taskId ? db.tasks.get(state.taskId) : undefined), [state.taskId])
  const ticking = state.phase === 'running' || state.phase === 'break'
  const now = useNow(ticking, 30)
  const [distractOpen, setDistractOpen] = useState(false)
  const [endOpen, setEndOpen] = useState(false)
  const [soundOpen, setSoundOpen] = useState(false)
  const [suggest, setSuggest] = useState<'short' | 'long'>('short')
  const distractionCount = useLiveQuery(() => (state.sessionId ? db.distractions.where('session_id').equals(state.sessionId).count() : 0), [state.sessionId]) ?? 0

  useEffect(() => {
    if (state.phase === 'closed') void suggestedBreak().then(setSuggest)
  }, [state.phase, suggestedBreak])

  const el = elapsedSec(state, now)
  const remaining = Math.max(0, state.plannedSec - el)
  let progress = state.plannedSec ? el / state.plannedSec : 0
  let status: RingStatus = 'active'
  let display = formatTimer(state.mode === 'countdown' ? remaining : el, settings.focus.hideSeconds)
  let caption: string = state.mode === 'countdown' ? 'remaining' : `of ${formatDuration(state.plannedSec)}`

  if (state.phase === 'paused') {
    status = 'paused'
    caption = 'paused'
  } else if (state.phase === 'finished' || state.phase === 'closed') {
    status = 'complete'
    progress = state.actualSec >= state.plannedSec ? 1 : progress
    display = formatDuration(state.actualSec)
    caption = 'focused'
  } else if (state.phase === 'ended') {
    status = 'interrupted'
    display = formatDuration(state.actualSec)
    caption = 'logged'
  } else if (state.phase === 'break' || state.phase === 'breakOver') {
    status = 'break'
    const be = state.phase === 'break' ? breakElapsedSec(state, now) : state.breakSec
    progress = state.breakSec ? be / state.breakSec : 1
    display = state.phase === 'breakOver' ? '0:00' : formatTimer(state.breakSec - be, settings.focus.hideSeconds)
    caption = state.phase === 'breakOver' ? 'break over' : `${state.breakKind} break`
  }

  const taskTitle = task?.title ?? (state.taskId ? 'Task' : 'Untitled session')
  const breaksOn = settings.modules.breaks
  const inSession = state.phase === 'running' || state.phase === 'paused'

  return (
    <div className="flex min-h-dvh flex-col items-center px-5 pb-[max(24px,env(safe-area-inset-bottom))] pt-[max(16px,env(safe-area-inset-top))]">
      <div className="flex w-full max-w-xl items-center justify-between">
        <Button variant="ghost" size="icon" onClick={() => navigate('/')} aria-label="Back to Today">
          <ArrowLeft />
        </Button>
        <div className="flex items-center gap-1">
          {settings.modules.ambient && settings.ambient.available.length > 0 && inSession && (
            <Button variant="ghost" size="icon" onClick={() => setSoundOpen(true)} aria-label="Ambient sound">
              {state.sound ? <Volume2 /> : <VolumeX />}
            </Button>
          )}
        </div>
      </div>

      <div className="flex w-full max-w-xl flex-1 flex-col items-center justify-center py-4">
        <motion.p
          key={taskTitle}
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-8 max-w-md text-center text-lg font-medium tracking-tight text-fg/90 sm:text-xl"
        >
          {state.phase === 'break' || state.phase === 'breakOver' ? 'Step away for a moment' : taskTitle}
        </motion.p>

        <ProgressRing progress={progress} status={status} ring={settings.ring}>
          <div className={cn('tabular font-semibold tracking-tight transition-colors duration-700', status === 'interrupted' ? 'text-muted' : 'text-fg', settings.focus.hideSeconds ? 'text-[44px] sm:text-[52px]' : 'text-[52px] sm:text-[64px]')}>
            {display}
          </div>
          <div className="mt-1 text-sm text-muted">{caption}</div>
          {inSession && settings.modules.distractions && distractionCount > 0 && (
            <div className="mt-3 rounded-full bg-card-2 px-2.5 py-1 text-xs text-muted">{pluralize(distractionCount, 'distraction')}</div>
          )}
        </ProgressRing>

        <div className="mt-10 w-full">
          {inSession && (
            <div className="flex items-center justify-center gap-3">
              {settings.modules.distractions && (
                <Button variant="secondary" size="lg" onClick={() => setDistractOpen(true)} className="min-w-[124px]">
                  <Zap /> Distracted
                </Button>
              )}
              {state.phase === 'running' ? (
                <Button variant="primary" size="icon" className="size-14 rounded-full" onClick={pause} aria-label="Pause">
                  <Pause className="!size-5 fill-current" />
                </Button>
              ) : (
                <Button variant="primary" size="icon" className="size-14 rounded-full" onClick={resume} aria-label="Resume">
                  <Play className="!size-5 fill-current" />
                </Button>
              )}
              <Button variant="secondary" size="lg" onClick={() => setEndOpen(true)} className="min-w-[124px]">
                <Square className="size-3.5 fill-current" /> End
              </Button>
            </div>
          )}

          {state.phase === 'finished' && <SessionClose />}

          {state.phase === 'closed' && (
            <ResultCard
              title="Session complete"
              body={`${formatDuration(state.actualSec)} on ${taskTitle}.`}
              tone="success"
              actions={
                <>
                  {breaksOn ? (
                    <>
                      <Button variant="primary" size="lg" className="w-full" onClick={() => startBreak(suggest)}>
                        Start {suggest === 'long' ? settings.breaks.long : settings.breaks.short}-minute {suggest} break
                      </Button>
                      <div className="grid w-full grid-cols-2 gap-2">
                        <Button variant="secondary" onClick={() => startBreak(suggest === 'long' ? 'short' : 'long')}>
                          {suggest === 'long' ? `Short break (${settings.breaks.short}m)` : `Long break (${settings.breaks.long}m)`}
                        </Button>
                        <Button variant="secondary" onClick={() => void startNext()}>
                          Next session
                        </Button>
                      </div>
                    </>
                  ) : (
                    <Button variant="primary" size="lg" className="w-full" onClick={() => void startNext()}>
                      Start another session
                    </Button>
                  )}
                  <Button
                    variant="ghost"
                    className="w-full"
                    onClick={() => {
                      reset()
                      navigate('/')
                    }}
                  >
                    Done for now
                  </Button>
                </>
              }
            />
          )}

          {state.phase === 'ended' && (
            <ResultCard
              title="Session ended early"
              body={`${formatDuration(state.actualSec)} logged as interrupted${state.endReason ? ` · ${state.endReason}` : ''}. That's useful data, not a failure.`}
              tone="neutral"
              actions={
                <>
                  <Button variant="primary" size="lg" className="w-full" onClick={() => reset()}>
                    Start a new session
                  </Button>
                  <Button
                    variant="ghost"
                    className="w-full"
                    onClick={() => {
                      reset()
                      navigate('/')
                    }}
                  >
                    Back to Today
                  </Button>
                </>
              }
            />
          )}

          {state.phase === 'break' && (
            <div className="flex justify-center">
              <Button variant="secondary" size="lg" onClick={skipBreak}>
                <SkipForward /> Skip break
              </Button>
            </div>
          )}

          {state.phase === 'breakOver' && (
            <ResultCard
              title="Break's over"
              body={settings.breaks.autoStartNext ? 'Starting your next session…' : 'Ready when you are.'}
              tone="success"
              actions={
                <>
                  <Button variant="primary" size="lg" className="w-full" onClick={() => void startNext()}>
                    <Play className="fill-current" /> Start next session
                  </Button>
                  <Button
                    variant="ghost"
                    className="w-full"
                    onClick={() => {
                      reset()
                      navigate('/')
                    }}
                  >
                    Done for now
                  </Button>
                </>
              }
            />
          )}
        </div>
      </div>

      <DistractionSheet open={distractOpen} onOpenChange={setDistractOpen} />
      <EndEarlyDialog open={endOpen} onOpenChange={setEndOpen} />
      <Dialog open={soundOpen} onOpenChange={setSoundOpen} title="Ambient sound">
        <div className="pb-3">
          <SoundPicker sound={state.sound} onChange={setSound} compact />
        </div>
      </Dialog>
    </div>
  )
}

function ResultCard({ title, body, actions, tone }: { title: string; body: string; actions: React.ReactNode; tone: 'success' | 'neutral' }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: 'spring', stiffness: 260, damping: 26, delay: 0.15 }}
      className="card pad mx-auto w-full max-w-sm"
    >
      <div className="mb-4 flex items-start gap-3">
        {tone === 'success' ? <CircleCheck className="mt-0.5 size-5 shrink-0 text-success" /> : <X className="mt-0.5 size-5 shrink-0 text-muted" />}
        <div>
          <h2 className="font-semibold tracking-tight">{title}</h2>
          <p className="mt-0.5 text-sm text-muted">{body}</p>
        </div>
      </div>
      <div className="flex flex-col items-stretch gap-2">{actions}</div>
    </motion.div>
  )
}

function DistractionSheet({ open, onOpenChange }: { open: boolean; onOpenChange: (o: boolean) => void }) {
  const reasons = useReasons() ?? []
  const { settings } = useSettings()
  const { logDistraction } = useFocus()
  const [reason, setReason] = useState<string | null>(null)
  const [note, setNote] = useState('')
  useEffect(() => {
    if (open) {
      setReason(null)
      setNote('')
    }
  }, [open])

  const save = async (r: string, n = '') => {
    await logDistraction(r, n)
    onOpenChange(false)
    toast('Distraction logged. Back to it.', { kind: 'success', duration: 2200 })
  }

  return (
    <Dialog
      open={open}
      onOpenChange={onOpenChange}
      title="What pulled you away?"
      description="The timer keeps running."
      footer={
        settings.distractions.noteEnabled ? (
          <Button variant="primary" disabled={!reason} onClick={() => reason && void save(reason, note)}>
            Log distraction
          </Button>
        ) : undefined
      }
    >
      <div className="grid grid-cols-2 gap-2 pb-2 sm:grid-cols-3">
        {reasons.map((r) => (
          <button
            key={r.id}
            onClick={() => (settings.distractions.noteEnabled ? setReason(r.label) : void save(r.label))}
            className={cn(
              'h-12 rounded-[12px] border px-3 text-sm font-medium transition-all active:scale-95',
              reason === r.label ? 'border-accent/60 bg-accent-soft text-accent' : 'border-border bg-card-2/60 hover:bg-card-2',
            )}
          >
            {r.label}
          </button>
        ))}
      </div>
      {settings.distractions.noteEnabled && (
        <Input className="mt-3" value={note} onChange={(e) => setNote(e.target.value)} placeholder="Optional note" aria-label="Distraction note" />
      )}
      <div className="h-2" />
    </Dialog>
  )
}

const END_REASONS = ['Something urgent came up', 'Out of energy', 'Meeting or interruption', 'Wrong task', 'Other']

function EndEarlyDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (o: boolean) => void }) {
  const { state, endEarly, discard } = useFocus()
  const [other, setOther] = useState('')
  const [picked, setPicked] = useState<string | null>(null)
  useEffect(() => {
    if (open) {
      setPicked(null)
      setOther('')
    }
  }, [open])
  const short = elapsedSec(state) < 60

  const end = async (reason: string, finishedEarly: boolean) => {
    onOpenChange(false)
    await endEarly({ reason, finishedEarly })
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange} title="End session early?" description="A quick reason helps you spot patterns later.">
      <div className="space-y-2 pb-3">
        <button
          onClick={() => void end('Finished early', true)}
          className="flex h-12 w-full items-center gap-2 rounded-[12px] border border-success/40 bg-success/10 px-4 text-left text-sm font-medium text-success transition-all active:scale-[0.99]"
        >
          <CircleCheck className="size-4" /> I finished early
        </button>
        <div className="grid grid-cols-2 gap-2">
          {END_REASONS.map((r) => (
            <button
              key={r}
              onClick={() => (r === 'Other' ? setPicked('Other') : void end(r, false))}
              className={cn(
                'min-h-12 rounded-[12px] border px-3 py-2 text-left text-sm font-medium transition-all active:scale-95',
                picked === r ? 'border-accent/60 bg-accent-soft text-accent' : 'border-border bg-card-2/60 hover:bg-card-2',
              )}
            >
              {r}
            </button>
          ))}
        </div>
        {picked === 'Other' && (
          <form
            className="flex gap-2 pt-1"
            onSubmit={(e) => {
              e.preventDefault()
              void end(other.trim() || 'Other', false)
            }}
          >
            <Input autoFocus value={other} onChange={(e) => setOther(e.target.value)} placeholder="What happened?" />
            <Button type="submit" variant="primary">
              End
            </Button>
          </form>
        )}
        {short && (
          <Button
            variant="danger-ghost"
            className="mt-2 w-full"
            onClick={() => {
              onOpenChange(false)
              void discard()
            }}
          >
            Discard (under a minute, not logged)
          </Button>
        )}
      </div>
    </Dialog>
  )
}

export { SoundPicker }

import { Play, Plus, Square, X } from 'lucide-react'
import { useEffect, useRef, useState } from 'react'
import { db, uid } from '@/db'
import { useSettings, DEFAULT_REASONS } from '@/state/settings'
import { useReasons } from '@/hooks/data'
import {
  AMBIENT_SOUNDS,
  CHARTS,
  INSIGHT_CARDS,
  TASK_FIELDS,
  resetSection,
  type ResettableSection,
  type Settings,
} from '@/lib/settings'
import { DAY_NAMES } from '@/lib/date'
import { ambient, unlockAudio } from '@/lib/audio'
import { Row, Section } from '@/components/ui/row'
import { Switch } from '@/components/ui/switch'
import { Segmented } from '@/components/ui/segmented'
import { Select, Input } from '@/components/ui/input'
import { Slider } from '@/components/ui/slider'
import { Button } from '@/components/ui/button'
import { Chip } from '@/components/ui/chip'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { ProjectManager } from '@/components/shared/ProjectManager'
import { ProgressRing } from '@/features/focus/ProgressRing'
import { CommitInput, NumberInput, QuestionsEditor, ResetButton, SortableList, TimeInput } from '../controls'

const GROUPS: { id: string; label: string; module?: keyof Settings['modules'] }[] = [
  { id: 'c-priorities', label: 'Priorities', module: 'priorities' },
  { id: 'c-blocks', label: 'Time blocks', module: 'timeBlocks' },
  { id: 'c-tasks', label: 'Tasks', module: 'tasks' },
  { id: 'c-focus', label: 'Focus timer' },
  { id: 'c-ring', label: 'Progress ring' },
  { id: 'c-distractions', label: 'Distractions', module: 'distractions' },
  { id: 'c-close', label: 'Session close', module: 'sessionClose' },
  { id: 'c-breaks', label: 'Breaks', module: 'breaks' },
  { id: 'c-ambient', label: 'Sounds', module: 'ambient' },
  { id: 'c-streaks', label: 'Streaks', module: 'streaks' },
  { id: 'c-evening', label: 'Evening review', module: 'eveningReview' },
  { id: 'c-weekly', label: 'Weekly review', module: 'weeklyReview' },
  { id: 'c-insights', label: 'Insights', module: 'insights' },
  { id: 'c-goal', label: 'Daily goal' },
]

export function CustomizeSection() {
  const { settings, update } = useSettings()
  const m = settings.modules
  const reset = (section: ResettableSection) => update((s) => resetSection(s, section))
  const off = (k?: keyof Settings['modules']) => (k && !m[k] ? ' (module off)' : '')

  return (
    <div>
      <div className="no-scrollbar sticky top-0 z-10 -mx-4 mb-5 flex gap-1.5 overflow-x-auto bg-bg/85 px-4 py-2 backdrop-blur md:static md:mx-0 md:flex-wrap md:bg-transparent md:px-0 md:py-0 md:backdrop-blur-none">
        {GROUPS.map((g) => (
          <Chip key={g.id} onClick={() => document.getElementById(g.id)?.scrollIntoView({ behavior: 'smooth', block: 'start' })} className={g.module && !m[g.module] ? 'opacity-50' : ''}>
            {g.label}
          </Chip>
        ))}
      </div>

      <div id="c-priorities" className="scroll-mt-16">
        <Section title={`Top priorities${off('priorities')}`} action={<ResetButton label="Top priorities" onReset={() => reset('priorities')} />}>
          <Row label="Priorities per day">
            <Segmented value={settings.priorities.count} onChange={(v) => void update((s) => void (s.priorities.count = v))} options={[1, 2, 3, 4, 5].map((n) => ({ value: n, label: n }))} size="sm" />
          </Row>
          <Row label="Section label" stacked>
            <CommitInput value={settings.priorities.label} onCommit={(v) => void update((s) => void (s.priorities.label = v.trim() || 'Top priorities'))} />
          </Row>
        </Section>
      </div>

      <div id="c-blocks" className="scroll-mt-16">
        <Section title={`Time blocks${off('timeBlocks')}`} action={<ResetButton label="Time blocks" onReset={() => reset('timeBlocks')} />}>
          <Row label="Day starts">
            <TimeInput value={settings.timeBlocks.dayStart} onCommit={(v) => void update((s) => void (s.timeBlocks.dayStart = v))} />
          </Row>
          <Row label="Day ends" description={settings.timeBlocks.dayEnd <= settings.timeBlocks.dayStart ? 'Must be after the start time.' : undefined}>
            <TimeInput value={settings.timeBlocks.dayEnd} onCommit={(v) => void update((s) => void (s.timeBlocks.dayEnd = v))} />
          </Row>
          <Row label="Block length">
            <Segmented
              size="sm"
              value={settings.timeBlocks.blockLength}
              onChange={(v) => void update((s) => void (s.timeBlocks.blockLength = v))}
              options={[
                { value: 15, label: '15m' },
                { value: 30, label: '30m' },
                { value: 60, label: '60m' },
              ]}
            />
          </Row>
          <Row label="Show on weekends">
            <Switch checked={settings.timeBlocks.showWeekends} onCheckedChange={(v) => void update((s) => void (s.timeBlocks.showWeekends = v))} aria-label="Show on weekends" />
          </Row>
        </Section>
      </div>

      <div id="c-tasks" className="scroll-mt-16">
        <Section title={`Tasks${off('tasks')}`} action={<ResetButton label="Task fields" onReset={() => reset('tasks')} />}>
          <Row label="Project tags" description="Create, rename, recolor or delete." stacked>
            <ProjectManager />
          </Row>
          <Row label="Visible fields" stacked>
            <div className="flex flex-wrap gap-1.5">
              {TASK_FIELDS.map((f) => {
                const on = settings.tasks.visibleFields.includes(f.id)
                return (
                  <Chip
                    key={f.id}
                    active={on}
                    onClick={() =>
                      void update((s) => {
                        s.tasks.visibleFields = on ? s.tasks.visibleFields.filter((x) => x !== f.id) : [...s.tasks.visibleFields, f.id]
                      })
                    }
                  >
                    {f.label}
                  </Chip>
                )
              })}
            </div>
          </Row>
        </Section>
      </div>

      <div id="c-focus" className="scroll-mt-16">
        <FocusCustomization onReset={() => reset('focus')} />
      </div>

      <div id="c-ring" className="scroll-mt-16">
        <Section title="Progress ring" action={<ResetButton label="Progress ring" onReset={() => reset('ring')} />}>
          <RingPreview />
          <Row label="Style">
            <Segmented
              size="sm"
              value={settings.ring.style}
              onChange={(v) => void update((s) => void (s.ring.style = v))}
              options={[
                { value: 'thin', label: 'Thin' },
                { value: 'bold', label: 'Bold' },
                { value: 'segmented', label: 'Segmented' },
              ]}
            />
          </Row>
          <Row label="Glow">
            <Switch checked={settings.ring.glow} onCheckedChange={(v) => void update((s) => void (s.ring.glow = v))} aria-label="Glow" />
          </Row>
          <Row label="Completion animation">
            <Switch checked={settings.ring.completionAnimation} onCheckedChange={(v) => void update((s) => void (s.ring.completionAnimation = v))} aria-label="Completion animation" />
          </Row>
        </Section>
      </div>

      <div id="c-distractions" className="scroll-mt-16">
        <DistractionCustomization />
      </div>

      <div id="c-close" className="scroll-mt-16">
        <Section title={`Session close${off('sessionClose')}`} action={<ResetButton label="Session close" onReset={() => reset('sessionClose')} />}>
          <Row label="Result options" description="Which results you can pick." stacked>
            <div className="flex flex-wrap gap-1.5">
              {(['done', 'partly', 'stuck'] as const).map((r) => (
                <Chip key={r} active={settings.sessionClose.results[r]} onClick={() => void update((s) => void (s.sessionClose.results[r] = !s.sessionClose.results[r]))}>
                  {r === 'done' ? 'Done' : r === 'partly' ? 'Partly done' : 'Stuck'}
                </Chip>
              ))}
            </div>
          </Row>
          <Row label="“What did I get done?” note">
            <Segmented
              size="sm"
              value={settings.sessionClose.note}
              onChange={(v) => void update((s) => void (s.sessionClose.note = v))}
              options={[
                { value: 'required', label: 'Required' },
                { value: 'optional', label: 'Optional' },
                { value: 'hidden', label: 'Hidden' },
              ]}
            />
          </Row>
          <Row label="“Stuck” next-step prompt" description="Ask for the smallest next step and turn it into tasks.">
            <Switch checked={settings.sessionClose.stuckPrompt} onCheckedChange={(v) => void update((s) => void (s.sessionClose.stuckPrompt = v))} aria-label="Stuck prompt" />
          </Row>
        </Section>
      </div>

      <div id="c-breaks" className="scroll-mt-16">
        <Section title={`Breaks${off('breaks')}`} action={<ResetButton label="Breaks" onReset={() => reset('breaks')} />}>
          <Row label="Short break">
            <NumberInput value={settings.breaks.short} min={1} max={60} suffix="min" onCommit={(n) => void update((s) => void (s.breaks.short = n))} />
          </Row>
          <Row label="Long break">
            <NumberInput value={settings.breaks.long} min={1} max={120} suffix="min" onCommit={(n) => void update((s) => void (s.breaks.long = n))} />
          </Row>
          <Row label="Long break after">
            <NumberInput value={settings.breaks.longAfter} min={1} max={12} suffix="sessions" onCommit={(n) => void update((s) => void (s.breaks.longAfter = n))} />
          </Row>
          <Row label="Auto-start next session" description="Start the next session automatically when a break ends.">
            <Switch checked={settings.breaks.autoStartNext} onCheckedChange={(v) => void update((s) => void (s.breaks.autoStartNext = v))} aria-label="Auto-start next session" />
          </Row>
        </Section>
      </div>

      <div id="c-ambient" className="scroll-mt-16">
        <AmbientCustomization onReset={() => reset('ambient')} />
      </div>

      <div id="c-streaks" className="scroll-mt-16">
        <Section title={`Streaks${off('streaks')}`} action={<ResetButton label="Streaks" onReset={() => reset('streaks')} />}>
          <Row label="Rule" stacked>
            <Segmented
              size="sm"
              value={settings.streaks.rule}
              onChange={(v) => void update((s) => void (s.streaks.rule = v))}
              options={[
                { value: 'strict', label: 'Strict daily' },
                { value: 'neverMissTwice', label: 'Never miss twice' },
                { value: 'weekdays', label: 'Weekdays only' },
              ]}
            />
          </Row>
          <Row label="A day counts when I complete" stacked>
            <div className="flex flex-wrap items-center gap-3">
              <Segmented
                size="sm"
                value={settings.streaks.countsAs}
                onChange={(v) =>
                  void update((s) => {
                    s.streaks.countsAs = v
                    s.streaks.amount = v === 'minutes' ? 60 : 1
                  })
                }
                options={[
                  { value: 'session', label: 'Sessions' },
                  { value: 'minutes', label: 'Focus minutes' },
                  { value: 'tasks', label: 'Tasks' },
                ]}
              />
              <NumberInput value={settings.streaks.amount} min={1} max={settings.streaks.countsAs === 'minutes' ? 600 : 20} onCommit={(n) => void update((s) => void (s.streaks.amount = n))} suffix={settings.streaks.countsAs === 'minutes' ? 'min' : settings.streaks.countsAs === 'session' ? 'session(s)' : 'task(s)'} />
            </div>
          </Row>
        </Section>
      </div>

      <div id="c-evening" className="scroll-mt-16">
        <Section title={`Evening review${off('eveningReview')}`} action={<ResetButton label="Evening review" onReset={() => reset('eveningReview')} />}>
          <Row label="Review time" description="The review card appears on Today after this time.">
            <TimeInput value={settings.eveningReview.time} onCommit={(v) => void update((s) => void (s.eveningReview.time = v))} />
          </Row>
          <Row label="Questions" stacked>
            <QuestionsEditor questions={settings.eveningReview.questions} onChange={(q) => void update((s) => void (s.eveningReview.questions = q))} />
          </Row>
        </Section>
      </div>

      <div id="c-weekly" className="scroll-mt-16">
        <Section title={`Weekly review${off('weeklyReview')}`} action={<ResetButton label="Weekly review" onReset={() => reset('weeklyReview')} />}>
          <Row label="Day">
            <Select value={settings.weeklyReview.day} onChange={(e) => void update((s) => void (s.weeklyReview.day = Number(e.target.value)))} className="w-[150px]">
              {DAY_NAMES.map((d, i) => (
                <option key={d} value={i}>
                  {d}
                </option>
              ))}
            </Select>
          </Row>
          <Row label="Time">
            <TimeInput value={settings.weeklyReview.time} onCommit={(v) => void update((s) => void (s.weeklyReview.time = v))} />
          </Row>
          <Row label="Questions" stacked>
            <QuestionsEditor questions={settings.weeklyReview.questions} onChange={(q) => void update((s) => void (s.weeklyReview.questions = q))} />
          </Row>
        </Section>
      </div>

      <div id="c-insights" className="scroll-mt-16">
        <Section title={`Insights${off('insights')}`} action={<ResetButton label="Insights" onReset={() => reset('insights')} />}>
          <Row label="Default date range">
            <Segmented
              size="sm"
              value={settings.insights.defaultRange}
              onChange={(v) => void update((s) => void (s.insights.defaultRange = v))}
              options={[
                { value: 7, label: '7d' },
                { value: 14, label: '14d' },
                { value: 30, label: '30d' },
                { value: 90, label: '90d' },
                { value: 0, label: 'All' },
              ]}
            />
          </Row>
          <Row label="Visible charts" stacked>
            <div className="flex flex-wrap gap-1.5">
              {CHARTS.map((c) => {
                const on = settings.insights.charts.includes(c.id)
                return (
                  <Chip key={c.id} active={on} onClick={() => void update((s) => void (s.insights.charts = on ? s.insights.charts.filter((x) => x !== c.id) : [...s.insights.charts, c.id]))}>
                    {c.label}
                  </Chip>
                )
              })}
            </div>
          </Row>
          <Row label="Visible insight cards" description={!m.insightCards ? 'Insight cards module is off.' : undefined} stacked>
            <div className="flex flex-wrap gap-1.5">
              {INSIGHT_CARDS.map((c) => {
                const on = settings.insights.cards.includes(c.id)
                return (
                  <Chip key={c.id} active={on} onClick={() => void update((s) => void (s.insights.cards = on ? s.insights.cards.filter((x) => x !== c.id) : [...s.insights.cards, c.id]))}>
                    {c.label}
                  </Chip>
                )
              })}
            </div>
          </Row>
        </Section>
      </div>

      <div id="c-goal" className="scroll-mt-16">
        <Section title="Daily goal" action={<ResetButton label="Daily goal" onReset={() => reset('dailyGoal')} />}>
          <Row label="Measure">
            <Segmented
              size="sm"
              value={settings.dailyGoal.type}
              onChange={(v) =>
                void update((s) => {
                  s.dailyGoal.type = v
                  s.dailyGoal.target = v === 'minutes' ? 120 : v === 'sessions' ? 4 : 3
                })
              }
              options={[
                { value: 'minutes', label: 'Minutes' },
                { value: 'sessions', label: 'Sessions' },
                { value: 'tasks', label: 'Tasks' },
              ]}
            />
          </Row>
          <Row label="Target">
            <NumberInput value={settings.dailyGoal.target} min={1} max={settings.dailyGoal.type === 'minutes' ? 960 : 50} onCommit={(n) => void update((s) => void (s.dailyGoal.target = n))} suffix={settings.dailyGoal.type === 'minutes' ? 'min' : settings.dailyGoal.type} />
          </Row>
        </Section>
      </div>
    </div>
  )
}

function FocusCustomization({ onReset }: { onReset: () => Promise<void> }) {
  const { settings, update } = useSettings()
  const [preset, setPreset] = useState('')
  const f = settings.focus
  return (
    <Section title="Focus timer" action={<ResetButton label="Focus timer" onReset={onReset} />}>
      <Row label="Presets" description="Tap × to remove." stacked>
        <div className="flex flex-wrap items-center gap-1.5">
          {f.presets.map((p) => (
            <span key={p} className="tabular inline-flex h-8 items-center gap-1 rounded-full border border-border bg-card-2/60 pl-3 pr-1 text-[13px] font-medium">
              {p} min
              <button
                className="rounded-full p-1 text-muted hover:text-fg disabled:opacity-30"
                disabled={f.presets.length <= 1}
                onClick={() =>
                  void update((s) => {
                    s.focus.presets = s.focus.presets.filter((x) => x !== p)
                    if (!s.focus.presets.includes(s.focus.defaultDuration)) s.focus.defaultDuration = s.focus.presets[0]
                  })
                }
                aria-label={`Remove ${p} minute preset`}
              >
                <X className="size-3" />
              </button>
            </span>
          ))}
          <form
            className="flex items-center gap-1"
            onSubmit={(e) => {
              e.preventDefault()
              const n = Math.round(Number(preset))
              if (!(n >= 1 && n <= 300)) return toast('Use 1–300 minutes.')
              void update((s) => void (s.focus.presets = [...new Set([...s.focus.presets, n])].sort((a, b) => a - b)))
              setPreset('')
            }}
          >
            <Input type="number" value={preset} onChange={(e) => setPreset(e.target.value)} placeholder="min" className="tabular h-8 w-20 rounded-full" aria-label="New preset minutes" />
            <Button type="submit" variant="ghost" size="icon-sm" disabled={!preset} aria-label="Add preset">
              <Plus />
            </Button>
          </form>
        </div>
      </Row>
      <Row label="Default duration">
        <Select value={f.defaultDuration} onChange={(e) => void update((s) => void (s.focus.defaultDuration = Number(e.target.value)))} className="w-[120px]">
          {f.presets.map((p) => (
            <option key={p} value={p}>
              {p} min
            </option>
          ))}
        </Select>
      </Row>
      <Row label="Allow custom duration">
        <Switch checked={f.allowCustom} onCheckedChange={(v) => void update((s) => void (s.focus.allowCustom = v))} aria-label="Allow custom duration" />
      </Row>
      <Row label="Timer mode">
        <Segmented
          size="sm"
          value={f.mode}
          onChange={(v) => void update((s) => void (s.focus.mode = v))}
          options={[
            { value: 'countdown', label: 'Countdown' },
            { value: 'countup', label: 'Count-up' },
          ]}
        />
      </Row>
      <Row label="Hide seconds">
        <Switch checked={f.hideSeconds} onCheckedChange={(v) => void update((s) => void (s.focus.hideSeconds = v))} aria-label="Hide seconds" />
      </Row>
      <Row label="Require a task" description="Off allows untitled sessions.">
        <Switch checked={f.requireTask} onCheckedChange={(v) => void update((s) => void (s.focus.requireTask = v))} aria-label="Require a task" />
      </Row>
      <Row label="Keep screen awake" description={'wakeLock' in navigator ? 'Uses the Screen Wake Lock API during sessions.' : 'Not supported in this browser.'}>
        <Switch checked={f.wakeLock} onCheckedChange={(v) => void update((s) => void (s.focus.wakeLock = v))} aria-label="Keep screen awake" />
      </Row>
    </Section>
  )
}

function RingPreview() {
  const { settings } = useSettings()
  const [p, setP] = useState(0.62)
  return (
    <div className="flex items-center gap-5 border-b border-border/70 py-4">
      <div className="w-28 shrink-0 [&>div]:!w-28">
        <ProgressRing progress={p} status="active" ring={settings.ring}>
          <span className="tabular text-sm font-semibold">{Math.round(p * 100)}%</span>
        </ProgressRing>
      </div>
      <div className="flex-1">
        <p className="mb-2 text-[13px] text-muted">Preview</p>
        <Slider value={p} onValueChange={setP} aria-label="Preview progress" />
      </div>
    </div>
  )
}

function DistractionCustomization() {
  const { settings, update } = useSettings()
  const reasons = useReasons() ?? []
  const [draft, setDraft] = useState('')
  return (
    <Section
      title={`Distraction logging${settings.modules.distractions ? '' : ' (module off)'}`}
      action={
        <ResetButton
          label="Distraction logging"
          onReset={async () => {
            await db.transaction('rw', db.distractionReasons, async () => {
              await db.distractionReasons.clear()
              await db.distractionReasons.bulkPut(DEFAULT_REASONS.map((label, order) => ({ id: uid(), label, order })))
            })
            await update((s) => resetSection(s, 'distractions'))
          }}
        />
      }
    >
      <Row label="Reasons" description="Drag to reorder. Past logs keep their original label." stacked>
        <div className="py-1">
          <SortableList
            items={reasons}
            onReorder={(next) =>
              void db.transaction('rw', db.distractionReasons, async () => {
                for (const [i, r] of next.entries()) await db.distractionReasons.update(r.id, { order: i })
              })
            }
            render={(r, handle) => (
              <div className="flex items-center gap-1.5">
                {handle}
                <CommitInput value={r.label} onCommit={(v) => v.trim() && void db.distractionReasons.update(r.id, { label: v.trim() })} className="h-9" aria-label="Reason label" />
                <Button
                  variant="ghost"
                  size="icon-sm"
                  disabled={reasons.length <= 1}
                  onClick={async () => {
                    if (await confirmDialog({ title: `Delete “${r.label}”?`, description: 'Past distractions keep this label.', confirmLabel: 'Delete', danger: true })) await db.distractionReasons.delete(r.id)
                  }}
                  aria-label={`Delete ${r.label}`}
                >
                  <X />
                </Button>
              </div>
            )}
          />
          <form
            className="mt-2 flex gap-2 pl-7"
            onSubmit={async (e) => {
              e.preventDefault()
              if (!draft.trim()) return
              await db.distractionReasons.put({ id: uid(), label: draft.trim(), order: reasons.length })
              setDraft('')
            }}
          >
            <Input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="Add a reason" className="h-9" />
            <Button type="submit" variant="secondary" size="icon" className="size-9" disabled={!draft.trim()} aria-label="Add reason">
              <Plus />
            </Button>
          </form>
        </div>
      </Row>
      <Row label="Optional note" description="Show a note field when logging a distraction.">
        <Switch checked={settings.distractions.noteEnabled} onCheckedChange={(v) => void update((s) => void (s.distractions.noteEnabled = v))} aria-label="Distraction note" />
      </Row>
    </Section>
  )
}

function AmbientCustomization({ onReset }: { onReset: () => Promise<void> }) {
  const { settings, update } = useSettings()
  const [vol, setVol] = useState(settings.ambient.volume)
  const [previewing, setPreviewing] = useState<string | null>(null)
  const a = settings.ambient
  const previewRef = useRef<string | null>(null)
  previewRef.current = previewing
  useEffect(() => () => void (previewRef.current && ambient.stop()), [])
  const preview = (id: (typeof AMBIENT_SOUNDS)[number]['id']) => {
    unlockAudio()
    if (previewing === id) {
      ambient.stop()
      setPreviewing(null)
    } else {
      ambient.play(id, vol)
      setPreviewing(id)
    }
  }
  return (
    <Section
      title={`Ambient sounds${settings.modules.ambient ? '' : ' (module off)'}`}
      action={
        <ResetButton
          label="Ambient sounds"
          onReset={async () => {
            await onReset()
            setVol(0.5)
          }}
        />
      }
    >
      {AMBIENT_SOUNDS.map((s) => (
        <Row key={s.id} label={s.label}>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon-sm" onClick={() => preview(s.id)} aria-label={previewing === s.id ? `Stop ${s.label}` : `Preview ${s.label}`}>
              {previewing === s.id ? <Square className="!size-3 fill-current" /> : <Play className="!size-3.5 fill-current" />}
            </Button>
            <Switch
              checked={a.available.includes(s.id)}
              onCheckedChange={(v) => void update((st) => void (st.ambient.available = v ? [...st.ambient.available, s.id] : st.ambient.available.filter((x) => x !== s.id)))}
              aria-label={`${s.label} available`}
            />
          </div>
        </Row>
      ))}
      <Row label="Volume" stacked>
        <Slider
          value={vol}
          onValueChange={(v) => {
            setVol(v)
            ambient.setVolume(v)
          }}
          onValueCommit={(v) => void update((s) => void (s.ambient.volume = v))}
          aria-label="Volume"
        />
      </Row>
      <Row label="Play by default" description="Preselect a sound when starting a session.">
        <Switch checked={a.defaultOn} onCheckedChange={(v) => void update((s) => void (s.ambient.defaultOn = v))} aria-label="Play by default" />
      </Row>
      {a.defaultOn && (
        <Row label="Default sound">
          <Select value={a.defaultSound} onChange={(e) => void update((s) => void (s.ambient.defaultSound = e.target.value as typeof a.defaultSound))} className="w-[150px]">
            {AMBIENT_SOUNDS.filter((s) => a.available.includes(s.id)).map((s) => (
              <option key={s.id} value={s.id}>
                {s.label}
              </option>
            ))}
          </Select>
        </Row>
      )}
    </Section>
  )
}

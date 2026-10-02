import { format } from 'date-fns'
import { Check, Circle, Plus } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router'
import { useLiveQuery } from 'dexie-react-hooks'
import { startOfDay } from 'date-fns'
import { db, uid } from '@/db'
import { useSettings } from '@/state/settings'
import { createTask, useDistractions, useSessions, useTasks, useTimeBlocks } from '@/hooks/data'
import { Page } from '@/components/shared/Page'
import { Button } from '@/components/ui/button'
import { Card, CardHeader } from '@/components/ui/card'
import { Input, Textarea } from '@/components/ui/input'
import { LoadingBlock, PageHeader } from '@/components/ui/empty'
import { toast } from '@/components/ui/toast'
import { plannedVsDone } from '@/lib/stats'
import { formatDuration, todayKey, tomorrowKey } from '@/lib/date'
import { cn } from '@/lib/utils'

export default function EveningReviewPage() {
  const { settings } = useSettings()
  const navigate = useNavigate()
  const today = todayKey()
  const tomorrow = tomorrowKey()
  const since = useMemo(() => startOfDay(new Date()).getTime(), [])
  const tasks = useTasks()
  const blocks = useTimeBlocks(today)
  const sessions = useSessions(since)
  const distractions = useDistractions(since)
  const existing = useLiveQuery(() => db.reviews.where('date').equals(today).filter((r) => r.type === 'daily').first(), [today])
  const questions = settings.eveningReview.questions
  const [answers, setAnswers] = useState<string[]>(() => questions.map(() => ''))
  const [picked, setPicked] = useState<string[] | null>(null)
  const [newTask, setNewTask] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (existing) setAnswers(questions.map((q) => existing.answers.find((a) => a.question === q)?.answer ?? ''))
  }, [existing, questions])

  useEffect(() => {
    if (tasks && picked === null) setPicked(tasks.filter((t) => t.is_priority && t.priority_date === tomorrow).sort((a, b) => a.priority_order - b.priority_order).map((t) => t.id))
  }, [tasks, picked, tomorrow])

  if (!tasks || !blocks || !sessions || !distractions || picked === null) {
    return (
      <Page>
        <PageHeader title="Evening review" />
        <LoadingBlock className="h-64" />
      </Page>
    )
  }

  const { planned, done, unplannedDone } = plannedVsDone(today, tasks, blocks)
  const focusSec = sessions.reduce((a, s) => a + s.actual_duration, 0)
  const reasonCounts = new Map<string, number>()
  for (const d of distractions) reasonCounts.set(d.reason, (reasonCounts.get(d.reason) ?? 0) + 1)
  const topReason = [...reasonCounts.entries()].sort((a, b) => b[1] - a[1])[0]
  const limit = settings.priorities.count
  const candidates = tasks.filter((t) => t.status !== 'done')

  const toggle = (id: string) =>
    setPicked((p) => {
      const cur = p ?? []
      if (cur.includes(id)) return cur.filter((x) => x !== id)
      if (cur.length >= limit) {
        toast(`Up to ${limit} priorities.`)
        return cur
      }
      return [...cur, id]
    })

  const save = async () => {
    setSaving(true)
    const chosen = picked
    if (settings.modules.priorities) {
      await db.transaction('rw', db.tasks, async () => {
        const prev = await db.tasks.where('priority_date').equals(tomorrow).toArray()
        for (const t of prev) if (!chosen.includes(t.id)) await db.tasks.update(t.id, { is_priority: false, priority_date: null })
        for (const [i, id] of chosen.entries()) await db.tasks.update(id, { is_priority: true, priority_date: tomorrow, priority_order: i })
      })
    }
    const review = {
      id: existing?.id ?? uid(),
      type: 'daily' as const,
      date: today,
      answers: questions.map((q, i) => ({ question: q, answer: answers[i]?.trim() ?? '' })),
      next_priorities: settings.modules.priorities ? chosen.map((id) => ({ task_id: id, title: tasks.find((t) => t.id === id)?.title ?? '' })) : [],
      stats: { focus_minutes: Math.round(focusSec / 60), planned: planned.length, done: done.length, distractions: distractions.length, top_distraction: topReason?.[0] ?? '' },
      created_at: existing?.created_at ?? Date.now(),
    }
    await db.reviews.put(review)
    setSaving(false)
    toast('Evening review saved', { kind: 'success' })
    navigate('/')
  }

  return (
    <Page>
      <PageHeader title="Evening review" subtitle={`${format(new Date(), 'EEEE, MMMM d')} · about 2 minutes`} />

      <div className="flex flex-col gap-d">
        {(settings.modules.priorities || settings.modules.timeBlocks) && (
          <Card>
            <CardHeader title="Planned vs. done" subtitle={planned.length ? `${done.length} of ${planned.length} planned tasks finished` : 'Nothing was planned today'} />
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-muted">Planned</p>
                <ul className="space-y-1.5">
                  {planned.map((t) => (
                    <li key={t.id} className="flex items-start gap-2 text-sm">
                      {t.status === 'done' ? <Check className="mt-0.5 size-4 shrink-0 text-success" /> : <Circle className="mt-0.5 size-4 shrink-0 text-muted" />}
                      <span className={cn(t.status !== 'done' && 'text-muted')}>{t.title}</span>
                    </li>
                  ))}
                  {planned.length === 0 && <li className="text-sm text-muted">—</li>}
                </ul>
              </div>
              <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-muted">Done</p>
                <ul className="space-y-1.5">
                  {done.map((t) => (
                    <li key={t.id} className="flex items-start gap-2 text-sm">
                      <Check className="mt-0.5 size-4 shrink-0 text-success" />
                      {t.title}
                    </li>
                  ))}
                  {unplannedDone.map((t) => (
                    <li key={t.id} className="flex items-start gap-2 text-sm">
                      <Check className="mt-0.5 size-4 shrink-0 text-success" />
                      <span>
                        {t.title} <span className="text-xs text-muted">(unplanned)</span>
                      </span>
                    </li>
                  ))}
                  {done.length + unplannedDone.length === 0 && <li className="text-sm text-muted">Nothing marked done yet.</li>}
                </ul>
              </div>
            </div>
          </Card>
        )}

        <Card className="grid grid-cols-3 gap-3 !py-4">
          <Stat label="Focus time" value={formatDuration(focusSec)} />
          <Stat label="Sessions" value={String(sessions.filter((s) => s.result !== 'interrupted').length)} />
          {settings.modules.distractions ? (
            <Stat label={topReason ? `Top: ${topReason[0]}` : 'Distractions'} value={String(distractions.length)} />
          ) : (
            <Stat label="Interrupted" value={String(sessions.filter((s) => s.result === 'interrupted').length)} />
          )}
        </Card>

        {questions.length > 0 && (
          <Card>
            <CardHeader title="Reflection" />
            <div className="space-y-4">
              {questions.map((q, i) => (
                <div key={q + i}>
                  <label className="mb-1.5 block text-sm font-medium">{q}</label>
                  <Textarea value={answers[i] ?? ''} onChange={(e) => setAnswers((a) => a.map((x, j) => (j === i ? e.target.value : x)))} placeholder="Write a line…" />
                </div>
              ))}
            </div>
          </Card>
        )}

        {settings.modules.priorities && (
          <Card>
            <CardHeader title={`Tomorrow's ${settings.priorities.label.toLowerCase()}`} subtitle={`${picked.length} of ${limit} chosen`} />
            <ul className="max-h-72 space-y-1 overflow-y-auto">
              {candidates.map((t) => {
                const on = picked.includes(t.id)
                const idx = picked.indexOf(t.id)
                return (
                  <li key={t.id}>
                    <button
                      onClick={() => toggle(t.id)}
                      className={cn('flex w-full items-center gap-3 rounded-[12px] px-3 py-2 text-left text-sm transition-colors', on ? 'bg-accent-soft' : 'hover:bg-card-2')}
                    >
                      <span className={cn('tabular flex size-6 shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold', on ? 'border-accent bg-accent text-accent-fg' : 'border-border')}>
                        {on ? idx + 1 : ''}
                      </span>
                      <span className="min-w-0 flex-1 truncate">{t.title}</span>
                    </button>
                  </li>
                )
              })}
              {candidates.length === 0 && <li className="py-3 text-sm text-muted">No open tasks. Add one below.</li>}
            </ul>
            <form
              className="mt-3 flex gap-2"
              onSubmit={async (e) => {
                e.preventDefault()
                if (!newTask.trim()) return
                const t = await createTask({ title: newTask.trim() })
                setNewTask('')
                toggle(t.id)
              }}
            >
              <Input value={newTask} onChange={(e) => setNewTask(e.target.value)} placeholder="New task for tomorrow" />
              <Button type="submit" variant="secondary" size="icon" disabled={!newTask.trim()} aria-label="Add">
                <Plus />
              </Button>
            </form>
          </Card>
        )}

        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={() => navigate(-1)}>
            Cancel
          </Button>
          <Button variant="primary" size="lg" disabled={saving} onClick={() => void save()}>
            {existing ? 'Update review' : 'Save review'}
          </Button>
        </div>
      </div>
    </Page>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="min-w-0">
      <div className="tabular text-[22px] font-semibold tracking-tight">{value}</div>
      <div className="truncate text-xs text-muted">{label}</div>
    </div>
  )
}

export { Stat }

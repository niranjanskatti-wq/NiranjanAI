import { addDays, format, startOfDay } from 'date-fns'
import { Clock } from 'lucide-react'
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router'
import { Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { db, uid } from '@/db'
import { useSettings } from '@/state/settings'
import { useDistractions, useSessions, useTasks } from '@/hooks/data'
import { Page } from '@/components/shared/Page'
import { Button } from '@/components/ui/button'
import { Card, CardHeader } from '@/components/ui/card'
import { Textarea } from '@/components/ui/input'
import { LoadingBlock, PageHeader } from '@/components/ui/empty'
import { toast } from '@/components/ui/toast'
import { ChartCard, ChartTooltip, axisProps, gridProps } from '@/components/shared/charts'
import { bestFocusTime, bestTimeLabel, BEST_TIME_MIN_SESSIONS } from '@/lib/stats'
import { dateKey, formatDuration, lastNDays } from '@/lib/date'
import { sum } from '@/lib/utils'
import { Stat } from './EveningReviewPage'

export default function WeeklyReviewPage() {
  const { settings } = useSettings()
  const navigate = useNavigate()
  const days = useMemo(() => lastNDays(7), [])
  const since = days[0].getTime()
  const sessions = useSessions(since)
  const allRecent = useSessions(startOfDay(addDays(new Date(), -13)).getTime())
  const distractions = useDistractions(since)
  const tasks = useTasks()
  const questions = settings.weeklyReview.questions
  const [answers, setAnswers] = useState<string[]>(() => questions.map(() => ''))
  const [saving, setSaving] = useState(false)

  const data = useMemo(() => {
    if (!sessions || !distractions || !tasks) return []
    return days.map((d) => {
      const k = dateKey(d)
      const s = sessions.filter((x) => dateKey(x.started_at) === k)
      return {
        label: format(d, 'EEE'),
        hours: Math.round((sum(s.map((x) => x.actual_duration)) / 3600) * 10) / 10,
        tasks: tasks.filter((t) => t.status === 'done' && t.completed_at && dateKey(t.completed_at) === k).length,
        distractions: distractions.filter((x) => dateKey(x.timestamp) === k).length,
      }
    })
  }, [days, sessions, distractions, tasks])

  if (!sessions || !distractions || !tasks || !allRecent) {
    return (
      <Page>
        <PageHeader title="Weekly review" />
        <LoadingBlock className="h-64" />
      </Page>
    )
  }

  const best = bestFocusTime(allRecent)
  const focusSec = sum(sessions.map((s) => s.actual_duration))
  const tasksDone = sum(data.map((d) => d.tasks))

  const save = async () => {
    setSaving(true)
    await db.reviews.put({
      id: uid(),
      type: 'weekly',
      date: dateKey(),
      answers: questions.map((q, i) => ({ question: q, answer: answers[i]?.trim() ?? '' })),
      next_priorities: [],
      stats: { focus_minutes: Math.round(focusSec / 60), tasks_done: tasksDone, distractions: distractions.length, sessions: sessions.length, best_time: best ? bestTimeLabel(best) : '' },
      created_at: Date.now(),
    })
    setSaving(false)
    toast('Weekly review saved', { kind: 'success' })
    navigate('/reviews')
  }

  return (
    <Page>
      <PageHeader title="Weekly review" subtitle={`${format(days[0], 'MMM d')} – ${format(days[6], 'MMM d')} · about 10 minutes`} />
      <div className="flex flex-col gap-d">
        <Card className="grid grid-cols-3 gap-3 !py-4">
          <Stat label="Focus time" value={formatDuration(focusSec)} />
          <Stat label="Tasks done" value={String(tasksDone)} />
          <Stat label={settings.modules.distractions ? 'Distractions' : 'Sessions'} value={String(settings.modules.distractions ? distractions.length : sessions.length)} />
        </Card>

        <ChartCard title="Focus hours per day">
          <MiniBar data={data} dataKey="hours" unit="h" />
        </ChartCard>
        <div className="grid gap-d sm:grid-cols-2">
          <ChartCard title="Tasks completed">
            <MiniBar data={data} dataKey="tasks" unit="" color="var(--success)" />
          </ChartCard>
          {settings.modules.distractions && (
            <ChartCard title="Distraction trend">
              <div className="h-40">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: -16 }}>
                    <CartesianGrid {...gridProps} />
                    <XAxis dataKey="label" {...axisProps} />
                    <YAxis {...axisProps} allowDecimals={false} width={40} />
                    <Tooltip content={({ active, payload, label }) => <ChartTooltip active={active} label={label} rows={payload?.length ? [{ name: 'Distractions', value: String(payload[0].value) }] : []} />} />
                    <Line type="monotone" dataKey="distractions" stroke="var(--warning)" strokeWidth={2} dot={{ r: 3, strokeWidth: 0, fill: 'var(--warning)' }} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </ChartCard>
          )}
        </div>

        <Card className="flex items-center gap-4">
          <span className="flex size-11 shrink-0 items-center justify-center rounded-2xl bg-accent-soft text-accent">
            <Clock className="size-5" />
          </span>
          <div>
            <div className="text-[15px] font-semibold">{best ? `Best focus time: ${bestTimeLabel(best)}` : 'Best focus time'}</div>
            <div className="text-[13px] text-muted">
              {best
                ? `${Math.round(best.rate * 100)}% of ${best.count} sessions started then were marked done (last 14 days).`
                : `Needs at least ${BEST_TIME_MIN_SESSIONS} sessions in the last 14 days.`}
            </div>
          </div>
        </Card>

        {questions.length > 0 && (
          <Card>
            <CardHeader title="Reflection" />
            <div className="space-y-4">
              {questions.map((q, i) => (
                <div key={q + i}>
                  <label className="mb-1.5 block text-sm font-medium">{q}</label>
                  <Textarea value={answers[i] ?? ''} onChange={(e) => setAnswers((a) => a.map((x, j) => (j === i ? e.target.value : x)))} placeholder="Write a few lines…" />
                </div>
              ))}
            </div>
          </Card>
        )}

        <div className="flex justify-end gap-2">
          <Button variant="ghost" onClick={() => navigate(-1)}>
            Cancel
          </Button>
          <Button variant="primary" size="lg" disabled={saving} onClick={() => void save()}>
            Save review
          </Button>
        </div>
      </div>
    </Page>
  )
}

function MiniBar({ data, dataKey, unit, color = 'var(--accent)' }: { data: Record<string, unknown>[]; dataKey: string; unit: string; color?: string }) {
  return (
    <div className="h-40">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 4, right: 4, bottom: 0, left: -16 }}>
          <CartesianGrid {...gridProps} />
          <XAxis dataKey="label" {...axisProps} />
          <YAxis {...axisProps} allowDecimals={false} width={40} />
          <Tooltip cursor={{ fill: 'var(--card-2)' }} content={({ active, payload, label }) => <ChartTooltip active={active} label={label} rows={payload?.length ? [{ name: dataKey === 'hours' ? 'Focus' : 'Tasks', value: `${payload[0].value}${unit ? ' ' + unit : ''}` }] : []} />} />
          <Bar dataKey={dataKey} fill={color} radius={[4, 4, 0, 0]} maxBarSize={32} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

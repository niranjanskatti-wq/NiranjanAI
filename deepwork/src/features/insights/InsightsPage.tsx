import { addDays, format, startOfWeek } from 'date-fns'
import { ChartColumn, Lightbulb, NotebookPen, TrendingUp, TriangleAlert } from 'lucide-react'
import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router'
import { Bar, BarChart, CartesianGrid, Cell, Line, LineChart, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useSettings } from '@/state/settings'
import { useDistractions, useProjects, useReasons, useSessions, useTasks } from '@/hooks/data'
import { Page } from '@/components/shared/Page'
import { Button } from '@/components/ui/button'
import { Segmented } from '@/components/ui/segmented'
import { EmptyState, LoadingBlock, PageHeader } from '@/components/ui/empty'
import { ChartCard, ChartTooltip, axisProps, gridProps, useCategorical } from '@/components/shared/charts'
import { toast } from '@/components/ui/toast'
import { loadDemoData } from '@/lib/demo'
import { computeInsightCards, heatmap, rangeDays, rangeStart, completionRate, type InsightCard } from '@/lib/stats'
import { DAY_SHORT, dateKey, formatHour } from '@/lib/date'
import type { RangeOption } from '@/lib/settings'
import type { Session } from '@/db/types'
import { cn, sum } from '@/lib/utils'

const RANGES: { value: RangeOption; label: string }[] = [
  { value: 7, label: '7d' },
  { value: 14, label: '14d' },
  { value: 30, label: '30d' },
  { value: 90, label: '90d' },
  { value: 0, label: 'All' },
]

export default function InsightsPage() {
  const { settings } = useSettings()
  const navigate = useNavigate()
  const [range, setRange] = useState<RangeOption>(settings.insights.defaultRange)
  const since = useMemo(() => rangeStart(range), [range])
  const allSessions = useSessions(0)
  const distractionsAll = useDistractions(since)
  const tasks = useTasks()
  const projects = useProjects()
  const reasons = useReasons()
  const [loadingDemo, setLoadingDemo] = useState(false)

  const sessions = useMemo(() => (allSessions ?? []).filter((s) => s.started_at >= since), [allSessions, since])
  const loading = !allSessions || !distractionsAll || !tasks || !projects || !reasons
  const charts = new Set(settings.insights.charts)
  const mod = settings.modules
  const showChart = (id: string, module?: keyof typeof mod) => charts.has(id as never) && (!module || mod[module])

  const cards = useMemo<InsightCard[]>(() => {
    if (loading || !mod.insightCards) return []
    return computeInsightCards({ settings, sessions, allSessions: allSessions!, distractions: distractionsAll!, tasks: tasks!, projects: projects!, range })
  }, [loading, mod.insightCards, settings, sessions, allSessions, distractionsAll, tasks, projects, range])

  const header = (
    <PageHeader
      title="Insights"
      subtitle="Calculated on this device from your own data."
      action={
        (mod.eveningReview || mod.weeklyReview) && (
          <Button variant="ghost" size="sm" onClick={() => navigate('/reviews')}>
            <NotebookPen /> Reviews
          </Button>
        )
      }
    />
  )

  if (loading) {
    return (
      <Page wide>
        {header}
        <div className="grid gap-4 md:grid-cols-2">
          {[0, 1, 2, 3].map((i) => (
            <LoadingBlock key={i} className="h-64" />
          ))}
        </div>
      </Page>
    )
  }

  const empty = sessions.length === 0

  return (
    <Page wide>
      {header}
      <div className="mb-5 flex items-center justify-between gap-3">
        <Segmented value={range} onChange={setRange} options={RANGES} />
        <span className="tabular hidden text-sm text-muted sm:block">
          {sessions.length} sessions · {Math.round(sum(sessions.map((s) => s.actual_duration)) / 360) / 10} h
        </span>
      </div>

      {empty ? (
        <div className="card">
          <EmptyState
            icon={<ChartColumn />}
            title={allSessions!.length ? 'No sessions in this range' : 'No data yet'}
            description={
              allSessions!.length
                ? 'Try a longer date range.'
                : 'Complete a few focus sessions and your charts and insights will appear here. Or preview with demo data.'
            }
            action={
              !allSessions!.length && (
                <Button
                  variant="subtle"
                  disabled={loadingDemo}
                  onClick={async () => {
                    setLoadingDemo(true)
                    await loadDemoData()
                    setLoadingDemo(false)
                    toast('Demo data loaded. Clear it any time in Settings → Data.', { kind: 'success' })
                  }}
                >
                  {loadingDemo ? 'Loading…' : 'Load demo data'}
                </Button>
              )
            }
          />
        </div>
      ) : (
        <>
          {mod.insightCards && (
            <div className="mb-4">
              {cards.length > 0 ? (
                <div className="grid gap-3 md:grid-cols-2">
                  {cards.map((c) => (
                    <InsightCardView key={c.id} card={c} />
                  ))}
                </div>
              ) : (
                <div className="card pad flex items-center gap-3 text-sm text-muted">
                  <Lightbulb className="size-4 shrink-0" />
                  Insight cards appear once there's enough data — usually after a week or two of sessions.
                </div>
              )}
            </div>
          )}
          <div className="grid gap-4 md:grid-cols-2">
            {showChart('focusHours') && <FocusHoursChart sessions={sessions} range={range} allSessions={allSessions!} />}
            {showChart('completionRate') && <CompletionChart sessions={sessions} range={range} allSessions={allSessions!} />}
            {showChart('distractionReasons', 'distractions') && <DistractionDonut distractions={distractionsAll!} reasonOrder={reasons!.map((r) => r.label)} />}
            {showChart('byProject', 'tasks') && <ProjectChart sessions={sessions} tasks={tasks!} projects={projects!} />}
            {showChart('heatmap') && (
              <div className="md:col-span-2">
                <Heatmap sessions={sessions} />
              </div>
            )}
          </div>
        </>
      )}
    </Page>
  )
}

function InsightCardView({ card }: { card: InsightCard }) {
  const Icon = card.tone === 'attention' ? TriangleAlert : card.tone === 'positive' ? TrendingUp : Lightbulb
  return (
    <div className="card pad flex gap-3">
      <span
        className={cn(
          'flex size-9 shrink-0 items-center justify-center rounded-xl',
          card.tone === 'attention' ? 'bg-warning/12 text-warning' : card.tone === 'positive' ? 'bg-success/12 text-success' : 'bg-accent-soft text-accent',
        )}
      >
        <Icon className="size-4" />
      </span>
      <div>
        <p className="text-[15px] font-medium leading-snug">{card.title}</p>
        <p className="mt-1 text-[13px] text-muted">{card.body}</p>
      </div>
    </div>
  )
}

/** Day buckets for short ranges, week buckets for long ones. */
function buckets(range: RangeOption, allSessions: Session[]) {
  const days = rangeDays(range, allSessions)
  if (days.length <= 31) return days.map((d) => ({ key: dateKey(d), start: d.getTime(), end: addDays(d, 1).getTime(), label: days.length <= 7 ? format(d, 'EEE') : format(d, 'd MMM') }))
  const weeks: { key: string; start: number; end: number; label: string }[] = []
  let w = startOfWeek(days[0], { weekStartsOn: 1 })
  const last = days[days.length - 1].getTime()
  while (w.getTime() <= last) {
    weeks.push({ key: dateKey(w), start: w.getTime(), end: addDays(w, 7).getTime(), label: format(w, 'd MMM') })
    w = addDays(w, 7)
  }
  return weeks
}

function FocusHoursChart({ sessions, range, allSessions }: { sessions: Session[]; range: RangeOption; allSessions: Session[] }) {
  const data = useMemo(
    () =>
      buckets(range, allSessions).map((b) => ({
        label: b.label,
        hours: Math.round((sum(sessions.filter((s) => s.started_at >= b.start && s.started_at < b.end).map((s) => s.actual_duration)) / 3600) * 10) / 10,
      })),
    [sessions, range, allSessions],
  )
  const total = sum(data.map((d) => d.hours))
  const weekly = data.length > 0 && rangeDays(range, allSessions).length > 31
  return (
    <ChartCard title="Focus hours" subtitle={`${Math.round(total * 10) / 10} h ${weekly ? 'by week' : 'by day'}`}>
      <div className="h-52">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 4, right: 4, bottom: 0, left: -8 }} barCategoryGap="22%">
            <CartesianGrid {...gridProps} />
            <XAxis dataKey="label" {...axisProps} interval="preserveStartEnd" minTickGap={12} />
            <YAxis {...axisProps} allowDecimals={false} width={44} />
            <Tooltip
              cursor={{ fill: 'var(--card-2)' }}
              content={({ active, payload, label }) => <ChartTooltip active={active} label={label} rows={payload?.length ? [{ name: 'Focus', value: `${payload[0].value} h` }] : []} />}
            />
            <Bar dataKey="hours" fill="var(--accent)" radius={[4, 4, 0, 0]} maxBarSize={28} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </ChartCard>
  )
}

function CompletionChart({ sessions, range, allSessions }: { sessions: Session[]; range: RangeOption; allSessions: Session[] }) {
  const data = useMemo(
    () =>
      buckets(range, allSessions).map((b) => {
        const list = sessions.filter((s) => s.started_at >= b.start && s.started_at < b.end)
        const r = completionRate(list)
        return { label: b.label, rate: r === null ? null : Math.round(r * 100), n: list.length }
      }),
    [sessions, range, allSessions],
  )
  const overall = completionRate(sessions)
  return (
    <ChartCard title="Completion rate" subtitle={`${overall === null ? '—' : Math.round(overall * 100) + '%'} of sessions marked done`}>
      <div className="h-52">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: -8 }}>
            <CartesianGrid {...gridProps} />
            <XAxis dataKey="label" {...axisProps} interval="preserveStartEnd" minTickGap={12} />
            <YAxis {...axisProps} domain={[0, 100]} ticks={[0, 50, 100]} tickFormatter={(v) => `${v}%`} width={44} />
            <Tooltip
              cursor={{ stroke: 'var(--muted)', strokeDasharray: '3 3' }}
              content={({ active, payload, label }) => {
                const p = payload?.[0]?.payload as { rate: number | null; n: number } | undefined
                return <ChartTooltip active={active} label={label} rows={p ? [{ name: 'Done', value: p.rate === null ? 'no sessions' : `${p.rate}% of ${p.n}` }] : []} />
              }}
            />
            <Line type="monotone" dataKey="rate" stroke="var(--accent)" strokeWidth={2} dot={data.length <= 31 ? { r: 3, strokeWidth: 0, fill: 'var(--accent)' } : false} activeDot={{ r: 5, stroke: 'var(--card)', strokeWidth: 2 }} connectNulls />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </ChartCard>
  )
}

function DistractionDonut({ distractions, reasonOrder }: { distractions: { reason: string }[]; reasonOrder: string[] }) {
  const palette = useCategorical()
  const data = useMemo(() => {
    const counts = new Map<string, number>()
    for (const d of distractions) counts.set(d.reason, (counts.get(d.reason) ?? 0) + 1)
    // Color follows the reason's configured order (entity), not its rank. Beyond 7, fold into "Other".
    const known = reasonOrder.filter((r) => counts.has(r))
    const unknown = [...counts.keys()].filter((r) => !reasonOrder.includes(r))
    const all = [...known, ...unknown]
    const main = all.slice(0, 7)
    const rest = all.slice(7)
    const rows = main.map((r) => ({ name: r, value: counts.get(r)!, color: palette[Math.max(0, reasonOrder.indexOf(r)) % 8] }))
    if (rest.length) rows.push({ name: 'Other reasons', value: sum(rest.map((r) => counts.get(r)!)), color: 'var(--muted)' })
    return rows
  }, [distractions, reasonOrder, palette])
  const total = sum(data.map((d) => d.value))
  return (
    <ChartCard title="Distractions by reason" subtitle={`${total} logged`}>
      {total === 0 ? (
        <p className="py-16 text-center text-sm text-muted">No distractions logged in this range.</p>
      ) : (
        <div className="flex items-center gap-4">
          <div className="relative h-44 w-44 shrink-0">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={data} dataKey="value" nameKey="name" innerRadius="64%" outerRadius="100%" paddingAngle={2} stroke="var(--card)" strokeWidth={2} isAnimationActive>
                  {data.map((d) => (
                    <Cell key={d.name} fill={d.color} />
                  ))}
                </Pie>
                <Tooltip content={({ active, payload }) => <ChartTooltip active={active} rows={payload?.length ? [{ name: String(payload[0].name), value: `${payload[0].value} (${Math.round((Number(payload[0].value) / total) * 100)}%)`, color: (payload[0].payload as { color: string }).color }] : []} />} />
              </PieChart>
            </ResponsiveContainer>
            <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
              <span className="tabular text-2xl font-semibold">{total}</span>
              <span className="text-xs text-muted">total</span>
            </div>
          </div>
          <ul className="min-w-0 flex-1 space-y-1.5">
            {data.map((d) => (
              <li key={d.name} className="flex items-center gap-2 text-[13px]">
                <span className="size-2.5 shrink-0 rounded-full" style={{ background: d.color }} />
                <span className="min-w-0 flex-1 truncate">{d.name}</span>
                <span className="tabular text-muted">{Math.round((d.value / total) * 100)}%</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </ChartCard>
  )
}

function ProjectChart({ sessions, tasks, projects }: { sessions: Session[]; tasks: { id: string; project_id: string | null }[]; projects: { id: string; name: string; color: string }[] }) {
  const data = useMemo(() => {
    const taskProject = new Map(tasks.map((t) => [t.id, t.project_id]))
    const m = new Map<string, { sessions: number; minutes: number }>()
    for (const s of sessions) {
      const pid = (s.task_id && taskProject.get(s.task_id)) || 'none'
      const v = m.get(pid) ?? { sessions: 0, minutes: 0 }
      v.sessions++
      v.minutes += s.actual_duration / 60
      m.set(pid, v)
    }
    return [...m.entries()]
      .map(([pid, v]) => {
        const p = projects.find((x) => x.id === pid)
        return { name: p?.name ?? 'No project', color: p?.color ?? 'var(--muted)', sessions: v.sessions, hours: Math.round((v.minutes / 60) * 10) / 10 }
      })
      .sort((a, b) => b.sessions - a.sessions)
  }, [sessions, tasks, projects])
  const max = Math.max(1, ...data.map((d) => d.sessions))
  return (
    <ChartCard title="Sessions by project" subtitle={`${data.length} ${data.length === 1 ? 'project' : 'projects'}`}>
      <ul className="space-y-3">
        {data.map((d) => (
          <li key={d.name} className="group" title={`${d.name}: ${d.sessions} sessions, ${d.hours} h`}>
            <div className="mb-1 flex items-center justify-between text-[13px]">
              <span className="truncate font-medium">{d.name}</span>
              <span className="tabular shrink-0 text-muted">
                {d.sessions} · {d.hours} h
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-border/60">
              <div className="h-full rounded-full transition-[width] duration-700" style={{ width: `${(d.sessions / max) * 100}%`, background: d.color }} />
            </div>
          </li>
        ))}
      </ul>
    </ChartCard>
  )
}

function Heatmap({ sessions }: { sessions: Session[] }) {
  const grid = useMemo(() => heatmap(sessions), [sessions])
  const max = Math.max(1, ...grid.flat())
  // Show only hours that ever have data, padded to a sensible working window.
  const used = grid[0].map((_, h) => grid.some((row) => row[h] > 0))
  let first = used.indexOf(true)
  let last = used.lastIndexOf(true)
  if (first === -1) {
    first = 8
    last = 18
  }
  first = Math.max(0, Math.min(first, 8))
  last = Math.min(23, Math.max(last, 18))
  const hours = Array.from({ length: last - first + 1 }, (_, i) => first + i)
  const order = [1, 2, 3, 4, 5, 6, 0]
  const [hover, setHover] = useState<{ d: number; h: number } | null>(null)
  return (
    <ChartCard
      title="Best hours"
      subtitle={hover ? `${DAY_SHORT[hover.d]} ${formatHour(hover.h)}: ${Math.round(grid[hover.d][hover.h])} focus minutes` : 'Focus minutes by weekday and hour'}
    >
      <div className="overflow-x-auto">
        <div className="inline-grid min-w-full gap-[3px]" style={{ gridTemplateColumns: `36px repeat(${hours.length}, minmax(18px, 1fr))` }}>
          <span />
          {hours.map((h) => (
            <span key={h} className="tabular text-center text-[10px] text-muted">
              {h % 3 === 0 ? formatHour(h).replace(' ', '') : ''}
            </span>
          ))}
          {order.map((d) => (
            <div key={d} className="contents">
              <span className="pr-1 text-[11px] leading-[22px] text-muted">{DAY_SHORT[d]}</span>
              {hours.map((h) => {
                const v = grid[d][h]
                const t = v / max
                return (
                  <button
                    key={h}
                    onMouseEnter={() => setHover({ d, h })}
                    onMouseLeave={() => setHover(null)}
                    onFocus={() => setHover({ d, h })}
                    onClick={() => setHover({ d, h })}
                    aria-label={`${DAY_SHORT[d]} ${formatHour(h)}: ${Math.round(v)} minutes`}
                    className="h-[22px] rounded-[4px] transition-transform hover:scale-110"
                    style={{ background: v > 0 ? `color-mix(in oklab, var(--accent) ${Math.round(15 + 85 * t)}%, var(--card-2))` : 'var(--card-2)' }}
                  />
                )
              })}
            </div>
          ))}
        </div>
      </div>
      <div className="mt-3 flex items-center justify-end gap-1.5 text-[11px] text-muted">
        Less
        {[0.15, 0.4, 0.65, 1].map((t) => (
          <span key={t} className="size-3 rounded-[3px]" style={{ background: `color-mix(in oklab, var(--accent) ${Math.round(t * 100)}%, var(--card-2))` }} />
        ))}
        More
      </div>
    </ChartCard>
  )
}


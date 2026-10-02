import { CircleCheck, Search, ShieldAlert } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { useSettings } from '@/state/settings'
import { Deepwork, type InstalledApp } from '@/lib/native'
import { resetSection } from '@/lib/settings'
import { Row, Section } from '@/components/ui/row'
import { Switch } from '@/components/ui/switch'
import { Segmented } from '@/components/ui/segmented'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Spinner } from '@/components/ui/empty'
import { cn } from '@/lib/utils'
import { ResetButton } from '../controls'

/** Android only: choose which apps are paused during focus sessions. */
export function BlockingSection() {
  const { settings, update } = useSettings()
  const b = settings.blocking
  const [serviceOn, setServiceOn] = useState<boolean | null>(null)
  const [apps, setApps] = useState<InstalledApp[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [q, setQ] = useState('')

  useEffect(() => {
    const check = () => void Deepwork.blockerStatus().then((s) => setServiceOn(s.serviceEnabled)).catch(() => setServiceOn(false))
    check()
    // Re-check when returning from Android's accessibility settings.
    const onVis = () => document.visibilityState === 'visible' && check()
    document.addEventListener('visibilitychange', onVis)
    return () => document.removeEventListener('visibilitychange', onVis)
  }, [])

  useEffect(() => {
    Deepwork.getInstalledApps()
      .then((r) => setApps(r.apps))
      .catch((e) => setError(e instanceof Error ? e.message : 'Could not list apps'))
  }, [])

  const selected = useMemo(() => new Set(b.packages), [b.packages])
  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase()
    const list = (apps ?? []).filter((a) => !needle || a.label.toLowerCase().includes(needle))
    // Chosen apps first, then alphabetical.
    return list.sort((x, y) => Number(selected.has(y.packageName)) - Number(selected.has(x.packageName)) || x.label.localeCompare(y.label))
  }, [apps, q, selected])

  const toggle = (app: InstalledApp) =>
    void update((s) => {
      const set = new Set(s.blocking.packages)
      if (set.has(app.packageName)) set.delete(app.packageName)
      else set.add(app.packageName)
      s.blocking.packages = [...set]
      s.blocking.labels = { ...s.blocking.labels, [app.packageName]: app.label }
    })

  return (
    <>
      <p className="mb-4 text-sm text-muted">
        While a focus session is running, opening a paused app shows a “Stay with it” screen instead. Pausing or ending the session lifts the block. Your phone, keyboard and home screen are never blocked.
      </p>

      {serviceOn === false && (
        <div className="card pad mb-6 flex items-start gap-3 border-warning/40">
          <ShieldAlert className="mt-0.5 size-5 shrink-0 text-warning" />
          <div className="min-w-0 flex-1">
            <p className="font-medium">Turn on the blocking permission</p>
            <p className="mt-0.5 text-[13px] text-muted">
              Android needs you to allow Deepwork under Accessibility. It only sees which app is opened during a session, never what's on screen. Tap below, choose <b>Deepwork focus blocking</b> (it may be under “Installed apps” or “Downloaded apps”) and switch it on.
            </p>
            <p className="mt-2 text-[13px] text-muted">
              If Android says the setting is restricted: open Android Settings → Apps → Deepwork → ⋮ (top right) → <b>Allow restricted settings</b>, then try again.
            </p>
            <Button variant="primary" size="sm" className="mt-3" onClick={() => void Deepwork.openBlockerSettings()}>
              Open Accessibility settings
            </Button>
          </div>
        </div>
      )}

      <Section title="Blocking" action={<ResetButton label="App blocking" onReset={() => update((s) => resetSection(s, 'blocking'))} />}>
        <Row label="Block apps during focus sessions">
          <Switch checked={settings.modules.appBlocking} onCheckedChange={(v) => void update((s) => void (s.modules.appBlocking = v))} aria-label="Block apps during focus sessions" />
        </Row>
        <Row label="Permission" description={serviceOn === null ? 'Checking…' : serviceOn ? 'Allowed' : 'Not allowed yet'}>
          {serviceOn ? <CircleCheck className="size-5 text-success" /> : null}
        </Row>
        <Row label="Mode" description={b.mode === 'block' ? 'Only the apps you pick are paused.' : 'Every app is paused except the ones you pick.'} stacked>
          <Segmented
            value={b.mode}
            onChange={(v) => void update((s) => void (s.blocking.mode = v))}
            options={[
              { value: 'block', label: 'Block chosen apps' },
              { value: 'allow', label: 'Allow only chosen apps' },
            ]}
          />
        </Row>
        <Row label="Log attempts as distractions" description="Trying to open a paused app is added to the session as a “Blocked app” distraction.">
          <Switch checked={b.logAttempts} onCheckedChange={(v) => void update((s) => void (s.blocking.logAttempts = v))} aria-label="Log attempts" />
        </Row>
      </Section>

      <Section title={b.mode === 'block' ? `Apps to pause (${b.packages.length})` : `Apps to allow (${b.packages.length})`}>
        <div className="relative my-3">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted" />
          <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search apps" className="pl-9" />
        </div>
        {error && <p className="py-4 text-sm text-warning">{error}</p>}
        {!apps && !error && (
          <div className="flex justify-center py-8">
            <Spinner />
          </div>
        )}
        <ul className="-mx-1 pb-2">
          {filtered.map((a) => {
            const on = selected.has(a.packageName)
            return (
              <li key={a.packageName}>
                <button onClick={() => toggle(a)} className={cn('flex w-full items-center gap-3 rounded-[12px] px-1 py-2 text-left transition-colors', on && 'bg-accent-soft/60')}>
                  {a.icon ? <img src={a.icon} alt="" className="size-9 shrink-0 rounded-[10px]" /> : <span className="size-9 shrink-0 rounded-[10px] bg-card-2" />}
                  <span className="min-w-0 flex-1 truncate text-sm font-medium">{a.label}</span>
                  <Switch checked={on} onCheckedChange={() => toggle(a)} aria-label={`${b.mode === 'block' ? 'Pause' : 'Allow'} ${a.label}`} />
                </button>
              </li>
            )
          })}
        </ul>
      </Section>
    </>
  )
}

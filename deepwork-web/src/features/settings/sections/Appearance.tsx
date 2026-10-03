import { Check, Monitor, Moon, Sun } from 'lucide-react'
import { useSettings } from '@/state/settings'
import { ACCENT_PRESETS, HOME_SECTIONS, resetSection } from '@/lib/settings'
import { Row, Section } from '@/components/ui/row'
import { Segmented } from '@/components/ui/segmented'
import { Switch } from '@/components/ui/switch'
import { contrastText, cn } from '@/lib/utils'
import { ResetButton, SortableList } from '../controls'

export function AppearanceSection() {
  const { settings, update } = useSettings()
  const a = settings.appearance
  return (
    <>
      <Section title="Theme" action={<ResetButton label="Appearance" onReset={() => update((s) => resetSection(s, 'appearance'))} />}>
        <div className="grid grid-cols-3 gap-2 py-4">
          {(
            [
              { v: 'dark', label: 'Dark', icon: Moon },
              { v: 'light', label: 'Light', icon: Sun },
              { v: 'system', label: 'System', icon: Monitor },
            ] as const
          ).map((t) => (
            <button
              key={t.v}
              onClick={() => void update((s) => void (s.appearance.theme = t.v))}
              className={cn(
                'flex flex-col items-center gap-2 rounded-[14px] border py-4 text-sm font-medium transition-all active:scale-95',
                a.theme === t.v ? 'border-accent/60 bg-accent-soft text-accent' : 'border-border hover:bg-card-2',
              )}
            >
              <t.icon className="size-5" />
              {t.label}
            </button>
          ))}
        </div>
        <Row label="Accent color" stacked>
          <div className="flex flex-wrap items-center gap-2.5">
            {ACCENT_PRESETS.map((c) => (
              <button
                key={c}
                onClick={() => void update((s) => void (s.appearance.accent = c))}
                className="flex size-8 items-center justify-center rounded-full transition-transform hover:scale-110 active:scale-95"
                style={{ background: c, boxShadow: a.accent.toLowerCase() === c.toLowerCase() ? `0 0 0 2px var(--card), 0 0 0 4px ${c}` : undefined }}
                aria-label={`Accent ${c}`}
              >
                {a.accent.toLowerCase() === c.toLowerCase() && <Check className="size-4" style={{ color: contrastText(c) }} />}
              </button>
            ))}
            <label className="relative flex h-8 cursor-pointer items-center gap-2 rounded-full border border-border pl-1 pr-3 text-[13px] font-medium" title="Custom color">
              <span className="size-6 rounded-full" style={{ background: a.accent }} />
              Custom
              <input type="color" value={a.accent} onChange={(e) => void update((s) => void (s.appearance.accent = e.target.value))} className="absolute inset-0 size-full cursor-pointer opacity-0" aria-label="Custom accent color" />
            </label>
          </div>
        </Row>
      </Section>

      <Section title="Text & layout">
        <Row label="Font">
          <Segmented
            size="sm"
            value={a.font}
            onChange={(v) => void update((s) => void (s.appearance.font = v))}
            options={[
              { value: 'inter', label: <span style={{ fontFamily: 'Inter Variable' }}>Inter</span> },
              { value: 'geist', label: <span style={{ fontFamily: 'Geist Variable' }}>Geist</span> },
              { value: 'serif', label: <span style={{ fontFamily: 'Source Serif 4 Variable' }}>Serif</span> },
            ]}
          />
        </Row>
        <Row label="Text size">
          <Segmented
            size="sm"
            value={a.textSize}
            onChange={(v) => void update((s) => void (s.appearance.textSize = v))}
            options={[
              { value: 'small', label: 'Small' },
              { value: 'medium', label: 'Medium' },
              { value: 'large', label: 'Large' },
            ]}
          />
        </Row>
        <Row label="Density">
          <Segmented
            size="sm"
            value={a.density}
            onChange={(v) => void update((s) => void (s.appearance.density = v))}
            options={[
              { value: 'comfortable', label: 'Comfortable' },
              { value: 'compact', label: 'Compact' },
            ]}
          />
        </Row>
        <Row label="Animations" description={a.animations === 'full' ? 'Follows your system reduced-motion setting.' : undefined}>
          <Segmented
            size="sm"
            value={a.animations}
            onChange={(v) => void update((s) => void (s.appearance.animations = v))}
            options={[
              { value: 'full', label: 'Full' },
              { value: 'reduced', label: 'Reduced' },
              { value: 'off', label: 'Off' },
            ]}
          />
        </Row>
      </Section>

      <Section title="Home layout" description="Drag to reorder Today's sections. Sections for modules that are off stay hidden.">
        <div className="py-2">
          <SortableList
            items={a.homeLayout}
            onReorder={(next) => void update((s) => void (s.appearance.homeLayout = next))}
            render={(item, handle) => {
              const def = HOME_SECTIONS[item.id]
              const moduleOff = def.module && !settings.modules[def.module]
              return (
                <div className="flex items-center gap-2 py-1">
                  {handle}
                  <span className={cn('flex-1 text-sm', moduleOff && 'text-muted')}>
                    {def.label}
                    {moduleOff && <span className="ml-1.5 text-xs">(module off)</span>}
                  </span>
                  <Switch
                    checked={item.visible}
                    onCheckedChange={(v) =>
                      void update((s) => {
                        const it = s.appearance.homeLayout.find((x) => x.id === item.id)
                        if (it) it.visible = v
                      })
                    }
                    aria-label={`Show ${def.label}`}
                  />
                </div>
              )
            }}
          />
        </div>
      </Section>
    </>
  )
}

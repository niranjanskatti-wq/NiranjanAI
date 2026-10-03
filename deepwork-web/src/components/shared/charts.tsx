import type { ReactNode } from 'react'
import { useResolvedTheme } from '@/hooks/appearance'
import { useSettings } from '@/state/settings'

// Validated categorical palette (fixed order, never cycled) — light and dark steps.
const CAT_LIGHT = ['#2a78d6', '#eb6834', '#1baf7a', '#eda100', '#e87ba4', '#008300', '#4a3aa7', '#e34948']
const CAT_DARK = ['#3987e5', '#d95926', '#199e70', '#c98500', '#d55181', '#008300', '#9085e9', '#e66767']

export function useCategorical() {
  const { settings } = useSettings()
  const theme = useResolvedTheme(settings.appearance.theme)
  return theme === 'dark' ? CAT_DARK : CAT_LIGHT
}

export const axisProps = {
  tickLine: false,
  axisLine: false,
  tick: { fill: 'var(--muted)', fontSize: 11 },
} as const

export const gridProps = { stroke: 'var(--border)', strokeOpacity: 0.7, vertical: false } as const

/** Tooltip body styled with app tokens. Text uses ink tokens; a swatch carries identity. */
export function ChartTooltip({
  active,
  label,
  rows,
}: {
  active?: boolean
  label?: ReactNode
  rows: { name: string; value: string; color?: string }[]
}) {
  if (!active || rows.length === 0) return null
  return (
    <div className="glass rounded-[12px] border border-border px-3 py-2 text-xs shadow-xl">
      {label != null && <div className="mb-1 font-medium text-fg">{label}</div>}
      {rows.map((r) => (
        <div key={r.name} className="flex items-center gap-2 text-muted">
          {r.color && <span className="size-2 rounded-full" style={{ background: r.color }} />}
          <span>{r.name}</span>
          <span className="tabular ml-auto pl-3 font-semibold text-fg">{r.value}</span>
        </div>
      ))}
    </div>
  )
}

export function ChartCard({ title, subtitle, children, footer }: { title: string; subtitle?: ReactNode; children: ReactNode; footer?: ReactNode }) {
  return (
    <section className="card pad">
      <div className="mb-4">
        <h3 className="text-[15px] font-semibold tracking-tight">{title}</h3>
        {subtitle && <p className="mt-0.5 text-[13px] text-muted">{subtitle}</p>}
      </div>
      {children}
      {footer}
    </section>
  )
}

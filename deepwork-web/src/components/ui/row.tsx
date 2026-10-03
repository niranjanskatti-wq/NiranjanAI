import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

/** A labelled settings row with a control on the right. */
export function Row({
  label,
  description,
  children,
  className,
  stacked,
}: {
  label: ReactNode
  description?: ReactNode
  children?: ReactNode
  className?: string
  stacked?: boolean
}) {
  return (
    <div
      className={cn(
        'flex gap-3 border-b border-border/70 py-3.5 last:border-b-0',
        stacked ? 'flex-col' : 'items-center justify-between',
        className,
      )}
    >
      <div className="min-w-0">
        <div className="text-[14px] font-medium">{label}</div>
        {description && <div className="mt-0.5 text-[13px] text-muted">{description}</div>}
      </div>
      {children && <div className={cn(stacked ? 'w-full' : 'shrink-0')}>{children}</div>}
    </div>
  )
}

export function Section({ title, description, children, action }: { title: string; description?: ReactNode; children: ReactNode; action?: ReactNode }) {
  return (
    <section className="mb-6">
      <div className="mb-2 flex items-end justify-between gap-3 px-1">
        <div>
          <h2 className="text-[13px] font-semibold uppercase tracking-wider text-muted">{title}</h2>
          {description && <p className="mt-0.5 text-[13px] text-muted">{description}</p>}
        </div>
        {action}
      </div>
      <div className="card px-[var(--pad)] py-0.5">{children}</div>
    </section>
  )
}

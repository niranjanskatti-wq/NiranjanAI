import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: {
  icon?: ReactNode
  title: string
  description?: ReactNode
  action?: ReactNode
  className?: string
}) {
  return (
    <div className={cn('flex flex-col items-center justify-center px-6 py-10 text-center', className)}>
      {icon && <div className="mb-3 flex size-11 items-center justify-center rounded-2xl bg-card-2 text-muted [&_svg]:size-5">{icon}</div>}
      <p className="text-[15px] font-medium">{title}</p>
      {description && <p className="mt-1 max-w-xs text-sm text-muted">{description}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  )
}

export function Spinner({ className }: { className?: string }) {
  return <div className={cn('size-5 animate-spin rounded-full border-2 border-border border-t-accent', className)} />
}

export function LoadingBlock({ className }: { className?: string }) {
  return <div className={cn('animate-pulse rounded-2xl bg-card-2', className)} />
}

export function PageHeader({ title, subtitle, action }: { title: ReactNode; subtitle?: ReactNode; action?: ReactNode }) {
  return (
    <div className="mb-6 flex items-end justify-between gap-4">
      <div className="min-w-0">
        <h1 className="text-[28px] font-semibold leading-tight tracking-tight sm:text-[32px]">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-muted">{subtitle}</p>}
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </div>
  )
}

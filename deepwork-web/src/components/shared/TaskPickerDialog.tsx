import { Plus, Search } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { Dialog } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { ProjectDot } from '@/components/ui/chip'
import { createTask, useProjects, useTasks } from '@/hooks/data'
import type { Task } from '@/db/types'
import { cn } from '@/lib/utils'

/** Choose an open task (or create one inline). */
export function TaskPickerDialog({
  open,
  onOpenChange,
  title,
  description,
  onPick,
  exclude = [],
  allowNone,
  noneLabel = 'No task',
}: {
  open: boolean
  onOpenChange: (o: boolean) => void
  title: string
  description?: string
  onPick: (task: Task | null) => void
  exclude?: string[]
  allowNone?: boolean
  noneLabel?: string
}) {
  const tasks = useTasks()
  const projects = useProjects()
  const [q, setQ] = useState('')
  useEffect(() => {
    if (open) setQ('')
  }, [open])
  const projectMap = new Map((projects ?? []).map((p) => [p.id, p]))
  const list = useMemo(() => {
    const ex = new Set(exclude)
    const needle = q.trim().toLowerCase()
    return (tasks ?? []).filter((t) => t.status !== 'done' && !ex.has(t.id) && (!needle || t.title.toLowerCase().includes(needle)))
  }, [tasks, exclude, q])

  const createAndPick = async () => {
    const title = q.trim()
    if (!title) return
    const t = await createTask({ title })
    onPick(t)
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange} title={title} description={description}>
      <form
        className="relative mb-3"
        onSubmit={(e) => {
          e.preventDefault()
          if (list.length === 1) {
            onPick(list[0])
            onOpenChange(false)
          } else void createAndPick()
        }}
      >
        <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted" />
        <Input autoFocus value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search or create a task" className="pl-9" />
      </form>
      <div className="max-h-[46dvh] space-y-1 overflow-y-auto pb-3">
        {allowNone && (
          <PickRow
            onClick={() => {
              onPick(null)
              onOpenChange(false)
            }}
            title={noneLabel}
            muted
          />
        )}
        {list.map((t) => {
          const p = t.project_id ? projectMap.get(t.project_id) : undefined
          return (
            <PickRow
              key={t.id}
              onClick={() => {
                onPick(t)
                onOpenChange(false)
              }}
              title={t.title}
              subtitle={p?.name}
              color={p?.color}
            />
          )
        })}
        {q.trim() && !list.some((t) => t.title.toLowerCase() === q.trim().toLowerCase()) && (
          <Button variant="ghost" className="w-full justify-start text-accent" onClick={() => void createAndPick()}>
            <Plus /> Create “{q.trim()}”
          </Button>
        )}
        {!q && list.length === 0 && <p className="py-6 text-center text-sm text-muted">No open tasks. Type above to create one.</p>}
      </div>
    </Dialog>
  )
}

function PickRow({ onClick, title, subtitle, color, muted }: { onClick: () => void; title: string; subtitle?: string; color?: string; muted?: boolean }) {
  return (
    <button onClick={onClick} className="flex w-full items-center gap-3 rounded-[12px] px-3 py-2.5 text-left transition-colors hover:bg-card-2 active:scale-[0.99]">
      <span className={cn('min-w-0 flex-1 truncate text-sm font-medium', muted && 'text-muted')}>{title}</span>
      {subtitle && (
        <span className="flex shrink-0 items-center gap-1.5 text-xs text-muted">
          {color && <ProjectDot color={color} />}
          {subtitle}
        </span>
      )}
    </button>
  )
}

import { Flag, GripVertical, Minus, Play, Plus, Sun, Trash2, X } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, uid } from '@/db'
import type { Task, TaskStatus } from '@/db/types'
import { useSettings } from '@/state/settings'
import { addToPriorities, deleteTask, removeFromPriorities, useProjects } from '@/hooks/data'
import { Dialog } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input, Label, Select } from '@/components/ui/input'
import { Segmented } from '@/components/ui/segmented'
import { Switch } from '@/components/ui/switch'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { ProgressBar } from '@/components/ui/progress'
import { todayKey } from '@/lib/date'
import { cn } from '@/lib/utils'

export function TaskSheet({ task, onClose, spent }: { task: Task | null; onClose: () => void; spent: number }) {
  const { settings } = useSettings()
  const navigate = useNavigate()
  const projects = useProjects()
  const [title, setTitle] = useState('')
  const subtasks = useLiveQuery(() => (task ? db.subtasks.where('task_id').equals(task.id).sortBy('order') : []), [task?.id])
  const [newSub, setNewSub] = useState('')
  const fields = new Set(settings.tasks.visibleFields)
  const today = todayKey()

  useEffect(() => {
    if (task) setTitle(task.title)
    setNewSub('')
    // Only reset when a different task is opened.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [task?.id])

  if (!task) return <Dialog open={false} onOpenChange={() => {}} title="" />

  const set = (patch: Partial<Task>) => db.tasks.update(task.id, patch)
  const setStatus = (status: TaskStatus) => set({ status, completed_at: status === 'done' ? Date.now() : null })
  const isPrio = task.is_priority && task.priority_date === today

  const addSub = async () => {
    const t = newSub.trim()
    if (!t) return
    await db.subtasks.put({ id: uid(), task_id: task.id, title: t, done: false, order: (subtasks?.length ?? 0) + 1 })
    setNewSub('')
  }

  const moveSub = async (i: number, dir: -1 | 1) => {
    if (!subtasks) return
    const j = i + dir
    if (j < 0 || j >= subtasks.length) return
    await db.transaction('rw', db.subtasks, async () => {
      await db.subtasks.update(subtasks[i].id, { order: subtasks[j].order })
      await db.subtasks.update(subtasks[j].id, { order: subtasks[i].order })
    })
  }

  return (
    <Dialog
      open={!!task}
      onOpenChange={(o) => {
        if (!o) {
          if (title.trim() && title.trim() !== task.title) void set({ title: title.trim() })
          onClose()
        }
      }}
      title="Task"
      footer={
        <>
          <Button
            variant="danger-ghost"
            className="mr-auto"
            onClick={async () => {
              if (await confirmDialog({ title: `Delete “${task.title}”?`, description: 'Subtasks are deleted too. Logged sessions are kept.', confirmLabel: 'Delete', danger: true })) {
                await deleteTask(task.id)
                onClose()
                toast('Task deleted')
              }
            }}
          >
            <Trash2 /> Delete
          </Button>
          {task.status !== 'done' && (
            <Button
              variant="primary"
              onClick={() => {
                if (title.trim() && title.trim() !== task.title) void set({ title: title.trim() })
                onClose()
                navigate(`/focus?task=${task.id}`)
              }}
            >
              <Play className="fill-current" /> Focus
            </Button>
          )}
        </>
      }
    >
      <div className="space-y-4 pb-3">
        <Input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onBlur={() => title.trim() && title.trim() !== task.title && void set({ title: title.trim() })}
          className="h-12 text-base font-medium"
          aria-label="Title"
        />

        {fields.has('status') && (
          <Segmented
            value={task.status}
            onChange={(v) => void setStatus(v)}
            options={[
              { value: 'todo', label: 'To do' },
              { value: 'in_progress', label: 'In progress' },
              { value: 'done', label: 'Done' },
            ]}
          />
        )}

        <div className="grid grid-cols-2 gap-3">
          {fields.has('project') && (
            <div>
              <Label>Project</Label>
              <Select value={task.project_id ?? ''} onChange={(e) => void set({ project_id: e.target.value || null })}>
                <option value="">None</option>
                {(projects ?? []).map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </Select>
            </div>
          )}
          {fields.has('dueDate') && (
            <div>
              <Label>Due date</Label>
              <div className="flex gap-1">
                <Input type="date" value={task.due_date ?? ''} onChange={(e) => void set({ due_date: e.target.value || null })} />
                {task.due_date && (
                  <Button variant="ghost" size="icon" onClick={() => void set({ due_date: null })} aria-label="Clear due date">
                    <X />
                  </Button>
                )}
              </div>
            </div>
          )}
        </div>

        {(fields.has('estimate') || fields.has('sessions')) && (
          <div className="flex items-center justify-between gap-4 rounded-[12px] bg-card-2/60 px-3 py-2.5">
            <div className="min-w-0 flex-1">
              <div className="text-sm font-medium">Sessions</div>
              <div className="tabular text-xs text-muted">
                {spent} spent{task.estimate_sessions ? ` of ${task.estimate_sessions} estimated` : ''}
              </div>
              {task.estimate_sessions ? <ProgressBar className="mt-1.5" value={spent / task.estimate_sessions} color={spent > task.estimate_sessions ? 'var(--warning)' : undefined} /> : null}
            </div>
            {fields.has('estimate') && (
              <div className="flex items-center gap-1">
                <Button variant="ghost" size="icon-sm" onClick={() => void set({ estimate_sessions: Math.max(0, (task.estimate_sessions ?? 0) - 1) || null })} aria-label="Decrease estimate">
                  <Minus />
                </Button>
                <span className="tabular w-6 text-center text-sm font-semibold">{task.estimate_sessions ?? 0}</span>
                <Button variant="ghost" size="icon-sm" onClick={() => void set({ estimate_sessions: Math.min(50, (task.estimate_sessions ?? 0) + 1) })} aria-label="Increase estimate">
                  <Plus />
                </Button>
              </div>
            )}
          </div>
        )}

        <div className="flex flex-col gap-1">
          {fields.has('flag') && (
            <div className="flex items-center justify-between rounded-[12px] px-1 py-1.5">
              <span className="flex items-center gap-2 text-sm">
                <Flag className={cn('size-4', task.flagged ? 'fill-warning text-warning' : 'text-muted')} /> High priority
              </span>
              <Switch checked={task.flagged} onCheckedChange={(v) => void set({ flagged: v })} aria-label="High priority" />
            </div>
          )}
          {settings.modules.priorities && task.status !== 'done' && (
            <div className="flex items-center justify-between rounded-[12px] px-1 py-1.5">
              <span className="flex items-center gap-2 text-sm">
                <Sun className="size-4 text-muted" /> In today’s {settings.priorities.label.toLowerCase()}
              </span>
              <Switch
                checked={isPrio}
                onCheckedChange={async (v) => {
                  if (v) {
                    const ok = await addToPriorities(task.id, settings.priorities.count)
                    if (!ok) toast(`${settings.priorities.label} are full (${settings.priorities.count}).`)
                  } else await removeFromPriorities(task.id)
                }}
                aria-label="In today's priorities"
              />
            </div>
          )}
        </div>

        {settings.modules.subtasks && (
          <div>
            <Label>Checklist</Label>
            <ul className="space-y-1">
              {(subtasks ?? []).map((s, i) => (
                <li key={s.id} className="group flex items-center gap-2 rounded-[10px] px-1 py-1 hover:bg-card-2/60">
                  <div className="flex flex-col">
                    <button className="text-muted/60 hover:text-fg disabled:opacity-20" disabled={i === 0} onClick={() => void moveSub(i, -1)} aria-label="Move up">
                      <GripVertical className="size-3.5 rotate-90" />
                    </button>
                  </div>
                  <button
                    onClick={() => void db.subtasks.update(s.id, { done: !s.done })}
                    className={cn('flex size-[18px] shrink-0 items-center justify-center rounded-[6px] border-2 transition-colors', s.done ? 'border-accent bg-accent' : 'border-border')}
                    aria-label={s.done ? 'Uncheck' : 'Check'}
                  >
                    {s.done && <svg viewBox="0 0 12 12" className="size-2.5 text-accent-fg"><path d="M2 6.5l2.5 2.5L10 3.5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg>}
                  </button>
                  <input
                    defaultValue={s.title}
                    onBlur={(e) => e.target.value.trim() && e.target.value !== s.title && void db.subtasks.update(s.id, { title: e.target.value.trim() })}
                    className={cn('min-w-0 flex-1 bg-transparent text-sm focus:outline-none', s.done && 'text-muted line-through')}
                    aria-label="Subtask title"
                  />
                  <button className="text-muted opacity-60 hover:text-danger md:opacity-0 md:group-hover:opacity-100" onClick={() => void db.subtasks.delete(s.id)} aria-label="Delete subtask">
                    <X className="size-4" />
                  </button>
                </li>
              ))}
            </ul>
            <form
              className="mt-1.5 flex gap-2"
              onSubmit={(e) => {
                e.preventDefault()
                void addSub()
              }}
            >
              <Input value={newSub} onChange={(e) => setNewSub(e.target.value)} placeholder="Add a step" className="h-9" />
              <Button type="submit" variant="secondary" size="icon" className="size-9" disabled={!newSub.trim()} aria-label="Add subtask">
                <Plus />
              </Button>
            </form>
          </div>
        )}
      </div>
    </Dialog>
  )
}

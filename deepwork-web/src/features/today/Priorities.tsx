import { useSortable, SortableContext, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { AnimatePresence, motion } from 'framer-motion'
import { Check, GripVertical, Play, Plus, Target, Undo2, X } from 'lucide-react'
import { useState } from 'react'
import { useNavigate } from 'react-router'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/db'
import type { Project, Session, Task } from '@/db/types'
import { useSettings } from '@/state/settings'
import { addToPriorities, removeFromPriorities, setTaskDone } from '@/hooks/data'
import { Card, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { ProjectDot } from '@/components/ui/chip'
import { EmptyState } from '@/components/ui/empty'
import { toast } from '@/components/ui/toast'
import { TaskPickerDialog } from '@/components/shared/TaskPickerDialog'
import { todayKey } from '@/lib/date'
import { cn, pluralize } from '@/lib/utils'

export function Priorities({ priorities, projects, sessions }: { priorities: Task[]; projects: Project[]; sessions: Session[] }) {
  const { settings } = useSettings()
  const [pickerOpen, setPickerOpen] = useState(false)
  const limit = settings.priorities.count
  const today = todayKey()
  const projectMap = new Map(projects.map((p) => [p.id, p]))
  const sessionsByTask = new Map<string, number>()
  for (const s of sessions) if (s.task_id && s.result !== 'interrupted') sessionsByTask.set(s.task_id, (sessionsByTask.get(s.task_id) ?? 0) + 1)

  // Unfinished priorities from the most recent earlier day, offered for carry-over.
  const carry = useLiveQuery(async () => {
    const prev = await db.tasks.where('priority_date').below(today).reverse().sortBy('priority_date')
    const open = prev.filter((t) => t.is_priority && t.status !== 'done')
    if (!open.length) return []
    const latest = open[0].priority_date
    return open.filter((t) => t.priority_date === latest)
  }, [today])

  const doneCount = priorities.filter((t) => t.status === 'done').length
  const room = limit - priorities.length

  const carryOver = async () => {
    if (!carry?.length) return
    let added = 0
    for (const t of carry.slice(0, Math.max(0, room))) if (await addToPriorities(t.id, limit)) added++
    toast(added ? `Carried over ${pluralize(added, 'priority', 'priorities')}.` : 'Your priorities are already full.', { kind: added ? 'success' : 'info' })
  }

  return (
    <Card>
      <CardHeader
        icon={<Target />}
        title={settings.priorities.label}
        subtitle={priorities.length ? `${doneCount} of ${priorities.length} done` : undefined}
        action={
          room > 0 ? (
            <Button variant="ghost" size="sm" onClick={() => setPickerOpen(true)}>
              <Plus /> Add
            </Button>
          ) : undefined
        }
      />
      {priorities.length === 0 ? (
        <EmptyState
          className="py-6"
          title="What matters most today?"
          description={`Pick up to ${limit}. Fewer is usually better.`}
          action={
            <div className="flex flex-wrap justify-center gap-2">
              <Button variant="subtle" size="sm" onClick={() => setPickerOpen(true)}>
                <Plus /> Choose priorities
              </Button>
              {!!carry?.length && (
                <Button variant="ghost" size="sm" onClick={() => void carryOver()}>
                  <Undo2 /> Carry over {carry.length}
                </Button>
              )}
            </div>
          }
        />
      ) : (
        <>
          <SortableContext items={priorities.map((t) => `prio:${t.id}`)} strategy={verticalListSortingStrategy}>
            <ul className="space-y-1">
              <AnimatePresence initial={false}>
                {priorities.map((t, i) => (
                  <PriorityRow
                    key={t.id}
                    task={t}
                    index={i}
                    project={t.project_id ? projectMap.get(t.project_id) : undefined}
                    spent={sessionsByTask.get(t.id) ?? 0}
                  />
                ))}
              </AnimatePresence>
            </ul>
          </SortableContext>
          {!!carry?.length && room > 0 && (
            <button className="mt-3 inline-flex items-center gap-1.5 text-[13px] font-medium text-muted hover:text-fg" onClick={() => void carryOver()}>
              <Undo2 className="size-3.5" /> Carry over {pluralize(carry.length, 'unfinished priority', 'unfinished priorities')}
            </button>
          )}
        </>
      )}
      <TaskPickerDialog
        open={pickerOpen}
        onOpenChange={setPickerOpen}
        title={`Add to ${settings.priorities.label.toLowerCase()}`}
        description={`${priorities.length} of ${limit} chosen`}
        exclude={priorities.map((t) => t.id)}
        onPick={async (t) => {
          if (!t) return
          const ok = await addToPriorities(t.id, limit)
          if (!ok) toast(`You can have up to ${limit}. Change this in Settings.`)
        }}
      />
    </Card>
  )
}

function PriorityRow({ task, index, project, spent }: { task: Task; index: number; project?: Project; spent: number }) {
  const navigate = useNavigate()
  const { settings } = useSettings()
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id: `prio:${task.id}`, data: { taskId: task.id, title: task.title } })
  const done = task.status === 'done'
  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, height: 0 }}
      ref={setNodeRef}
      style={{ transform: CSS.Translate.toString(transform), transition }}
      className={cn('group flex items-center gap-2 rounded-[12px] py-1.5 pr-1', isDragging && 'z-10 opacity-40')}
    >
      <button
        className="flex h-9 w-6 shrink-0 cursor-grab touch-none items-center justify-center text-muted/60 hover:text-muted active:cursor-grabbing"
        aria-label="Drag to reorder or schedule"
        {...attributes}
        {...listeners}
      >
        <GripVertical className="size-4" />
      </button>
      <button
        onClick={() => void setTaskDone(task.id, !done)}
        className={cn(
          'flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 transition-all active:scale-90',
          done ? 'border-success bg-success text-bg' : 'border-border hover:border-accent',
        )}
        aria-label={done ? 'Mark not done' : 'Mark done'}
      >
        {done && <Check className="size-3.5" strokeWidth={3} />}
      </button>
      <button
        className="min-w-0 flex-1 text-left"
        onClick={() => !done && navigate(`/focus?task=${task.id}`)}
        title={done ? undefined : 'Start focus on this task'}
      >
        <div className={cn('flex items-center gap-2 truncate text-[15px] font-medium', done && 'text-muted line-through decoration-muted/60')}>
          <span className="tabular text-xs text-muted">{index + 1}</span>
          <span className="truncate">{task.title}</span>
        </div>
        {(project || task.estimate_sessions) && (
          <div className="mt-0.5 flex items-center gap-2 pl-[18px] text-xs text-muted">
            {project && settings.modules.tasks && (
              <span className="flex items-center gap-1">
                <ProjectDot color={project.color} /> {project.name}
              </span>
            )}
            {task.estimate_sessions ? (
              <span className="tabular">
                {spent}/{task.estimate_sessions} sessions
              </span>
            ) : null}
          </div>
        )}
      </button>
      {!done && (
        <Button variant="subtle" size="icon-sm" className="rounded-full" onClick={() => navigate(`/focus?task=${task.id}`)} aria-label={`Focus on ${task.title}`}>
          <Play className="!size-3.5 fill-current" />
        </Button>
      )}
      <Button
        variant="ghost"
        size="icon-sm"
        className="opacity-60 hover:opacity-100 md:opacity-0 md:group-hover:opacity-100"
        onClick={() => void removeFromPriorities(task.id)}
        aria-label="Remove from priorities"
      >
        <X />
      </Button>
    </motion.li>
  )
}

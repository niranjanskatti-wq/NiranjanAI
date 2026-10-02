import { AnimatePresence, motion } from 'framer-motion'
import { format, isBefore, parseISO } from 'date-fns'
import { Calendar, Check, Flag, FolderOpen, ListChecks, Plus, Sun, Trash2 } from 'lucide-react'
import { useMemo, useState } from 'react'
import { db } from '@/db'
import type { Project, Subtask, Task } from '@/db/types'
import { useSettings } from '@/state/settings'
import { addToPriorities, createTask, deleteTask, setTaskDone, useProjects, useSessions, useSubtasks, useTasks, useTimeBlocks } from '@/hooks/data'
import { Page } from '@/components/shared/Page'
import { Button } from '@/components/ui/button'
import { Chip, ProjectDot, Tag } from '@/components/ui/chip'
import { Dialog } from '@/components/ui/dialog'
import { EmptyState, LoadingBlock, PageHeader } from '@/components/ui/empty'
import { Select } from '@/components/ui/input'
import { Segmented } from '@/components/ui/segmented'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { ProjectManager } from '@/components/shared/ProjectManager'
import { todayKey } from '@/lib/date'
import { cn } from '@/lib/utils'
import { TaskSheet } from './TaskSheet'

type Filter = 'today' | 'upcoming' | 'all' | 'completed'

export default function TasksPage() {
  const { settings } = useSettings()
  const tasks = useTasks()
  const projects = useProjects()
  const subtasks = useSubtasks()
  const sessions = useSessions(0)
  const today = todayKey()
  const blocks = useTimeBlocks(today)
  const [filter, setFilter] = useState<Filter>('all')
  const [project, setProject] = useState<string | 'all'>('all')
  const [title, setTitle] = useState('')
  const [newProject, setNewProject] = useState<string>('')
  const [openId, setOpenId] = useState<string | null>(null)
  const [projectsOpen, setProjectsOpen] = useState(false)

  const projectMap = useMemo(() => new Map((projects ?? []).map((p) => [p.id, p])), [projects])
  const spent = useMemo(() => {
    const m = new Map<string, number>()
    for (const s of sessions ?? []) if (s.task_id && s.result !== 'interrupted') m.set(s.task_id, (m.get(s.task_id) ?? 0) + 1)
    return m
  }, [sessions])
  const subMap = useMemo(() => {
    const m = new Map<string, Subtask[]>()
    for (const s of subtasks ?? []) m.set(s.task_id, [...(m.get(s.task_id) ?? []), s])
    return m
  }, [subtasks])

  const list = useMemo(() => {
    if (!tasks) return []
    const blocked = new Set((blocks ?? []).map((b) => b.task_id))
    let l = tasks.filter((t) => project === 'all' || t.project_id === project)
    if (filter === 'today')
      l = l.filter((t) => t.status !== 'done' && ((t.is_priority && t.priority_date === today) || (t.due_date && t.due_date <= today) || blocked.has(t.id)))
    else if (filter === 'upcoming') l = l.filter((t) => t.status !== 'done' && t.due_date && t.due_date > today).sort((a, b) => a.due_date!.localeCompare(b.due_date!))
    else if (filter === 'completed') l = l.filter((t) => t.status === 'done').sort((a, b) => (b.completed_at ?? 0) - (a.completed_at ?? 0))
    else l = l.filter((t) => t.status !== 'done').sort((a, b) => Number(b.flagged) - Number(a.flagged) || a.order - b.order)
    return l
  }, [tasks, blocks, filter, project, today])

  const add = async () => {
    const t = title.trim()
    if (!t) return
    await createTask({
      title: t,
      project_id: newProject || (project !== 'all' ? project : null),
      due_date: filter === 'today' ? today : null,
    })
    setTitle('')
  }

  const openTask = tasks?.find((t) => t.id === openId) ?? null
  const fields = new Set(settings.tasks.visibleFields)
  const counts = {
    open: tasks?.filter((t) => t.status !== 'done').length ?? 0,
  }

  return (
    <Page>
      <PageHeader
        title="Tasks"
        subtitle={tasks ? `${counts.open} open` : undefined}
        action={
          <Button variant="ghost" size="sm" onClick={() => setProjectsOpen(true)}>
            <FolderOpen /> Projects
          </Button>
        }
      />

      <form
        className="card mb-4 flex items-center gap-2 p-2"
        onSubmit={(e) => {
          e.preventDefault()
          void add()
        }}
      >
        <Plus className="ml-2 size-4 shrink-0 text-muted" />
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Add a task…"
          className="h-10 min-w-0 flex-1 bg-transparent text-[15px] placeholder:text-muted/70 focus:outline-none"
          aria-label="New task title"
        />
        {fields.has('project') && (projects?.length ?? 0) > 0 && (
          <Select value={newProject} onChange={(e) => setNewProject(e.target.value)} className="w-[132px] shrink-0" aria-label="Project for new task">
            <option value="">No project</option>
            {projects!.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        )}
        <Button type="submit" variant="primary" size="sm" disabled={!title.trim()}>
          Add
        </Button>
      </form>

      <div className="mb-3 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { value: 'today', label: 'Today' },
            { value: 'upcoming', label: 'Upcoming' },
            { value: 'all', label: 'All open' },
            { value: 'completed', label: 'Completed' },
          ]}
        />
      </div>
      {(projects?.length ?? 0) > 0 && (
        <div className="no-scrollbar -mx-4 mb-4 flex gap-1.5 overflow-x-auto px-4">
          <Chip active={project === 'all'} onClick={() => setProject('all')}>
            All projects
          </Chip>
          {projects!.map((p) => (
            <Chip key={p.id} active={project === p.id} onClick={() => setProject(project === p.id ? 'all' : p.id)}>
              <ProjectDot color={p.color} /> {p.name}
            </Chip>
          ))}
        </div>
      )}

      {!tasks ? (
        <div className="space-y-2">
          {[0, 1, 2, 3].map((i) => (
            <LoadingBlock key={i} className="h-14" />
          ))}
        </div>
      ) : list.length === 0 ? (
        <div className="card">
          <EmptyState
            icon={<ListChecks />}
            title={filter === 'completed' ? 'Nothing completed yet' : filter === 'upcoming' ? 'Nothing upcoming' : filter === 'today' ? 'Nothing planned for today' : 'No open tasks'}
            description={
              filter === 'completed'
                ? 'Finished tasks will show up here.'
                : filter === 'upcoming'
                  ? 'Tasks with a future due date appear here.'
                  : 'Add one above. Keep titles short and concrete.'
            }
          />
        </div>
      ) : (
        <ul className="card divide-y divide-border/70 overflow-hidden px-1">
          <AnimatePresence initial={false}>
            {list.map((t) => (
              <TaskRow
                key={t.id}
                task={t}
                project={t.project_id ? projectMap.get(t.project_id) : undefined}
                spent={spent.get(t.id) ?? 0}
                subs={subMap.get(t.id) ?? []}
                fields={fields}
                onOpen={() => setOpenId(t.id)}
              />
            ))}
          </AnimatePresence>
        </ul>
      )}

      <TaskSheet task={openTask} onClose={() => setOpenId(null)} spent={openTask ? spent.get(openTask.id) ?? 0 : 0} />
      <Dialog open={projectsOpen} onOpenChange={setProjectsOpen} title="Projects" description="Colored tags for grouping tasks.">
        <div className="pb-4">
          <ProjectManager />
        </div>
      </Dialog>
    </Page>
  )
}

function TaskRow({
  task,
  project,
  spent,
  subs,
  fields,
  onOpen,
}: {
  task: Task
  project?: Project
  spent: number
  subs: Subtask[]
  fields: Set<string>
  onOpen: () => void
}) {
  const { settings } = useSettings()
  const done = task.status === 'done'
  const today = todayKey()
  const overdue = task.due_date && task.due_date < today && !done
  const isPrio = task.is_priority && task.priority_date === today
  const subsDone = subs.filter((s) => s.done).length

  const moveToToday = async () => {
    if (settings.modules.priorities) {
      const ok = await addToPriorities(task.id, settings.priorities.count)
      toast(ok ? `Added to ${settings.priorities.label.toLowerCase()}` : `${settings.priorities.label} are full (${settings.priorities.count}).`, { kind: ok ? 'success' : 'info' })
    } else {
      await db.tasks.update(task.id, { due_date: today })
      toast('Due today', { kind: 'success' })
    }
  }

  return (
    <motion.li layout initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, height: 0 }} className="group flex items-center gap-3 px-3 py-3">
      <button
        onClick={() => void setTaskDone(task.id, !done)}
        className={cn('flex size-[22px] shrink-0 items-center justify-center rounded-full border-2 transition-all active:scale-90', done ? 'border-success bg-success text-bg' : 'border-border hover:border-accent')}
        aria-label={done ? 'Mark not done' : 'Mark done'}
      >
        {done && <Check className="size-3.5" strokeWidth={3} />}
      </button>
      <button className="min-w-0 flex-1 text-left" onClick={onOpen}>
        <div className={cn('flex items-center gap-1.5 text-[15px] font-medium', done && 'text-muted line-through decoration-muted/50')}>
          {fields.has('flag') && task.flagged && <Flag className="size-3.5 shrink-0 fill-warning text-warning" />}
          <span className="truncate">{task.title}</span>
        </div>
        <div className="mt-1 flex flex-wrap items-center gap-x-2.5 gap-y-1 text-xs text-muted">
          {fields.has('project') && project && <Tag color={project.color}>{project.name}</Tag>}
          {isPrio && settings.modules.priorities && <span className="font-medium text-accent">Today</span>}
          {fields.has('status') && task.status === 'in_progress' && <span className="font-medium text-accent">In progress</span>}
          {fields.has('sessions') && (task.estimate_sessions || spent > 0) ? (
            <span className={cn('tabular', task.estimate_sessions && spent > task.estimate_sessions && 'text-warning')}>
              {spent}
              {task.estimate_sessions ? `/${task.estimate_sessions}` : ''} sessions
            </span>
          ) : fields.has('estimate') && task.estimate_sessions ? (
            <span className="tabular">est. {task.estimate_sessions} sessions</span>
          ) : null}
          {fields.has('dueDate') && task.due_date && (
            <span className={cn('flex items-center gap-1', overdue && 'text-warning')}>
              <Calendar className="size-3" />
              {task.due_date === today ? 'Today' : format(parseISO(task.due_date), 'MMM d')}
            </span>
          )}
          {fields.has('subtasks') && settings.modules.subtasks && subs.length > 0 && (
            <span className="tabular">
              {subsDone}/{subs.length} steps
            </span>
          )}
          {done && task.completed_at && <span>Done {format(task.completed_at, 'MMM d')}</span>}
        </div>
      </button>
      {!done && !isPrio && (
        <Button variant="ghost" size="icon-sm" className="opacity-70 hover:opacity-100 md:opacity-0 md:group-hover:opacity-100" onClick={() => void moveToToday()} aria-label="Move to today" title="Move to today">
          <Sun />
        </Button>
      )}
      <Button
        variant="ghost"
        size="icon-sm"
        className="hidden opacity-0 group-hover:opacity-100 md:inline-flex"
        onClick={async () => {
          if (await confirmDialog({ title: `Delete “${task.title}”?`, description: 'Sessions logged on it are kept.', confirmLabel: 'Delete', danger: true })) {
            await deleteTask(task.id)
            toast('Task deleted')
          }
        }}
        aria-label="Delete task"
      >
        <Trash2 />
      </Button>
    </motion.li>
  )
}

export function isOverdue(t: Task) {
  return !!t.due_date && isBefore(parseISO(t.due_date), new Date(new Date().toDateString()))
}

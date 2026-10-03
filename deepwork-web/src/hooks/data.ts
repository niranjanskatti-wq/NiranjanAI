import { useLiveQuery } from 'dexie-react-hooks'
import { db, uid } from '@/db'
import type { Distraction, DistractionReason, Project, Review, Session, Subtask, Task, TimeBlock } from '@/db/types'
import { dateKey } from '@/lib/date'

export function useProjects(): Project[] | undefined {
  return useLiveQuery(() => db.projects.orderBy('order').toArray(), [])
}

export function useTasks(): Task[] | undefined {
  return useLiveQuery(() => db.tasks.orderBy('order').toArray(), [])
}

export function useSubtasks(): Subtask[] | undefined {
  return useLiveQuery(() => db.subtasks.orderBy('order').toArray(), [])
}

export function useSessions(since = 0): Session[] | undefined {
  return useLiveQuery(() => db.sessions.where('started_at').aboveOrEqual(since).sortBy('started_at'), [since])
}

export function useDistractions(since = 0): Distraction[] | undefined {
  return useLiveQuery(() => db.distractions.where('timestamp').aboveOrEqual(since).toArray(), [since])
}

export function useReasons(): DistractionReason[] | undefined {
  return useLiveQuery(() => db.distractionReasons.orderBy('order').toArray(), [])
}

export function useTimeBlocks(date?: string): TimeBlock[] | undefined {
  return useLiveQuery(() => (date ? db.timeBlocks.where('date').equals(date).toArray() : db.timeBlocks.toArray()), [date])
}

export function useReviews(): Review[] | undefined {
  return useLiveQuery(() => db.reviews.orderBy('created_at').reverse().toArray(), [])
}

// ------------------------------------------------------------ task mutations

export async function createTask(partial: Partial<Task> & { title: string }): Promise<Task> {
  const last = await db.tasks.orderBy('order').last()
  const task: Task = {
    id: uid(),
    project_id: null,
    estimate_sessions: null,
    due_date: null,
    status: 'todo',
    flagged: false,
    is_priority: false,
    priority_date: null,
    priority_order: 0,
    order: (last?.order ?? 0) + 1,
    created_at: Date.now(),
    completed_at: null,
    ...partial,
  }
  await db.tasks.put(task)
  return task
}

export async function setTaskDone(id: string, done: boolean) {
  await db.tasks.update(id, { status: done ? 'done' : 'todo', completed_at: done ? Date.now() : null })
}

export async function deleteTask(id: string) {
  await db.transaction('rw', db.tasks, db.subtasks, db.timeBlocks, db.sessions, async () => {
    await db.tasks.delete(id)
    await db.subtasks.where('task_id').equals(id).delete()
    await db.timeBlocks.where('task_id').equals(id).modify({ task_id: null })
    await db.sessions.where('task_id').equals(id).modify({ task_id: null })
  })
}

export async function todaysPriorities(day = dateKey()) {
  return (await db.tasks.where('priority_date').equals(day).toArray()).filter((t) => t.is_priority).sort((a, b) => a.priority_order - b.priority_order)
}

/** Add a task to a day's top priorities. Returns false when the limit is reached. */
export async function addToPriorities(id: string, limit: number, day = dateKey()) {
  const current = await todaysPriorities(day)
  if (current.some((t) => t.id === id)) return true
  if (current.length >= limit) return false
  await db.tasks.update(id, { is_priority: true, priority_date: day, priority_order: current.length })
  return true
}

export async function removeFromPriorities(id: string) {
  await db.tasks.update(id, { is_priority: false, priority_date: null })
}

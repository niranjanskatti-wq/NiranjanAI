import Dexie, { type Table } from 'dexie'
import type {
  Distraction,
  DistractionReason,
  Project,
  Review,
  Session,
  SettingsRow,
  Subtask,
  Task,
  TimeBlock,
} from './types'

export class DeepworkDB extends Dexie {
  settings!: Table<SettingsRow, string>
  projects!: Table<Project, string>
  tasks!: Table<Task, string>
  subtasks!: Table<Subtask, string>
  timeBlocks!: Table<TimeBlock, string>
  sessions!: Table<Session, string>
  distractions!: Table<Distraction, string>
  distractionReasons!: Table<DistractionReason, string>
  reviews!: Table<Review, string>

  constructor() {
    super('deepwork')
    this.version(1).stores({
      settings: 'key',
      projects: 'id, order',
      tasks: 'id, project_id, status, due_date, priority_date, order, completed_at, created_at',
      subtasks: 'id, task_id, order',
      timeBlocks: 'id, date, task_id',
      sessions: 'id, task_id, started_at, result',
      distractions: 'id, session_id, timestamp',
      distractionReasons: 'id, order',
      reviews: 'id, type, date, created_at',
    })
  }
}

export const db = new DeepworkDB()

export const DATA_TABLES = [
  'projects',
  'tasks',
  'subtasks',
  'timeBlocks',
  'sessions',
  'distractions',
  'distractionReasons',
  'reviews',
] as const

export type DataTable = (typeof DATA_TABLES)[number]

export function uid(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) return crypto.randomUUID()
  return Math.random().toString(36).slice(2) + Date.now().toString(36)
}

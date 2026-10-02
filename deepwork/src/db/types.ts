export type ID = string

export type TaskStatus = 'todo' | 'in_progress' | 'done'
export type SessionResult = 'done' | 'partly' | 'stuck' | 'interrupted'

export interface Project {
  id: ID
  name: string
  color: string
  order: number
  is_demo?: boolean
}

export interface Task {
  id: ID
  title: string
  project_id: ID | null
  estimate_sessions: number | null
  due_date: string | null // yyyy-MM-dd
  status: TaskStatus
  /** High-priority flag shown in the task list. */
  flagged: boolean
  /** Whether the task is one of the top priorities for `priority_date`. */
  is_priority: boolean
  priority_date: string | null
  priority_order: number
  order: number
  created_at: number
  completed_at: number | null
  is_demo?: boolean
}

export interface Subtask {
  id: ID
  task_id: ID
  title: string
  done: boolean
  order: number
  is_demo?: boolean
}

export interface TimeBlock {
  id: ID
  date: string // yyyy-MM-dd
  start_time: string // HH:mm
  end_time: string // HH:mm
  task_id: ID | null
  label: string
  is_demo?: boolean
}

export interface Session {
  id: ID
  task_id: ID | null
  planned_duration: number // seconds
  actual_duration: number // seconds
  started_at: number
  ended_at: number
  result: SessionResult
  note: string
  is_demo?: boolean
}

export interface Distraction {
  id: ID
  session_id: ID
  timestamp: number
  reason: string
  note: string
  is_demo?: boolean
}

export interface DistractionReason {
  id: ID
  label: string
  order: number
}

export type ReviewType = 'daily' | 'weekly'

export interface ReviewAnswer {
  question: string
  answer: string
}

export interface Review {
  id: ID
  type: ReviewType
  date: string // yyyy-MM-dd (for weekly: the date the review was written)
  answers: ReviewAnswer[]
  next_priorities: { task_id: ID; title: string }[]
  stats?: Record<string, number | string>
  created_at: number
  is_demo?: boolean
}

export interface SettingsRow {
  key: 'app'
  value: import('@/lib/settings').Settings
}

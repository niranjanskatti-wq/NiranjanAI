// Full-data export / import, CSV export, and wipe. Backups carry a schema version so future
// versions of the app can migrate and restore older files.
import { format } from 'date-fns'
import { DATA_TABLES, db, type DataTable } from '@/db'
import type { Distraction, Project, Session, Task } from '@/db/types'
import { DEFAULT_SETTINGS, mergeSettings, type Settings } from './settings'
import { DEFAULT_REASONS } from '@/state/settings'
import { uid } from '@/db'

export const SCHEMA_VERSION = 1

export interface BackupFile {
  app: 'deepwork'
  schema_version: number
  exported_at: string
  data: {
    settings: Partial<Settings>
    projects: unknown[]
    tasks: unknown[]
    subtasks: unknown[]
    timeBlocks: unknown[]
    sessions: unknown[]
    distractions: unknown[]
    distractionReasons: unknown[]
    reviews: unknown[]
  }
}

export type RecordCounts = Record<DataTable, number>

/** Strip device-specific secrets (PIN hash, biometric credential, Drive state) from settings. */
function portableSettings(s: Settings): Partial<Settings> {
  const copy = structuredClone(s) as Partial<Settings>
  delete copy.lock
  delete copy.backup
  delete copy.demoLoaded
  return copy
}

export async function buildBackup(): Promise<BackupFile> {
  const row = await db.settings.get('app')
  const settings = mergeSettings(row?.value)
  const data = { settings: portableSettings(settings) } as BackupFile['data']
  for (const t of DATA_TABLES) (data as unknown as Record<string, unknown[]>)[t] = await db.table(t).toArray()
  return { app: 'deepwork', schema_version: SCHEMA_VERSION, exported_at: new Date().toISOString(), data }
}

export function backupFilename(date = new Date()) {
  return `deepwork-backup-${format(date, 'yyyy-MM-dd')}.json`
}

/** Bring older backup files up to the current schema. Add steps here when the schema changes. */
export function migrateBackup(raw: unknown): BackupFile {
  if (!raw || typeof raw !== 'object') throw new Error('This file is not a Deepwork backup.')
  const file = raw as Partial<BackupFile>
  if (file.app !== 'deepwork' || !file.data || typeof file.data !== 'object') throw new Error('This file is not a Deepwork backup.')
  const version = Number(file.schema_version ?? 0)
  if (version > SCHEMA_VERSION) throw new Error(`This backup was made by a newer version of Deepwork (schema ${version}). Please update the app first.`)
  const data = { ...(file.data as BackupFile['data']) }
  // v0 → v1: early files might lack newer collections or fields.
  for (const t of DATA_TABLES) if (!Array.isArray((data as Record<string, unknown>)[t])) (data as Record<string, unknown>)[t] = []
  data.tasks = (data.tasks as Partial<Task>[]).map((t) => ({
    flagged: false,
    is_priority: false,
    priority_date: null,
    priority_order: 0,
    order: 0,
    estimate_sessions: null,
    due_date: null,
    project_id: null,
    completed_at: null,
    status: 'todo',
    created_at: Date.now(),
    ...t,
  }))
  data.timeBlocks = (data.timeBlocks as Record<string, unknown>[]).map((b) => ({ label: '', ...b }))
  data.sessions = (data.sessions as Record<string, unknown>[]).map((s) => ({ note: '', ...s }))
  data.distractions = (data.distractions as Record<string, unknown>[]).map((d) => ({ note: '', ...d }))
  return { app: 'deepwork', schema_version: SCHEMA_VERSION, exported_at: file.exported_at ?? '', data }
}

export function countRecords(file: BackupFile): RecordCounts {
  const out = {} as RecordCounts
  for (const t of DATA_TABLES) out[t] = ((file.data as unknown as Record<string, unknown[]>)[t] ?? []).length
  return out
}

export function parseBackupText(text: string): BackupFile {
  let raw: unknown
  try {
    raw = JSON.parse(text)
  } catch {
    throw new Error('The file is not valid JSON.')
  }
  return migrateBackup(raw)
}

/** Replace all local data with the contents of a backup. Device lock and Drive connection are kept. */
export async function restoreBackup(file: BackupFile) {
  const tables = [db.settings, ...DATA_TABLES.map((t) => db.table(t))]
  await db.transaction('rw', tables, async () => {
    const current = mergeSettings((await db.settings.get('app'))?.value)
    const incoming = mergeSettings({ ...file.data.settings, lock: current.lock, backup: current.backup, demoLoaded: false })
    for (const t of DATA_TABLES) {
      await db.table(t).clear()
      const rows = (file.data as unknown as Record<string, unknown[]>)[t]
      if (rows?.length) await db.table(t).bulkPut(rows)
    }
    if ((await db.distractionReasons.count()) === 0) {
      await db.distractionReasons.bulkPut(DEFAULT_REASONS.map((label, order) => ({ id: uid(), label, order })))
    }
    incoming.demoLoaded = (await db.sessions.filter((s) => !!s.is_demo).count()) > 0
    await db.settings.put({ key: 'app', value: incoming })
  })
}

export async function deleteAllData() {
  await db.transaction('rw', [db.settings, ...DATA_TABLES.map((t) => db.table(t))], async () => {
    for (const t of DATA_TABLES) await db.table(t).clear()
    await db.settings.clear()
  })
  try {
    for (const k of Object.keys(localStorage)) if (k.startsWith('deepwork.')) localStorage.removeItem(k)
  } catch {
    /* ignore */
  }
  // Recreate defaults so the app keeps working immediately.
  await db.settings.put({ key: 'app', value: structuredClone(DEFAULT_SETTINGS) })
  await db.distractionReasons.bulkPut(DEFAULT_REASONS.map((label, order) => ({ id: uid(), label, order })))
}

// ---------------------------------------------------------------- CSV

function csvCell(v: unknown): string {
  if (v === null || v === undefined) return ''
  const s = String(v)
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
}

function toCsv(headers: string[], rows: unknown[][]) {
  return [headers.join(','), ...rows.map((r) => r.map(csvCell).join(','))].join('\r\n')
}

const iso = (ts: number | null | undefined) => (ts ? new Date(ts).toISOString() : '')

export async function buildCsvs() {
  const [sessions, tasks, distractions, projects]: [Session[], Task[], Distraction[], Project[]] = await Promise.all([
    db.sessions.orderBy('started_at').toArray(),
    db.tasks.toArray(),
    db.distractions.orderBy('timestamp').toArray(),
    db.projects.toArray(),
  ])
  const taskTitle = new Map(tasks.map((t) => [t.id, t.title]))
  const projectName = new Map(projects.map((p) => [p.id, p.name]))
  const sessionsCsv = toCsv(
    ['id', 'task_id', 'task_title', 'planned_minutes', 'actual_minutes', 'started_at', 'ended_at', 'result', 'note'],
    sessions.map((s) => [
      s.id,
      s.task_id ?? '',
      s.task_id ? taskTitle.get(s.task_id) ?? '' : '',
      Math.round(s.planned_duration / 6) / 10,
      Math.round(s.actual_duration / 6) / 10,
      iso(s.started_at),
      iso(s.ended_at),
      s.result,
      s.note,
    ]),
  )
  const tasksCsv = toCsv(
    ['id', 'title', 'project', 'estimate_sessions', 'due_date', 'status', 'flagged', 'is_priority', 'priority_date', 'created_at', 'completed_at'],
    tasks.map((t) => [
      t.id,
      t.title,
      t.project_id ? projectName.get(t.project_id) ?? '' : '',
      t.estimate_sessions ?? '',
      t.due_date ?? '',
      t.status,
      t.flagged,
      t.is_priority,
      t.priority_date ?? '',
      iso(t.created_at),
      iso(t.completed_at),
    ]),
  )
  const distractionsCsv = toCsv(
    ['id', 'session_id', 'timestamp', 'reason', 'note'],
    distractions.map((d) => [d.id, d.session_id, iso(d.timestamp), d.reason, d.note]),
  )
  return { sessionsCsv, tasksCsv, distractionsCsv }
}

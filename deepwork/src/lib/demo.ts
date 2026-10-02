// Demo data so insights can be previewed. Every demo record carries is_demo: true and can be
// cleared without touching real data.
import { addDays, startOfDay } from 'date-fns'
import { db, uid } from '@/db'
import type { Distraction, Project, Review, Session, SessionResult, Subtask, Task, TimeBlock } from '@/db/types'
import { dateKey } from './date'
import { updateSettings } from '@/state/settings'

function rng(seed: number) {
  let s = seed
  return () => {
    s = (s * 1664525 + 1013904223) % 4294967296
    return s / 4294967296
  }
}

const PROJECTS = [
  { name: 'Thesis', color: '#7C7CFF' },
  { name: 'Client work', color: '#22C3A6' },
  { name: 'Learning', color: '#F59E0B' },
  { name: 'Admin', color: '#F472B6' },
]

const TASK_TITLES: Record<string, string[]> = {
  Thesis: ['Draft chapter 3 methods', 'Revise literature review', 'Clean experiment data', 'Write results section', 'Make figures for chapter 4', 'Outline discussion'],
  'Client work': ['Homepage redesign', 'Fix checkout bug', 'Write API docs', 'Prepare sprint demo', 'Refactor auth flow', 'Review pull requests'],
  Learning: ['Rust ownership chapter', 'Statistics course week 4', 'Read "Deep Work" ch. 2', 'Practice SQL window functions'],
  Admin: ['Tax paperwork', 'Plan next week', 'Inbox zero', 'Update invoices'],
}

export async function loadDemoData() {
  await clearDemoData()
  const r = rng(42)
  const now = new Date()
  const today = startOfDay(now)
  const reasons = (await db.distractionReasons.orderBy('order').toArray()).map((x) => x.label)
  const reasonPool = reasons.length ? reasons : ['Phone', 'Person', 'Noise', 'Boredom', 'Unclear task', 'Other']
  const weights = [0.38, 0.18, 0.12, 0.14, 0.12, 0.06]

  const existingProjects = await db.projects.count()
  const projects: Project[] = PROJECTS.map((p, i) => ({ id: uid(), ...p, order: existingProjects + i, is_demo: true }))
  const tasks: Task[] = []
  const subtasks: Subtask[] = []
  let order = (await db.tasks.count()) + 1
  for (const p of projects) {
    for (const title of TASK_TITLES[p.name]) {
      const created = addDays(today, -Math.floor(r() * 50) - 10).getTime()
      tasks.push({
        id: uid(),
        title,
        project_id: p.id,
        estimate_sessions: 1 + Math.floor(r() * 5),
        due_date: r() < 0.4 ? dateKey(addDays(today, Math.floor(r() * 14) - 3)) : null,
        status: 'todo',
        flagged: r() < 0.2,
        is_priority: false,
        priority_date: null,
        priority_order: 0,
        order: order++,
        created_at: created,
        completed_at: null,
        is_demo: true,
      })
    }
  }
  for (const t of tasks.slice(0, 8)) {
    const n = 2 + Math.floor(r() * 3)
    for (let i = 0; i < n; i++) subtasks.push({ id: uid(), task_id: t.id, title: `Step ${i + 1}`, done: r() < 0.5, order: i, is_demo: true })
  }

  const sessions: Session[] = []
  const distractions: Distraction[] = []
  const reviews: Review[] = []
  const blocks: TimeBlock[] = []
  const durations = [25, 25, 45, 45, 60, 90, 15]

  for (let d = 59; d >= 0; d--) {
    const day = addDays(today, -d)
    const weekend = day.getDay() === 0 || day.getDay() === 6
    if (weekend && r() < 0.6) continue
    if (r() < 0.08) continue
    const count = d === 0 ? Math.min(2, Math.floor(now.getHours() / 5)) : 2 + Math.floor(r() * 4)
    let cursor = 8 * 60 + Math.floor(r() * 90)
    const dayKey = dateKey(day)
    // Priorities for the day
    const open = tasks.filter((t) => t.status !== 'done')
    const prios = open.sort(() => r() - 0.5).slice(0, 3)
    for (const [i, t] of prios.entries()) {
      t.is_priority = true
      t.priority_date = dayKey
      t.priority_order = i
    }
    for (let i = 0; i < count; i++) {
      const plannedMin = durations[Math.floor(r() * durations.length)]
      const start = new Date(day)
      start.setHours(0, cursor, 0, 0)
      if (start.getTime() > now.getTime() - plannedMin * 60000) break
      const task = r() < 0.9 ? prios[Math.floor(r() * prios.length)] ?? tasks[Math.floor(r() * tasks.length)] : null
      const afternoon = start.getHours() >= 15
      const roll = r()
      // Afternoon sessions get interrupted more; 45-minute sessions finish best.
      const bonus = plannedMin === 45 ? 0.18 : plannedMin === 90 ? -0.15 : 0
      let result: SessionResult
      if (roll < (afternoon ? 0.2 : 0.08)) result = 'interrupted'
      else if (roll < 0.62 + bonus) result = 'done'
      else if (roll < 0.86) result = 'partly'
      else result = 'stuck'
      const actualMin = result === 'interrupted' ? Math.max(3, Math.floor(plannedMin * (0.2 + r() * 0.6))) : plannedMin
      const sid = uid()
      sessions.push({
        id: sid,
        task_id: task?.id ?? null,
        planned_duration: plannedMin * 60,
        actual_duration: actualMin * 60,
        started_at: start.getTime(),
        ended_at: start.getTime() + actualMin * 60000,
        result,
        note: result === 'done' ? 'Finished the planned chunk.' : result === 'stuck' ? 'Unsure how to structure the next part.' : '',
        is_demo: true,
      })
      const nDistr = Math.floor(r() * (afternoon ? 4 : 2.2))
      for (let k = 0; k < nDistr; k++) {
        let x = r()
        let idx = 0
        while (idx < weights.length - 1 && x > weights[idx]) x -= weights[idx++]
        distractions.push({
          id: uid(),
          session_id: sid,
          timestamp: start.getTime() + Math.floor(r() * actualMin * 60000),
          reason: reasonPool[Math.min(idx, reasonPool.length - 1)],
          note: '',
          is_demo: true,
        })
      }
      if (task && result === 'done' && r() < 0.08 && task.status !== 'done') {
        task.status = 'done'
        task.completed_at = start.getTime() + actualMin * 60000
      }
      cursor += actualMin + 10 + Math.floor(r() * 50)
      if (i === 1) cursor += 45
    }
    if (d === 0) {
      for (const [i, t] of prios.entries()) {
        const startMin = 9 * 60 + i * 120
        blocks.push({
          id: uid(),
          date: dayKey,
          start_time: `${String(Math.floor(startMin / 60)).padStart(2, '0')}:00`,
          end_time: `${String(Math.floor(startMin / 60) + 1).padStart(2, '0')}:00`,
          task_id: t.id,
          label: '',
          is_demo: true,
        })
      }
    }
    if (d > 0 && r() < 0.6) {
      reviews.push({
        id: uid(),
        type: 'daily',
        date: dayKey,
        answers: [{ question: 'One thing to do differently tomorrow?', answer: ['Start with the hardest task.', 'Phone in another room.', 'Smaller first step.', 'Block the afternoon.'][Math.floor(r() * 4)] }],
        next_priorities: [],
        created_at: day.getTime() + 20 * 3600000,
        is_demo: true,
      })
    }
    if (d > 0 && day.getDay() === 0) {
      reviews.push({
        id: uid(),
        type: 'weekly',
        date: dayKey,
        answers: [
          { question: 'What went well?', answer: 'Mornings were consistently productive.' },
          { question: 'What should I cut?', answer: 'Late-afternoon meetings.' },
          { question: 'Top 3 priorities for next week?', answer: 'Chapter 3, sprint demo, invoices.' },
        ],
        next_priorities: [],
        created_at: day.getTime() + 17 * 3600000,
        is_demo: true,
      })
    }
  }

  await db.transaction('rw', [db.projects, db.tasks, db.subtasks, db.sessions, db.distractions, db.reviews, db.timeBlocks], async () => {
    await db.projects.bulkPut(projects)
    await db.tasks.bulkPut(tasks)
    await db.subtasks.bulkPut(subtasks)
    await db.sessions.bulkPut(sessions)
    await db.distractions.bulkPut(distractions)
    await db.reviews.bulkPut(reviews)
    await db.timeBlocks.bulkPut(blocks)
  })
  await updateSettings((s) => {
    s.demoLoaded = true
  })
  return { sessions: sessions.length, tasks: tasks.length }
}

export async function clearDemoData() {
  await db.transaction('rw', [db.projects, db.tasks, db.subtasks, db.sessions, db.distractions, db.reviews, db.timeBlocks], async () => {
    for (const table of [db.projects, db.tasks, db.subtasks, db.sessions, db.distractions, db.reviews, db.timeBlocks]) {
      await (table as unknown as import('dexie').Table<{ id: string; is_demo?: boolean }, string>).filter((x) => !!x.is_demo).delete()
    }
  })
  await updateSettings((s) => {
    s.demoLoaded = false
  })
}

import { useDraggable, useDroppable } from '@dnd-kit/core'
import { CSS } from '@dnd-kit/utilities'
import { CalendarDays, GripVertical, Play, Trash2 } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router'
import { db, uid } from '@/db'
import type { Project, Task, TimeBlock } from '@/db/types'
import { useSettings } from '@/state/settings'
import { Card, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'
import { Input, Label } from '@/components/ui/input'
import { confirmDialog } from '@/components/ui/confirm'
import { TaskPickerDialog } from '@/components/shared/TaskPickerDialog'
import { formatClock, minutesToTime, timeToMinutes, todayKey } from '@/lib/date'
import { cn } from '@/lib/utils'
import { toast } from '@/components/ui/toast'

export function Timeline({ blocks, tasks, projects, tray }: { blocks: TimeBlock[]; tasks: Task[]; projects: Project[]; tray: Task[] }) {
  const { settings } = useSettings()
  const tb = settings.timeBlocks
  const start = timeToMinutes(tb.dayStart)
  const end = Math.max(start + tb.blockLength, timeToMinutes(tb.dayEnd))
  const len = tb.blockLength
  const compact = settings.appearance.density === 'compact'
  const slotH = len === 15 ? (compact ? 28 : 32) : len === 30 ? (compact ? 36 : 42) : compact ? 46 : 56
  const slots = useMemo(() => {
    const out: number[] = []
    for (let m = start; m < end; m += len) out.push(m)
    return out
  }, [start, end, len])
  const taskMap = new Map(tasks.map((t) => [t.id, t]))
  const projectMap = new Map(projects.map((p) => [p.id, p]))
  const [editing, setEditing] = useState<TimeBlock | null>(null)
  const [newAt, setNewAt] = useState<number | null>(null)
  const nowMin = useNowMinutes()
  const scheduledIds = new Set(blocks.map((b) => b.task_id))
  const trayItems = tray.filter((t) => !scheduledIds.has(t.id) && t.status !== 'done')

  return (
    <Card>
      <CardHeader icon={<CalendarDays />} title="Time blocks" subtitle={`${formatClock(tb.dayStart)} – ${formatClock(tb.dayEnd)}`} />
      {trayItems.length > 0 && (
        <div className="mb-3">
          <p className="mb-1.5 text-xs text-muted">Drag onto the timeline, or tap a slot.</p>
          <div className="no-scrollbar -mx-1 flex gap-1.5 overflow-x-auto px-1 pb-1">
            {trayItems.map((t) => (
              <TrayChip key={t.id} task={t} color={t.project_id ? projectMap.get(t.project_id)?.color : undefined} />
            ))}
          </div>
        </div>
      )}
      <div className="relative" style={{ height: slots.length * slotH }}>
        {slots.map((m, i) => (
          <Slot key={m} minute={m} top={i * slotH} height={slotH} onTap={() => setNewAt(m)} showLabel={m % 60 === 0 || len === 60} />
        ))}
        {nowMin >= start && nowMin < end && (
          <div className="pointer-events-none absolute left-12 right-0 z-20 flex items-center" style={{ top: ((nowMin - start) / len) * slotH }}>
            <span className="-ml-1 size-2 rounded-full bg-accent" />
            <span className="h-px flex-1 bg-accent/70" />
          </div>
        )}
        {blocks.map((b) => {
          const s = timeToMinutes(b.start_time)
          const e = timeToMinutes(b.end_time)
          if (e <= start || s >= end) return null
          const top = ((Math.max(s, start) - start) / len) * slotH
          const height = Math.max(slotH * 0.6, ((Math.min(e, end) - Math.max(s, start)) / len) * slotH - 4)
          const task = b.task_id ? taskMap.get(b.task_id) : undefined
          const color = task?.project_id ? projectMap.get(task.project_id)?.color : undefined
          return <Block key={b.id} block={b} task={task} color={color} top={top} height={height} onTap={() => setEditing(b)} />
        })}
      </div>
      <BlockEditor block={editing} onClose={() => setEditing(null)} tasks={tasks} />
      <TaskPickerDialog
        open={newAt !== null}
        onOpenChange={(o) => !o && setNewAt(null)}
        title={newAt !== null ? `Block at ${formatClock(minutesToTime(newAt))}` : 'New block'}
        description="Choose a task for this block."
        allowNone
        noneLabel="Empty block (add a label later)"
        onPick={async (t) => {
          if (newAt === null) return
          await createBlock(newAt, len, t?.id ?? null, t ? '' : 'Focus block')
          setNewAt(null)
        }}
      />
    </Card>
  )
}

export async function createBlock(startMin: number, len: number, taskId: string | null, label = '') {
  await db.timeBlocks.put({
    id: uid(),
    date: todayKey(),
    start_time: minutesToTime(startMin),
    end_time: minutesToTime(startMin + len),
    task_id: taskId,
    label,
  })
}

export async function moveBlock(id: string, startMin: number) {
  const b = await db.timeBlocks.get(id)
  if (!b) return
  const dur = timeToMinutes(b.end_time) - timeToMinutes(b.start_time)
  await db.timeBlocks.update(id, { start_time: minutesToTime(startMin), end_time: minutesToTime(startMin + Math.max(5, dur)) })
}

function useNowMinutes() {
  const [m, setM] = useState(() => new Date().getHours() * 60 + new Date().getMinutes())
  useEffect(() => {
    const iv = setInterval(() => setM(new Date().getHours() * 60 + new Date().getMinutes()), 30_000)
    return () => clearInterval(iv)
  }, [])
  return m
}

function Slot({ minute, top, height, onTap, showLabel }: { minute: number; top: number; height: number; onTap: () => void; showLabel: boolean }) {
  const { setNodeRef, isOver } = useDroppable({ id: `slot:${minute}`, data: { minute } })
  return (
    <div ref={setNodeRef} className="absolute inset-x-0 flex" style={{ top, height }}>
      <div className="tabular w-12 shrink-0 -translate-y-2 pr-2 text-right text-[11px] text-muted">{showLabel ? formatClock(minutesToTime(minute)) : ''}</div>
      <button
        onClick={onTap}
        aria-label={`Add block at ${formatClock(minutesToTime(minute))}`}
        className={cn('flex-1 border-t border-border/70 transition-colors', isOver ? 'bg-accent-soft' : 'hover:bg-card-2/50')}
      />
    </div>
  )
}

function Block({ block, task, color, top, height, onTap }: { block: TimeBlock; task?: Task; color?: string; top: number; height: number; onTap: () => void }) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({ id: `block:${block.id}`, data: { title: task?.title ?? block.label } })
  const c = color ?? 'var(--accent)'
  const done = task?.status === 'done'
  return (
    <div
      ref={setNodeRef}
      className={cn('absolute left-12 right-0 z-10 flex overflow-hidden rounded-[10px] border text-left shadow-sm', isDragging && 'opacity-50')}
      style={{
        top: top + 2,
        height,
        transform: CSS.Translate.toString(transform),
        background: `color-mix(in oklab, ${c} 14%, var(--card))`,
        borderColor: `color-mix(in oklab, ${c} 35%, transparent)`,
      }}
    >
      <span className="w-1 shrink-0" style={{ background: c }} />
      <button className="min-w-0 flex-1 px-2.5 py-1 text-left" onClick={onTap}>
        <div className={cn('truncate text-[13px] font-medium', done && 'text-muted line-through')}>{task?.title ?? (block.label || 'Block')}</div>
        {height > 36 && (
          <div className="tabular truncate text-[11px] text-muted">
            {formatClock(block.start_time)} – {formatClock(block.end_time)}
          </div>
        )}
      </button>
      <button className="flex w-7 shrink-0 cursor-grab touch-none items-center justify-center text-muted/70" aria-label="Drag block" {...attributes} {...listeners}>
        <GripVertical className="size-3.5" />
      </button>
    </div>
  )
}

function TrayChip({ task, color }: { task: Task; color?: string }) {
  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({ id: `tray:${task.id}`, data: { taskId: task.id, title: task.title } })
  return (
    <button
      ref={setNodeRef}
      {...attributes}
      {...listeners}
      className={cn('flex h-8 max-w-[200px] shrink-0 cursor-grab touch-none items-center gap-1.5 rounded-full border border-border bg-card-2/60 px-3 text-[13px] font-medium', isDragging && 'opacity-40')}
    >
      <span className="size-1.5 shrink-0 rounded-full" style={{ background: color ?? 'var(--muted)' }} />
      <span className="truncate">{task.title}</span>
    </button>
  )
}

function BlockEditor({ block, onClose, tasks }: { block: TimeBlock | null; onClose: () => void; tasks: Task[] }) {
  const navigate = useNavigate()
  const [start, setStart] = useState('')
  const [end, setEnd] = useState('')
  const [label, setLabel] = useState('')
  const [taskId, setTaskId] = useState<string | null>(null)
  const [picker, setPicker] = useState(false)
  useEffect(() => {
    if (block) {
      setStart(block.start_time)
      setEnd(block.end_time)
      setLabel(block.label)
      setTaskId(block.task_id)
    }
  }, [block])
  const task = tasks.find((t) => t.id === taskId)
  const valid = start && end && timeToMinutes(end) > timeToMinutes(start)
  const duration = valid ? timeToMinutes(end) - timeToMinutes(start) : 0

  const save = async () => {
    if (!block || !valid) return
    await db.timeBlocks.update(block.id, { start_time: start, end_time: end, label, task_id: taskId })
    onClose()
  }

  return (
    <>
      <Dialog
        open={!!block}
        onOpenChange={(o) => !o && onClose()}
        title="Edit block"
        footer={
          <>
            <Button
              variant="danger-ghost"
              className="mr-auto"
              onClick={async () => {
                if (!block) return
                if (await confirmDialog({ title: 'Delete this block?', confirmLabel: 'Delete', danger: true })) {
                  await db.timeBlocks.delete(block.id)
                  onClose()
                  toast('Block deleted')
                }
              }}
            >
              <Trash2 /> Delete
            </Button>
            <Button variant="secondary" disabled={!valid} onClick={() => void save()}>
              Save
            </Button>
            {(!task || task.status !== 'done') && (
              <Button
                variant="primary"
                disabled={!valid}
                onClick={async () => {
                  await save()
                  navigate(`/focus?${taskId ? `task=${taskId}&` : ''}minutes=${Math.min(180, duration)}`)
                }}
              >
                <Play className="fill-current" /> Focus
              </Button>
            )}
          </>
        }
      >
        <div className="space-y-4 pb-3">
          <div>
            <Label>Task</Label>
            <button onClick={() => setPicker(true)} className="flex h-10 w-full items-center rounded-[12px] border border-border bg-card-2/60 px-3.5 text-left text-sm">
              {task ? task.title : <span className="text-muted">No task — tap to choose</span>}
            </button>
          </div>
          {!task && (
            <div>
              <Label htmlFor="blabel">Label</Label>
              <Input id="blabel" value={label} onChange={(e) => setLabel(e.target.value)} placeholder="e.g. Deep work" />
            </div>
          )}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="bstart">Start</Label>
              <Input id="bstart" type="time" value={start} onChange={(e) => setStart(e.target.value)} />
            </div>
            <div>
              <Label htmlFor="bend">End</Label>
              <Input id="bend" type="time" value={end} onChange={(e) => setEnd(e.target.value)} />
            </div>
          </div>
          {!valid && <p className="text-xs text-warning">End time must be after start time.</p>}
        </div>
      </Dialog>
      <TaskPickerDialog open={picker} onOpenChange={setPicker} title="Choose task" allowNone noneLabel="No task" onPick={(t) => setTaskId(t?.id ?? null)} />
    </>
  )
}

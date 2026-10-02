import { DndContext, KeyboardSensor, MouseSensor, TouchSensor, closestCenter, useSensor, useSensors, type DragEndEvent } from '@dnd-kit/core'
import { SortableContext, arrayMove, sortableKeyboardCoordinates, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { GripVertical, Plus, RotateCcw, X } from 'lucide-react'
import { useEffect, useState, type ReactNode } from 'react'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { cn } from '@/lib/utils'

/** Text input that keeps local state and commits on blur / Enter. */
export function CommitInput({ value, onCommit, className, ...rest }: { value: string; onCommit: (v: string) => void } & Omit<React.InputHTMLAttributes<HTMLInputElement>, 'value' | 'onChange'>) {
  const [v, setV] = useState(value)
  useEffect(() => setV(value), [value])
  return (
    <Input
      {...rest}
      className={className}
      value={v}
      onChange={(e) => setV(e.target.value)}
      onBlur={() => v !== value && onCommit(v)}
      onKeyDown={(e) => e.key === 'Enter' && (e.target as HTMLInputElement).blur()}
    />
  )
}

export function NumberInput({ value, min, max, onCommit, suffix, className }: { value: number; min: number; max: number; onCommit: (n: number) => void; suffix?: string; className?: string }) {
  const [v, setV] = useState(String(value))
  useEffect(() => setV(String(value)), [value])
  const commit = () => {
    const n = Math.round(Number(v))
    if (!Number.isFinite(n)) return setV(String(value))
    const c = Math.min(max, Math.max(min, n))
    setV(String(c))
    if (c !== value) onCommit(c)
  }
  return (
    <div className={cn('flex items-center gap-2', className)}>
      <Input type="number" inputMode="numeric" min={min} max={max} value={v} onChange={(e) => setV(e.target.value)} onBlur={commit} onKeyDown={(e) => e.key === 'Enter' && commit()} className="tabular h-9 w-20 text-right" />
      {suffix && <span className="text-sm text-muted">{suffix}</span>}
    </div>
  )
}

export function TimeInput({ value, onCommit }: { value: string; onCommit: (v: string) => void }) {
  return <Input type="time" value={value} onChange={(e) => e.target.value && onCommit(e.target.value)} className="tabular h-9 w-[148px]" />
}

export function ResetButton({ label, onReset }: { label: string; onReset: () => Promise<void> | void }) {
  return (
    <Button
      variant="ghost"
      size="sm"
      onClick={async () => {
        if (await confirmDialog({ title: `Reset ${label} to defaults?`, confirmLabel: 'Reset' })) {
          await onReset()
          toast(`${label} reset`, { kind: 'success' })
        }
      }}
    >
      <RotateCcw /> Reset
    </Button>
  )
}

/** Generic drag-to-reorder list. */
export function SortableList<T extends { id: string }>({ items, onReorder, render }: { items: T[]; onReorder: (items: T[]) => void; render: (item: T, handle: ReactNode) => ReactNode }) {
  const sensors = useSensors(
    useSensor(MouseSensor, { activationConstraint: { distance: 4 } }),
    useSensor(TouchSensor, { activationConstraint: { delay: 120, tolerance: 6 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  )
  const onEnd = (e: DragEndEvent) => {
    if (!e.over || e.active.id === e.over.id) return
    const from = items.findIndex((i) => i.id === e.active.id)
    const to = items.findIndex((i) => i.id === e.over!.id)
    onReorder(arrayMove(items, from, to))
  }
  return (
    <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={onEnd}>
      <SortableContext items={items.map((i) => i.id)} strategy={verticalListSortingStrategy}>
        <ul className="space-y-1">
          {items.map((item) => (
            <SortableItem key={item.id} id={item.id}>
              {(handle) => render(item, handle)}
            </SortableItem>
          ))}
        </ul>
      </SortableContext>
    </DndContext>
  )
}

function SortableItem({ id, children }: { id: string; children: (handle: ReactNode) => ReactNode }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({ id })
  const handle = (
    <button className="flex h-9 w-6 shrink-0 cursor-grab touch-none items-center justify-center text-muted/70 active:cursor-grabbing" aria-label="Drag to reorder" {...attributes} {...listeners}>
      <GripVertical className="size-4" />
    </button>
  )
  return (
    <li ref={setNodeRef} style={{ transform: CSS.Translate.toString(transform), transition }} className={cn('relative rounded-[12px] bg-card', isDragging && 'z-10 shadow-lg ring-1 ring-border')}>
      {children(handle)}
    </li>
  )
}

/** Edit/add/remove/reorder a list of question strings. */
export function QuestionsEditor({ questions, onChange }: { questions: string[]; onChange: (q: string[]) => void }) {
  const [draft, setDraft] = useState('')
  const items = questions.map((q, i) => ({ id: `${i}:${q}`, q, i }))
  return (
    <div className="py-3">
      <SortableList
        items={items}
        onReorder={(next) => onChange(next.map((x) => x.q))}
        render={(item, handle) => (
          <div className="flex items-center gap-1.5">
            {handle}
            <CommitInput value={item.q} onCommit={(v) => onChange(questions.map((x, j) => (j === item.i ? v.trim() || x : x)))} className="h-9" aria-label="Question" />
            <Button variant="ghost" size="icon-sm" onClick={() => onChange(questions.filter((_, j) => j !== item.i))} aria-label="Remove question">
              <X />
            </Button>
          </div>
        )}
      />
      {questions.length === 0 && <p className="py-2 text-sm text-muted">No questions. The review will show stats and priorities only.</p>}
      <form
        className="mt-2 flex gap-2 pl-7"
        onSubmit={(e) => {
          e.preventDefault()
          if (!draft.trim()) return
          onChange([...questions, draft.trim()])
          setDraft('')
        }}
      >
        <Input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="Add a question" className="h-9" />
        <Button type="submit" variant="secondary" size="icon" className="size-9" disabled={!draft.trim()} aria-label="Add question">
          <Plus />
        </Button>
      </form>
    </div>
  )
}

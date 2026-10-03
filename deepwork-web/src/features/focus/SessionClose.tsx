import { motion } from 'framer-motion'
import { Plus, X } from 'lucide-react'
import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/db'
import type { SessionResult } from '@/db/types'
import { useSettings } from '@/state/settings'
import { useFocus } from '@/state/focus'
import { Button } from '@/components/ui/button'
import { Input, Textarea } from '@/components/ui/input'
import { Switch } from '@/components/ui/switch'
import { cn } from '@/lib/utils'

const RESULT_LABELS: Record<'done' | 'partly' | 'stuck', { label: string; hint: string }> = {
  done: { label: 'Done', hint: 'Finished what I set out to do' },
  partly: { label: 'Partly done', hint: 'Made progress' },
  stuck: { label: 'Stuck', hint: 'Hit a wall' },
}

export function SessionClose() {
  const { settings } = useSettings()
  const { state, close } = useFocus()
  const cfg = settings.sessionClose
  const options = (['done', 'partly', 'stuck'] as const).filter((r) => cfg.results[r])
  const [result, setResult] = useState<SessionResult | null>(options.length === 1 ? options[0] : null)
  const [note, setNote] = useState('')
  const [steps, setSteps] = useState<string[]>([''])
  const task = useLiveQuery(() => (state.taskId ? db.tasks.get(state.taskId) : undefined), [state.taskId])
  const [markDone, setMarkDone] = useState(false)
  const [saving, setSaving] = useState(false)

  const effectiveResult: SessionResult = result ?? (options.length === 0 ? 'done' : 'done')
  const noteMissing = cfg.note === 'required' && !note.trim()
  const canSave = (options.length === 0 || !!result) && !noteMissing && !saving
  const showStuck = result === 'stuck' && cfg.stuckPrompt

  const save = async () => {
    setSaving(true)
    await close({
      result: effectiveResult,
      note: cfg.note === 'hidden' ? '' : note.trim(),
      markTaskDone: markDone,
      nextSteps: showStuck ? steps : [],
    })
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: 'spring', stiffness: 260, damping: 26, delay: 0.2 }}
      className="card pad mx-auto w-full max-w-md"
    >
      <h2 className="font-semibold tracking-tight">Session complete</h2>
      <p className="mt-0.5 text-sm text-muted">How did it go?</p>

      {options.length > 0 && (
        <div className={cn('mt-4 grid gap-2', options.length === 3 ? 'grid-cols-3' : options.length === 2 ? 'grid-cols-2' : 'grid-cols-1')}>
          {options.map((r) => (
            <button
              key={r}
              onClick={() => {
                setResult(r)
                if (r === 'done' && task && task.status !== 'done') setMarkDone(false)
              }}
              className={cn(
                'rounded-[12px] border px-2 py-3 text-center transition-all active:scale-95',
                result === r
                  ? r === 'done'
                    ? 'border-success/50 bg-success/10 text-success'
                    : r === 'stuck'
                      ? 'border-warning/50 bg-warning/10 text-warning'
                      : 'border-accent/50 bg-accent-soft text-accent'
                  : 'border-border bg-card-2/60 hover:bg-card-2',
              )}
            >
              <div className="text-sm font-semibold">{RESULT_LABELS[r].label}</div>
              <div className="mt-0.5 hidden text-[11px] text-muted sm:block">{RESULT_LABELS[r].hint}</div>
            </button>
          ))}
        </div>
      )}

      {cfg.note !== 'hidden' && (
        <div className="mt-4">
          <label className="mb-1.5 block text-[13px] font-medium text-muted">
            What did I get done? {cfg.note === 'optional' && <span className="font-normal">(optional)</span>}
          </label>
          <Textarea value={note} onChange={(e) => setNote(e.target.value)} placeholder="A sentence is enough." className="min-h-[72px]" />
        </div>
      )}

      {showStuck && (
        <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} className="mt-4 overflow-hidden">
          <label className="mb-1.5 block text-[13px] font-medium text-muted">What's the smallest next step?</label>
          <div className="space-y-2">
            {steps.map((s, i) => (
              <div key={i} className="flex gap-2">
                <Input
                  value={s}
                  autoFocus={i === steps.length - 1 && i > 0}
                  onChange={(e) => setSteps((arr) => arr.map((x, j) => (j === i ? e.target.value : x)))}
                  placeholder={i === 0 ? 'e.g. Write the first heading' : 'Another step'}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      setSteps((arr) => [...arr, ''])
                    }
                  }}
                />
                {steps.length > 1 && (
                  <Button variant="ghost" size="icon" onClick={() => setSteps((arr) => arr.filter((_, j) => j !== i))} aria-label="Remove step">
                    <X />
                  </Button>
                )}
              </div>
            ))}
          </div>
          <button className="mt-2 inline-flex items-center gap-1 text-[13px] font-medium text-accent" onClick={() => setSteps((arr) => [...arr, ''])}>
            <Plus className="size-3.5" /> Add step
          </button>
          <p className="mt-1.5 text-xs text-muted">Each step becomes a task{settings.modules.priorities ? '; the first is added to today’s priorities' : ''}.</p>
        </motion.div>
      )}

      {task && task.status !== 'done' && (
        <div className="mt-4 flex items-center justify-between rounded-[12px] bg-card-2/60 px-3 py-2.5">
          <span className="min-w-0 truncate text-sm">Mark “{task.title}” complete</span>
          <Switch checked={markDone} onCheckedChange={setMarkDone} aria-label="Mark task complete" />
        </div>
      )}

      <Button variant="primary" size="lg" className="mt-5 w-full" disabled={!canSave} onClick={() => void save()}>
        Save session
      </Button>
    </motion.div>
  )
}

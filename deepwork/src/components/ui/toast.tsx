import { AnimatePresence, motion } from 'framer-motion'
import { CheckCircle2, Info, TriangleAlert } from 'lucide-react'
import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

type ToastKind = 'info' | 'success' | 'error'
interface ToastItem {
  id: number
  message: string
  kind: ToastKind
  action?: { label: string; onClick: () => void }
}

let nextId = 1
const listeners = new Set<(t: ToastItem[]) => void>()
let items: ToastItem[] = []

function emit() {
  for (const l of listeners) l(items)
}

export function toast(message: string, opts: { kind?: ToastKind; action?: ToastItem['action']; duration?: number } = {}) {
  const item: ToastItem = { id: nextId++, message, kind: opts.kind ?? 'info', action: opts.action }
  items = [...items.slice(-2), item]
  emit()
  setTimeout(() => {
    items = items.filter((t) => t.id !== item.id)
    emit()
  }, opts.duration ?? 3800)
}

export function Toaster() {
  const [list, setList] = useState<ToastItem[]>(items)
  useEffect(() => {
    listeners.add(setList)
    return () => void listeners.delete(setList)
  }, [])
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-[calc(76px+env(safe-area-inset-bottom))] z-[120] flex flex-col items-center gap-2 px-4 md:bottom-6">
      <AnimatePresence initial={false}>
        {list.map((t) => (
          <motion.div
            key={t.id}
            layout
            initial={{ opacity: 0, y: 16, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8, scale: 0.98 }}
            transition={{ type: 'spring', stiffness: 500, damping: 36 }}
            className="glass pointer-events-auto flex max-w-md items-center gap-3 rounded-2xl border border-border px-4 py-3 text-sm shadow-xl"
            role="status"
          >
            {t.kind === 'success' ? (
              <CheckCircle2 className="size-4 shrink-0 text-success" />
            ) : t.kind === 'error' ? (
              <TriangleAlert className="size-4 shrink-0 text-warning" />
            ) : (
              <Info className="size-4 shrink-0 text-accent" />
            )}
            <span className="min-w-0 flex-1">{t.message}</span>
            {t.action && (
              <button
                className={cn('shrink-0 rounded-lg px-2 py-1 text-[13px] font-semibold text-accent hover:bg-accent-soft')}
                onClick={() => {
                  t.action!.onClick()
                  items = items.filter((x) => x.id !== t.id)
                  emit()
                }}
              >
                {t.action.label}
              </button>
            )}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  )
}

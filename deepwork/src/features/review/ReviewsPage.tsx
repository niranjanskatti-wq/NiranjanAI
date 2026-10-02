import { format, parseISO } from 'date-fns'
import { ChevronDown, NotebookPen, Trash2 } from 'lucide-react'
import { AnimatePresence, motion } from 'framer-motion'
import { useState } from 'react'
import { useNavigate } from 'react-router'
import { db } from '@/db'
import type { Review } from '@/db/types'
import { useSettings } from '@/state/settings'
import { useReviews } from '@/hooks/data'
import { Page } from '@/components/shared/Page'
import { Button } from '@/components/ui/button'
import { Segmented } from '@/components/ui/segmented'
import { EmptyState, LoadingBlock, PageHeader } from '@/components/ui/empty'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { cn } from '@/lib/utils'

export default function ReviewsPage() {
  const { settings } = useSettings()
  const navigate = useNavigate()
  const reviews = useReviews()
  const both = settings.modules.eveningReview && settings.modules.weeklyReview
  const [type, setType] = useState<'all' | 'daily' | 'weekly'>('all')
  const visibleTypes = new Set<string>([...(settings.modules.eveningReview ? ['daily'] : []), ...(settings.modules.weeklyReview ? ['weekly'] : [])])
  const list = (reviews ?? []).filter((r) => visibleTypes.has(r.type) && (type === 'all' || r.type === type))

  return (
    <Page>
      <PageHeader title="Reviews" subtitle="Your review history." />
      <div className="mb-5 flex flex-wrap gap-2">
        {settings.modules.eveningReview && (
          <Button variant="primary" onClick={() => navigate('/review/evening')}>
            <NotebookPen /> Evening review
          </Button>
        )}
        {settings.modules.weeklyReview && (
          <Button variant="secondary" onClick={() => navigate('/review/weekly')}>
            <NotebookPen /> Weekly review
          </Button>
        )}
      </div>
      {both && (
        <Segmented
          className="mb-4"
          value={type}
          onChange={setType}
          options={[
            { value: 'all', label: 'All' },
            { value: 'daily', label: 'Evening' },
            { value: 'weekly', label: 'Weekly' },
          ]}
        />
      )}
      {!reviews ? (
        <LoadingBlock className="h-40" />
      ) : list.length === 0 ? (
        <div className="card">
          <EmptyState icon={<NotebookPen />} title="No reviews yet" description="Reviews you save will be listed here so you can look back on them." />
        </div>
      ) : (
        <ul className="space-y-2">
          {list.map((r) => (
            <ReviewItem key={r.id} review={r} />
          ))}
        </ul>
      )}
    </Page>
  )
}

function ReviewItem({ review }: { review: Review }) {
  const [open, setOpen] = useState(false)
  const answered = review.answers.filter((a) => a.answer)
  return (
    <li className="card overflow-hidden">
      <button className="flex w-full items-center gap-3 px-[var(--pad)] py-4 text-left" onClick={() => setOpen((o) => !o)} aria-expanded={open}>
        <span className={cn('rounded-full px-2 py-0.5 text-[11px] font-semibold', review.type === 'weekly' ? 'bg-accent-soft text-accent' : 'bg-card-2 text-muted')}>
          {review.type === 'weekly' ? 'Weekly' : 'Evening'}
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-[15px] font-medium">{format(parseISO(review.date), 'EEEE, MMM d, yyyy')}</span>
          {!open && answered[0] && <span className="block truncate text-[13px] text-muted">{answered[0].answer}</span>}
        </span>
        <ChevronDown className={cn('size-4 shrink-0 text-muted transition-transform', open && 'rotate-180')} />
      </button>
      <AnimatePresence initial={false}>
        {open && (
          <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: 'auto', opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="overflow-hidden">
            <div className="space-y-3 border-t border-border/70 px-[var(--pad)] py-4">
              {review.stats && (
                <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                  {review.stats.focus_minutes !== undefined && <span>Focus {review.stats.focus_minutes} min</span>}
                  {review.stats.planned !== undefined && (
                    <span>
                      {review.stats.done}/{review.stats.planned} planned done
                    </span>
                  )}
                  {review.stats.tasks_done !== undefined && <span>{review.stats.tasks_done} tasks done</span>}
                  {review.stats.distractions !== undefined && <span>{review.stats.distractions} distractions</span>}
                  {review.stats.best_time ? <span>Best time {review.stats.best_time}</span> : null}
                </div>
              )}
              {review.answers.map((a, i) => (
                <div key={i}>
                  <p className="text-[13px] font-medium text-muted">{a.question}</p>
                  <p className="mt-0.5 whitespace-pre-wrap text-sm">{a.answer || <span className="text-muted">—</span>}</p>
                </div>
              ))}
              {review.next_priorities.length > 0 && (
                <div>
                  <p className="text-[13px] font-medium text-muted">Next priorities</p>
                  <ol className="mt-0.5 list-inside list-decimal text-sm">
                    {review.next_priorities.map((p) => (
                      <li key={p.task_id}>{p.title}</li>
                    ))}
                  </ol>
                </div>
              )}
              <div className="flex justify-end">
                <Button
                  variant="danger-ghost"
                  size="sm"
                  onClick={async () => {
                    if (await confirmDialog({ title: 'Delete this review?', confirmLabel: 'Delete', danger: true })) {
                      await db.reviews.delete(review.id)
                      toast('Review deleted')
                    }
                  }}
                >
                  <Trash2 /> Delete
                </Button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </li>
  )
}

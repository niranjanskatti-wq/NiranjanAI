import { motion } from 'framer-motion'
import { cn } from '@/lib/utils'

export function ProgressBar({ value, className, color = 'var(--accent)' }: { value: number; className?: string; color?: string }) {
  return (
    <div className={cn('h-1.5 w-full overflow-hidden rounded-full bg-border/70', className)}>
      <motion.div
        className="h-full rounded-full"
        style={{ background: color }}
        initial={false}
        animate={{ width: `${Math.max(0, Math.min(1, value)) * 100}%` }}
        transition={{ type: 'spring', stiffness: 120, damping: 24 }}
      />
    </div>
  )
}

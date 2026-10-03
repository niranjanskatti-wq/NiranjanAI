import { motion } from 'framer-motion'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

export function Page({ children, className, wide }: { children: ReactNode; className?: string; wide?: boolean }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
      className={cn('mx-auto w-full px-4 pb-10 pt-6 safe-top sm:px-6 md:pt-10', wide ? 'max-w-6xl' : 'max-w-3xl', className)}
    >
      {children}
    </motion.div>
  )
}

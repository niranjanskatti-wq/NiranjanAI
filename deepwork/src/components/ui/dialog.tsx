import * as DialogPrimitive from '@radix-ui/react-dialog'
import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

/** A glassy modal that presents as a bottom sheet on phones and a centered dialog on larger screens. */
export function Dialog({
  open,
  onOpenChange,
  title,
  description,
  children,
  footer,
  className,
  hideClose,
  dismissible = true,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: ReactNode
  description?: ReactNode
  children?: ReactNode
  footer?: ReactNode
  className?: string
  hideClose?: boolean
  dismissible?: boolean
}) {
  return (
    <DialogPrimitive.Root open={open} onOpenChange={(o) => (dismissible || o ? onOpenChange(o) : undefined)}>
      <AnimatePresence>
        {open && (
          <DialogPrimitive.Portal forceMount>
            <DialogPrimitive.Overlay asChild forceMount>
              <motion.div
                className="fixed inset-0 z-[80] bg-black/45 backdrop-blur-[2px]"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.18 }}
              />
            </DialogPrimitive.Overlay>
            <DialogPrimitive.Content
              asChild
              forceMount
              onPointerDownOutside={(e) => !dismissible && e.preventDefault()}
              onEscapeKeyDown={(e) => !dismissible && e.preventDefault()}
              aria-describedby={description ? undefined : undefined}
            >
              <motion.div
                className={cn(
                  'glass fixed inset-x-0 bottom-0 z-[90] flex max-h-[92dvh] flex-col rounded-t-[22px] border border-border shadow-2xl focus:outline-none',
                  'sm:inset-auto sm:left-1/2 sm:top-1/2 sm:w-[min(520px,calc(100vw-32px))] sm:-translate-x-1/2 sm:-translate-y-1/2 sm:rounded-[20px]',
                  className,
                )}
                initial={{ opacity: 0, y: 40, scale: 0.98 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 30, scale: 0.98 }}
                transition={{ type: 'spring', stiffness: 420, damping: 36 }}
              >
                <div className="mx-auto mt-2 h-1 w-10 rounded-full bg-border sm:hidden" />
                <div className="flex items-start justify-between gap-4 px-5 pb-2 pt-4 sm:px-6 sm:pt-5">
                  <div>
                    <DialogPrimitive.Title className="text-lg font-semibold tracking-tight">{title}</DialogPrimitive.Title>
                    {description ? (
                      <DialogPrimitive.Description className="mt-1 text-sm text-muted">{description}</DialogPrimitive.Description>
                    ) : (
                      <DialogPrimitive.Description className="sr-only">{typeof title === 'string' ? title : 'Dialog'}</DialogPrimitive.Description>
                    )}
                  </div>
                  {!hideClose && dismissible && (
                    <DialogPrimitive.Close className="-mr-1 rounded-lg p-1.5 text-muted transition-colors hover:bg-card-2 hover:text-fg" aria-label="Close">
                      <X className="size-4" />
                    </DialogPrimitive.Close>
                  )}
                </div>
                <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-4 sm:px-6">{children}</div>
                {footer && <div className="flex flex-wrap justify-end gap-2 border-t border-border px-5 py-3.5 safe-bottom sm:px-6">{footer}</div>}
              </motion.div>
            </DialogPrimitive.Content>
          </DialogPrimitive.Portal>
        )}
      </AnimatePresence>
    </DialogPrimitive.Root>
  )
}

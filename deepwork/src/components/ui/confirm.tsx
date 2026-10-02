import { useEffect, useState } from 'react'
import { Dialog } from './dialog'
import { Button } from './button'
import { Input } from './input'

interface ConfirmOptions {
  title: string
  description?: string
  confirmLabel?: string
  cancelLabel?: string
  danger?: boolean
  /** When set, the user must type this word to enable the confirm button. */
  typeToConfirm?: string
}

interface Pending extends ConfirmOptions {
  resolve: (ok: boolean) => void
}

let setPendingGlobal: ((p: Pending | null) => void) | null = null

export function confirmDialog(opts: ConfirmOptions): Promise<boolean> {
  return new Promise((resolve) => {
    if (!setPendingGlobal) return resolve(window.confirm(opts.title))
    setPendingGlobal({ ...opts, resolve })
  })
}

export function ConfirmHost() {
  const [pending, setPending] = useState<Pending | null>(null)
  const [typed, setTyped] = useState('')
  useEffect(() => {
    setPendingGlobal = (p) => {
      setTyped('')
      setPending(p)
    }
    return () => {
      setPendingGlobal = null
    }
  }, [])

  const close = (ok: boolean) => {
    pending?.resolve(ok)
    setPending(null)
  }
  const blocked = !!pending?.typeToConfirm && typed.trim().toUpperCase() !== pending.typeToConfirm.toUpperCase()

  return (
    <Dialog
      open={!!pending}
      onOpenChange={(o) => !o && close(false)}
      title={pending?.title ?? ''}
      description={pending?.description}
      footer={
        <>
          <Button variant="ghost" onClick={() => close(false)}>
            {pending?.cancelLabel ?? 'Cancel'}
          </Button>
          <Button variant={pending?.danger ? 'danger' : 'primary'} disabled={blocked} onClick={() => close(true)}>
            {pending?.confirmLabel ?? 'Confirm'}
          </Button>
        </>
      }
    >
      {pending?.typeToConfirm && (
        <div className="pb-2">
          <p className="mb-2 text-sm text-muted">
            Type <span className="font-mono font-semibold text-fg">{pending.typeToConfirm}</span> to confirm.
          </p>
          <Input autoFocus value={typed} onChange={(e) => setTyped(e.target.value)} placeholder={pending.typeToConfirm} />
        </div>
      )}
    </Dialog>
  )
}

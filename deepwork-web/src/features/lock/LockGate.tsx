import { AnimatePresence, motion } from 'framer-motion'
import { Delete, Fingerprint, Lock } from 'lucide-react'
import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react'
import { useSettings } from '@/state/settings'
import { useFocus } from '@/state/focus'
import { verifyBiometric, verifyPin } from '@/lib/lock'
import { cn } from '@/lib/utils'
import { Logo } from '@/components/layout/Logo'

export function LockGate({ children }: { children: ReactNode }) {
  const { settings } = useSettings()
  const { state: focus } = useFocus()
  const lock = settings.lock
  const active = lock.enabled && !!lock.pinHash
  const [locked, setLocked] = useState(active)
  const lastActivity = useRef(Date.now())
  const hiddenAt = useRef<number | null>(null)
  const focusBusy = focus.phase === 'running' || focus.phase === 'paused' || focus.phase === 'break'

  useEffect(() => {
    if (!active) setLocked(false)
  }, [active])

  useEffect(() => {
    if (!active) return
    const bump = () => (lastActivity.current = Date.now())
    const events = ['pointerdown', 'keydown', 'wheel', 'touchstart']
    events.forEach((e) => window.addEventListener(e, bump, { passive: true }))
    const iv = setInterval(() => {
      if (lock.autoLockMinutes > 0 && !focusBusy && Date.now() - lastActivity.current > lock.autoLockMinutes * 60_000) setLocked(true)
    }, 10_000)
    const onVis = () => {
      if (document.visibilityState === 'hidden') hiddenAt.current = Date.now()
      else if (hiddenAt.current) {
        const away = Date.now() - hiddenAt.current
        if (lock.autoLockMinutes === 0 || away > lock.autoLockMinutes * 60_000) setLocked(true)
        hiddenAt.current = null
        lastActivity.current = Date.now()
      }
    }
    document.addEventListener('visibilitychange', onVis)
    return () => {
      events.forEach((e) => window.removeEventListener(e, bump))
      clearInterval(iv)
      document.removeEventListener('visibilitychange', onVis)
    }
  }, [active, lock.autoLockMinutes, focusBusy])

  const unlock = useCallback(() => {
    lastActivity.current = Date.now()
    setLocked(false)
  }, [])

  return (
    <>
      <div aria-hidden={locked} className={cn(locked && 'pointer-events-none select-none blur-xl')} inert={locked}>
        {children}
      </div>
      <AnimatePresence>{locked && <LockScreen onUnlock={unlock} />}</AnimatePresence>
    </>
  )
}

function LockScreen({ onUnlock }: { onUnlock: () => void }) {
  const { settings } = useSettings()
  const { pinLength, pinSalt, pinHash, biometric, credentialId } = settings.lock
  const [pin, setPin] = useState('')
  const [error, setError] = useState(false)
  const [checking, setChecking] = useState(false)

  const tryBio = useCallback(async () => {
    if (!biometric || !credentialId) return
    if (await verifyBiometric(credentialId)) onUnlock()
  }, [biometric, credentialId, onUnlock])

  useEffect(() => {
    if (pin.length < pinLength) return
    setChecking(true)
    void verifyPin(pin, pinSalt, pinHash).then((ok) => {
      setChecking(false)
      if (ok) onUnlock()
      else {
        setError(true)
        setTimeout(() => {
          setPin('')
          setError(false)
        }, 550)
      }
    })
  }, [pin, pinLength, pinSalt, pinHash, onUnlock])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (/^\d$/.test(e.key)) setPin((p) => (p.length < pinLength ? p + e.key : p))
      else if (e.key === 'Backspace') setPin((p) => p.slice(0, -1))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [pinLength])

  const press = (d: string) => !checking && setPin((p) => (p.length < pinLength ? p + d : p))

  return (
    <motion.div
      className="fixed inset-0 z-[200] flex flex-col items-center justify-center bg-bg/90 px-6 backdrop-blur-2xl"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, scale: 1.02 }}
      transition={{ duration: 0.25 }}
    >
      <Logo className="mb-5 size-12" />
      <div className="flex items-center gap-2 text-sm text-muted">
        <Lock className="size-3.5" /> Enter your PIN
      </div>
      <motion.div className="mt-6 flex gap-3.5" animate={error ? { x: [0, -10, 10, -6, 6, 0] } : { x: 0 }} transition={{ duration: 0.4 }}>
        {Array.from({ length: pinLength }).map((_, i) => (
          <span
            key={i}
            className={cn('size-3.5 rounded-full border-2 transition-all duration-150', i < pin.length ? (error ? 'border-danger bg-danger' : 'scale-110 border-accent bg-accent') : 'border-border')}
          />
        ))}
      </motion.div>
      <div className="mt-10 grid grid-cols-3 gap-4">
        {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((d) => (
          <Key key={d} onClick={() => press(d)}>
            {d}
          </Key>
        ))}
        {biometric && credentialId ? (
          <Key onClick={() => void tryBio()} aria-label="Unlock with biometrics" subtle>
            <Fingerprint className="size-6" />
          </Key>
        ) : (
          <span />
        )}
        <Key onClick={() => press('0')}>0</Key>
        <Key onClick={() => setPin((p) => p.slice(0, -1))} aria-label="Delete" subtle>
          <Delete className="size-5" />
        </Key>
      </div>
    </motion.div>
  )
}

function Key({ children, onClick, subtle, ...rest }: { children: ReactNode; onClick: () => void; subtle?: boolean; 'aria-label'?: string }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'tabular flex size-[72px] items-center justify-center rounded-full text-2xl font-medium transition-all active:scale-90',
        subtle ? 'text-muted hover:text-fg' : 'border border-border bg-card hover:bg-card-2',
      )}
      {...rest}
    >
      {children}
    </button>
  )
}

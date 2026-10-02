import { useEffect, useState } from 'react'
import { useSettings } from '@/state/settings'
import { biometricsAvailable, hashPin, newSalt, registerBiometric, verifyPin } from '@/lib/lock'
import { Row, Section } from '@/components/ui/row'
import { Switch } from '@/components/ui/switch'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'
import { Input, Select } from '@/components/ui/input'
import { Segmented } from '@/components/ui/segmented'
import { isNative } from '@/lib/native'
import { toast } from '@/components/ui/toast'

export function PrivacySection() {
  const { settings, update } = useSettings()
  const lock = settings.lock
  const [setupOpen, setSetupOpen] = useState(false)
  const [verify, setVerify] = useState<null | 'disable' | 'change'>(null)
  const [bioAvail, setBioAvail] = useState(false)
  useEffect(() => {
    void biometricsAvailable().then(setBioAvail)
  }, [])
  const enabled = lock.enabled && !!lock.pinHash

  return (
    <>
      <Section title="App lock">
        <Row label="Require PIN to open" description="4–6 digits, stored only as a salted hash on this device.">
          <Switch
            checked={enabled}
            onCheckedChange={(v) => (v ? setSetupOpen(true) : setVerify('disable'))}
            aria-label="App lock"
          />
        </Row>
        {enabled && (
          <>
            <Row label="Change PIN">
              <Button variant="secondary" size="sm" onClick={() => setVerify('change')}>
                Change
              </Button>
            </Row>
            <Row
              label="Unlock with biometrics"
              description={
                bioAvail
                  ? isNative
                    ? 'Fingerprint or face unlock. Your PIN still works.'
                    : 'Face ID, Touch ID, Windows Hello or fingerprint. Your PIN still works.'
                  : isNative
                    ? 'No fingerprint or face unlock is set up on this phone.'
                    : 'Not available on this device or browser (requires HTTPS and a platform authenticator).'
              }
            >
              <Switch
                checked={lock.biometric && !!lock.credentialId}
                disabled={!bioAvail}
                onCheckedChange={async (v) => {
                  if (!v) return update((s) => void ((s.lock.biometric = false), (s.lock.credentialId = null)))
                  try {
                    const id = await registerBiometric()
                    await update((s) => {
                      s.lock.biometric = true
                      s.lock.credentialId = id
                    })
                    toast('Biometric unlock enabled', { kind: 'success' })
                  } catch (e) {
                    toast(e instanceof Error ? e.message : 'Biometric setup failed', { kind: 'error' })
                  }
                }}
                aria-label="Biometric unlock"
              />
            </Row>
            <Row label="Auto-lock" description="After inactivity, or when you leave the app for that long.">
              <Select value={lock.autoLockMinutes} onChange={(e) => void update((s) => void (s.lock.autoLockMinutes = Number(e.target.value)))} className="w-[170px]">
                <option value={0}>When app is hidden</option>
                <option value={1}>After 1 minute</option>
                <option value={5}>After 5 minutes</option>
                <option value={15}>After 15 minutes</option>
                <option value={30}>After 30 minutes</option>
                <option value={60}>After 1 hour</option>
              </Select>
            </Row>
          </>
        )}
      </Section>

      <Section title="Your data">
        <div className="space-y-2 py-4 text-sm text-muted">
          <p>Everything you create in Deepwork is stored on this device. There are no accounts, no analytics and no servers.</p>
          <p>The only network activity is the optional weekly backup, which sends a single JSON file directly from this device to a folder in your own Google Drive. The app can only see files it created.</p>
          <p>Backups never include your PIN, biometric registration or Google sign-in token.</p>
        </div>
      </Section>

      <PinSetupDialog
        open={setupOpen}
        onOpenChange={setSetupOpen}
        onDone={async (pin) => {
          const salt = newSalt()
          const hash = await hashPin(pin, salt)
          await update((s) => {
            s.lock.enabled = true
            s.lock.pinHash = hash
            s.lock.pinSalt = salt
            s.lock.pinLength = pin.length
          })
          toast('App lock is on', { kind: 'success' })
        }}
      />
      <VerifyPinDialog
        open={verify !== null}
        onOpenChange={(o) => !o && setVerify(null)}
        title={verify === 'disable' ? 'Turn off app lock' : 'Change PIN'}
        onVerified={async () => {
          if (verify === 'disable') {
            await update((s) => {
              s.lock.enabled = false
              s.lock.pinHash = null
              s.lock.pinSalt = null
              s.lock.biometric = false
              s.lock.credentialId = null
            })
            toast('App lock is off')
            setVerify(null)
          } else {
            setVerify(null)
            setSetupOpen(true)
          }
        }}
      />
    </>
  )
}

function PinSetupDialog({ open, onOpenChange, onDone }: { open: boolean; onOpenChange: (o: boolean) => void; onDone: (pin: string) => Promise<void> }) {
  const [len, setLen] = useState(4)
  const [pin, setPin] = useState('')
  const [confirm, setConfirm] = useState('')
  const [step, setStep] = useState<1 | 2>(1)
  useEffect(() => {
    if (open) {
      setPin('')
      setConfirm('')
      setStep(1)
    }
  }, [open])
  const mismatch = step === 2 && confirm.length === len && confirm !== pin

  return (
    <Dialog
      open={open}
      onOpenChange={onOpenChange}
      title={step === 1 ? 'Choose a PIN' : 'Confirm your PIN'}
      description={step === 1 ? 'You will enter it each time the app locks.' : 'Enter the same PIN again.'}
      footer={
        <>
          <Button variant="ghost" onClick={() => (step === 2 ? setStep(1) : onOpenChange(false))}>
            {step === 2 ? 'Back' : 'Cancel'}
          </Button>
          {step === 1 ? (
            <Button variant="primary" disabled={pin.length !== len} onClick={() => setStep(2)}>
              Next
            </Button>
          ) : (
            <Button
              variant="primary"
              disabled={confirm !== pin}
              onClick={async () => {
                await onDone(pin)
                onOpenChange(false)
              }}
            >
              Turn on
            </Button>
          )}
        </>
      }
    >
      <div className="space-y-4 pb-3">
        {step === 1 && (
          <Segmented
            value={len}
            onChange={(v) => {
              setLen(v)
              setPin((p) => p.slice(0, v))
            }}
            options={[4, 5, 6].map((n) => ({ value: n, label: `${n} digits` }))}
          />
        )}
        <Input
          key={step}
          autoFocus
          type="password"
          inputMode="numeric"
          autoComplete="off"
          maxLength={len}
          value={step === 1 ? pin : confirm}
          onChange={(e) => {
            const v = e.target.value.replace(/\D/g, '').slice(0, len)
            if (step === 1) setPin(v)
            else setConfirm(v)
          }}
          className="tabular h-12 text-center text-2xl tracking-[0.5em]"
          aria-label="PIN"
        />
        {mismatch && <p className="text-sm text-warning">PINs don't match.</p>}
      </div>
    </Dialog>
  )
}

function VerifyPinDialog({ open, onOpenChange, title, onVerified }: { open: boolean; onOpenChange: (o: boolean) => void; title: string; onVerified: () => Promise<void> }) {
  const { settings } = useSettings()
  const [pin, setPin] = useState('')
  const [error, setError] = useState(false)
  useEffect(() => {
    if (open) {
      setPin('')
      setError(false)
    }
  }, [open])
  const check = async () => {
    if (await verifyPin(pin, settings.lock.pinSalt, settings.lock.pinHash)) await onVerified()
    else {
      setError(true)
      setPin('')
    }
  }
  return (
    <Dialog
      open={open}
      onOpenChange={onOpenChange}
      title={title}
      description="Enter your current PIN."
      footer={
        <>
          <Button variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button variant="primary" disabled={pin.length < 4} onClick={() => void check()}>
            Continue
          </Button>
        </>
      }
    >
      <div className="pb-3">
        <Input
          autoFocus
          type="password"
          inputMode="numeric"
          maxLength={6}
          value={pin}
          onChange={(e) => setPin(e.target.value.replace(/\D/g, '').slice(0, 6))}
          onKeyDown={(e) => e.key === 'Enter' && void check()}
          className="tabular h-12 text-center text-2xl tracking-[0.5em]"
          aria-label="Current PIN"
        />
        {error && <p className="mt-2 text-sm text-warning">That PIN isn't right.</p>}
      </div>
    </Dialog>
  )
}

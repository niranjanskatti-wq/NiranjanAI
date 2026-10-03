import { useEffect, useState } from 'react'
import { Download } from 'lucide-react'
import { Row, Section } from '@/components/ui/row'
import { Button } from '@/components/ui/button'
import { useOnline } from '@/hooks/useMediaQuery'
import { SCHEMA_VERSION } from '@/lib/data'
import { Logo } from '@/components/layout/Logo'
import { toast } from '@/components/ui/toast'

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

let deferredPrompt: BeforeInstallPromptEvent | null = null
if (typeof window !== 'undefined') {
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault()
    deferredPrompt = e as BeforeInstallPromptEvent
  })
}

export function AboutSection() {
  const online = useOnline()
  const [storage, setStorage] = useState<{ usage: number; quota: number } | null>(null)
  const [persisted, setPersisted] = useState<boolean | null>(null)
  const [canInstall, setCanInstall] = useState(!!deferredPrompt)
  const standalone = window.matchMedia('(display-mode: standalone)').matches || (navigator as unknown as { standalone?: boolean }).standalone === true
  const swActive = 'serviceWorker' in navigator && !!navigator.serviceWorker.controller

  useEffect(() => {
    void navigator.storage?.estimate?.().then((e) => setStorage({ usage: e.usage ?? 0, quota: e.quota ?? 0 }))
    void navigator.storage?.persisted?.().then(setPersisted)
    const iv = setInterval(() => setCanInstall(!!deferredPrompt), 1000)
    return () => clearInterval(iv)
  }, [])

  const mb = (n: number) => (n / 1024 / 1024).toFixed(n > 1024 * 1024 * 10 ? 0 : 1)

  return (
    <>
      <div className="card pad mb-6 flex items-center gap-4">
        <Logo className="size-12" />
        <div>
          <p className="text-lg font-semibold tracking-tight">Deepwork</p>
          <p className="text-sm text-muted">Version {__APP_VERSION__} · data schema v{SCHEMA_VERSION}</p>
        </div>
      </div>

      <Section title="This device">
        <Row label="Connection" description={online ? 'Online' : 'Offline — everything except Drive backup works normally.'} />
        <Row label="Offline ready" description={swActive ? 'The app is cached for offline use.' : 'Offline cache installs after the first load of the production build.'} />
        <Row label="Installed" description={standalone ? 'Running as an installed app.' : 'Running in a browser tab.'}>
          {!standalone && canInstall && (
            <Button
              variant="secondary"
              size="sm"
              onClick={async () => {
                if (!deferredPrompt) return
                await deferredPrompt.prompt()
                const r = await deferredPrompt.userChoice
                deferredPrompt = null
                setCanInstall(false)
                if (r.outcome === 'accepted') toast('Installing Deepwork', { kind: 'success' })
              }}
            >
              <Download /> Install
            </Button>
          )}
        </Row>
        {storage && <Row label="Storage used" description={`${mb(storage.usage)} MB of ~${mb(storage.quota)} MB available`} />}
        <Row label="Persistent storage" description={persisted ? 'Granted — the browser won’t clear your data under storage pressure.' : 'Ask the browser not to evict your data when space is low.'}>
          {persisted === false && (
            <Button
              variant="secondary"
              size="sm"
              onClick={async () => {
                const ok = (await navigator.storage?.persist?.()) ?? false
                setPersisted(ok)
                toast(ok ? 'Storage is now persistent' : 'The browser declined. Installing the app usually helps.', { kind: ok ? 'success' : 'info' })
              }}
            >
              Request
            </Button>
          )}
        </Row>
      </Section>

      <Section title="Principles">
        <div className="space-y-2 py-4 text-sm text-muted">
          <p>Deepwork measures what you actually finish, not just time spent. It is a personal tool: no accounts, no tracking, no cloud database, and no AI.</p>
          <p>All insights are simple rules calculated on this device.</p>
        </div>
      </Section>
    </>
  )
}

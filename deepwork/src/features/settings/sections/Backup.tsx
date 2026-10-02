import { format } from 'date-fns'
import { Cloud, CloudUpload, Download, RefreshCw, TriangleAlert } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useSettings } from '@/state/settings'
import { useOnline } from '@/hooks/useMediaQuery'
import { DATA_TABLES } from '@/db'
import { DAY_NAMES, relativeDays } from '@/lib/date'
import { isBackupDue, nextBackupDate, runBackup } from '@/lib/backup'
import { countRecords, parseBackupText, restoreBackup, type BackupFile } from '@/lib/data'
import { DriveAuthError, downloadBackup, getAccount, isConfigured, listBackups, requestToken, revokeToken, validToken, type DriveBackup } from '@/lib/drive'
import { Row, Section } from '@/components/ui/row'
import { Switch } from '@/components/ui/switch'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'
import { Select } from '@/components/ui/input'
import { Spinner } from '@/components/ui/empty'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { NumberInput } from '../controls'
import { Deepwork, isNative } from '@/lib/native'

export const TABLE_LABELS: Record<(typeof DATA_TABLES)[number], string> = {
  projects: 'Projects',
  tasks: 'Tasks',
  subtasks: 'Subtasks',
  timeBlocks: 'Time blocks',
  sessions: 'Sessions',
  distractions: 'Distractions',
  distractionReasons: 'Distraction reasons',
  reviews: 'Reviews',
}

export function BackupSection() {
  const { settings, update } = useSettings()
  const online = useOnline()
  const b = settings.backup
  const [busy, setBusy] = useState<null | 'connect' | 'backup'>(null)
  const [restoreOpen, setRestoreOpen] = useState(false)
  const configured = isConfigured()

  const connect = async () => {
    setBusy('connect')
    try {
      const token = await requestToken('consent')
      let account: string | null = null
      try {
        account = await getAccount(token)
      } catch {
        /* account name is cosmetic */
      }
      await update((s) => {
        s.backup.connected = true
        s.backup.account = account
        s.backup.needsReconnect = false
        s.backup.lastError = null
        s.modules.backup = true
      })
      toast('Google Drive connected', { kind: 'success' })
      if (!settings.backup.lastBackupAt) {
        const r = await runBackup({ interactive: true })
        if (r.outcome === 'ok') toast('First backup saved to Drive', { kind: 'success' })
      }
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not connect', { kind: 'error' })
    } finally {
      setBusy(null)
    }
  }

  const reconnect = async () => {
    setBusy('connect')
    try {
      await requestToken('')
      await update((s) => {
        s.backup.needsReconnect = false
        s.backup.lastError = null
      })
      toast('Reconnected', { kind: 'success' })
      if (isBackupDue(settings)) await backupNow()
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not reconnect', { kind: 'error' })
    } finally {
      setBusy(null)
    }
  }

  const backupNow = async () => {
    setBusy('backup')
    const r = await runBackup({ interactive: true })
    setBusy(null)
    if (r.outcome === 'ok') toast('Backed up to Google Drive', { kind: 'success' })
    else if (r.message) toast(r.message, { kind: 'error' })
  }

  const disconnect = async () => {
    if (!(await confirmDialog({ title: 'Disconnect Google Drive?', description: 'Automatic backups stop and the stored sign-in token is removed from this device. Backups already in Drive are kept.', confirmLabel: 'Disconnect', danger: true }))) return
    await revokeToken()
    await update((s) => {
      s.backup.connected = false
      s.backup.account = null
      s.backup.needsReconnect = false
      s.backup.lastError = null
      s.modules.backup = false
    })
    toast('Disconnected from Google Drive')
  }

  if (!configured) {
    return (
      <Section title="Google Drive">
        <div className="space-y-2 py-4 text-sm">
          <p className="font-medium">Add your Google OAuth Client ID to enable backups.</p>
          <p className="text-muted">
            Deepwork backs up to your own Drive using a Client ID you create in Google Cloud Console. Paste it into <code className="rounded bg-card-2 px-1.5 py-0.5 text-[12px]">src/config/google.ts</code> (or set{' '}
            <code className="rounded bg-card-2 px-1.5 py-0.5 text-[12px]">VITE_GOOGLE_CLIENT_ID</code>), rebuild, and reload. The README has step-by-step instructions.
          </p>
          <p className="text-muted">Everything else in the app works without it. You can still export backups manually under Data.</p>
        </div>
      </Section>
    )
  }

  if (!b.connected) {
    return (
      <Section title="Google Drive">
        <div className="flex flex-col items-start gap-3 py-5">
          <div className="flex items-center gap-3">
            <span className="flex size-10 items-center justify-center rounded-xl bg-accent-soft text-accent">
              <Cloud className="size-5" />
            </span>
            <div>
              <p className="font-medium">Weekly backup to your Google Drive</p>
              <p className="text-[13px] text-muted">Saved to a “Deepwork Backups” folder. The app can only access files it creates.</p>
            </div>
          </div>
          <Button variant="primary" disabled={!online || busy === 'connect'} onClick={() => void connect()}>
            {busy === 'connect' ? <RefreshCw className="animate-spin" /> : <Cloud />} Connect Google Drive
          </Button>
          {!online && <p className="text-xs text-muted">You're offline. Connect when you're back online.</p>}
        </div>
        {isNative && <AndroidSetupHelp />}
      </Section>
    )
  }

  const due = isBackupDue(settings)
  const next = nextBackupDate(settings)

  return (
    <>
      {(b.needsReconnect || b.lastError) && (
        <div className="card pad mb-6 flex items-start gap-3 border-warning/40">
          <TriangleAlert className="mt-0.5 size-5 shrink-0 text-warning" />
          <div className="min-w-0 flex-1">
            <p className="font-medium">{b.needsReconnect ? 'Your Google sign-in has expired' : 'The last backup did not complete'}</p>
            <p className="mt-0.5 text-[13px] text-muted">{b.needsReconnect ? 'Reconnect to keep weekly backups running. Nothing else is affected.' : b.lastError}</p>
            <div className="mt-3 flex gap-2">
              {b.needsReconnect ? (
                <Button variant="primary" size="sm" disabled={!online || !!busy} onClick={() => void reconnect()}>
                  Reconnect
                </Button>
              ) : (
                <Button variant="primary" size="sm" disabled={!online || !!busy} onClick={() => void backupNow()}>
                  Retry
                </Button>
              )}
            </div>
          </div>
        </div>
      )}

      <Section title="Status">
        <Row label="Account" description={b.account ?? 'Connected'}>
          <Button variant="ghost" size="sm" onClick={() => void disconnect()}>
            Disconnect
          </Button>
        </Row>
        <Row label="Automatic weekly backup" description="Runs when you open the app (online) once a backup is due.">
          <Switch checked={settings.modules.backup} onCheckedChange={(v) => void update((s) => void (s.modules.backup = v))} aria-label="Automatic backup" />
        </Row>
        <Row label="Last successful backup" description={b.lastBackupAt ? `${format(b.lastBackupAt, 'MMM d, yyyy · h:mm a')} (${relativeDays(b.lastBackupAt)})` : 'Never'} />
        <Row label="Next backup" description={!settings.modules.backup ? 'Paused' : due ? (online ? 'Due now' : 'Due — waiting for a connection') : format(next, 'EEEE, MMM d')} />
        <div className="flex flex-wrap gap-2 py-4">
          <Button variant="primary" disabled={!online || !!busy} onClick={() => void backupNow()}>
            {busy === 'backup' ? <RefreshCw className="animate-spin" /> : <CloudUpload />} Back up now
          </Button>
          <Button variant="secondary" disabled={!online || !!busy} onClick={() => setRestoreOpen(true)}>
            <Download /> Restore from Google Drive
          </Button>
        </div>
        {!online && <p className="pb-3 text-xs text-muted">You're offline. Backup and restore need a connection.</p>}
      </Section>

      <Section title="Schedule">
        <Row label="Backup day">
          <Select value={b.day} onChange={(e) => void update((s) => void (s.backup.day = Number(e.target.value)))} className="w-[150px]">
            {DAY_NAMES.map((d, i) => (
              <option key={d} value={i}>
                {d}
              </option>
            ))}
          </Select>
        </Row>
        <Row label="Keep the last" description="Older backups created by Deepwork are deleted from Drive.">
          <NumberInput value={b.retention} min={1} max={52} suffix="backups" onCommit={(n) => void update((s) => void (s.backup.retention = n))} />
        </Row>
      </Section>

      <RestoreDialog open={restoreOpen} onOpenChange={setRestoreOpen} />
    </>
  )
}

/** The values Google Cloud needs for an Android OAuth client (one-time setup, see README). */
function AndroidSetupHelp() {
  const [info, setInfo] = useState<{ packageName: string; sha1?: string } | null>(null)
  useEffect(() => {
    void Deepwork.getSigningInfo().then(setInfo).catch(() => {})
  }, [])
  const copy = (v: string) => void navigator.clipboard?.writeText(v).then(() => toast('Copied', { kind: 'success', duration: 1500 }))
  return (
    <div className="border-t border-border/70 py-4 text-[13px] text-muted">
      <p className="mb-2 font-medium text-fg">One-time Google Cloud setup</p>
      <p>
        Create an <b>Android</b> OAuth client in Google Cloud Console (project with the Drive API enabled) using these two values. The README has step-by-step instructions.
      </p>
      {info && (
        <div className="mt-3 space-y-2">
          {[
            ['Package name', info.packageName],
            ['SHA-1 certificate fingerprint', info.sha1 || 'Unavailable'],
          ].map(([k, v]) => (
            <button key={k} onClick={() => copy(v)} className="block w-full rounded-[10px] bg-card-2/70 px-3 py-2 text-left" title="Tap to copy">
              <span className="block text-[11px] uppercase tracking-wider">{k}</span>
              <span className="block break-all font-mono text-[12px] text-fg">{v}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

function RestoreDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (o: boolean) => void }) {
  const { update } = useSettings()
  const [files, setFiles] = useState<DriveBackup[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [preview, setPreview] = useState<{ file: DriveBackup; data: BackupFile } | null>(null)

  useEffect(() => {
    if (open) void load()
    else {
      setFiles(null)
      setPreview(null)
      setError(null)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  const withToken = async () => validToken() ?? (await requestToken(''))

  const load = async () => {
    setLoading(true)
    setError(null)
    setPreview(null)
    try {
      const token = await withToken()
      setFiles(await listBackups(token))
    } catch (e) {
      if (e instanceof DriveAuthError) await update((s) => void (s.backup.needsReconnect = true))
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }

  const pick = async (f: DriveBackup) => {
    setLoading(true)
    setError(null)
    try {
      const token = await withToken()
      const text = await downloadBackup(token, f.id)
      setPreview({ file: f, data: parseBackupText(text) })
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }

  const restore = async () => {
    if (!preview) return
    const ok = await confirmDialog({
      title: 'Replace all data on this device?',
      description: 'Your current tasks, sessions, reviews and settings will be replaced by this backup. Your app lock and Drive connection stay as they are.',
      confirmLabel: 'Restore',
      danger: true,
    })
    if (!ok) return
    await restoreBackup(preview.data)
    toast('Backup restored', { kind: 'success' })
    onOpenChange(false)
  }

  return (
    <Dialog
      open={open}
      onOpenChange={onOpenChange}
      title={preview ? 'Restore this backup?' : 'Restore from Google Drive'}
      description={preview ? preview.file.name : 'Choose a backup to preview.'}
      footer={
        preview ? (
          <>
            <Button variant="ghost" onClick={() => setPreview(null)}>
              Back
            </Button>
            <Button variant="danger" onClick={() => void restore()}>
              Restore
            </Button>
          </>
        ) : undefined
      }
    >
      <div className="pb-4">
        {loading && (
          <div className="flex justify-center py-10">
            <Spinner />
          </div>
        )}
        {error && !loading && (
          <div className="space-y-3 py-4">
            <p className="text-sm text-warning">{error}</p>
            <Button variant="secondary" size="sm" onClick={() => void load()}>
              Try again
            </Button>
          </div>
        )}
        {!loading && !error && !preview && files && (
          <ul className="space-y-1">
            {files.map((f) => (
              <li key={f.id}>
                <button onClick={() => void pick(f)} className="flex w-full items-center justify-between rounded-[12px] px-3 py-3 text-left hover:bg-card-2">
                  <span className="text-sm font-medium">{f.name}</span>
                  <span className="text-xs text-muted">{format(new Date(f.modifiedTime), 'MMM d, h:mm a')}</span>
                </button>
              </li>
            ))}
            {files.length === 0 && <p className="py-8 text-center text-sm text-muted">No backups found in Drive yet.</p>}
          </ul>
        )}
        {!loading && preview && <BackupPreview data={preview.data} />}
      </div>
    </Dialog>
  )
}

export function BackupPreview({ data }: { data: BackupFile }) {
  const counts = countRecords(data)
  return (
    <div>
      <p className="mb-3 text-sm text-muted">Created {data.exported_at ? format(new Date(data.exported_at), 'EEEE, MMM d, yyyy · h:mm a') : 'at an unknown date'} · schema v{data.schema_version}</p>
      <div className="grid grid-cols-2 gap-2">
        {DATA_TABLES.map((t) => (
          <div key={t} className="flex items-center justify-between rounded-[10px] bg-card-2/60 px-3 py-2 text-sm">
            <span className="text-muted">{TABLE_LABELS[t]}</span>
            <span className="tabular font-semibold">{counts[t]}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

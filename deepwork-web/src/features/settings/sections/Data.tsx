import { Database, FileJson, FileSpreadsheet, RotateCcw, Sparkles, Trash2, Upload } from 'lucide-react'
import { useRef, useState } from 'react'
import { format } from 'date-fns'
import { useSettings } from '@/state/settings'
import { DEFAULT_SETTINGS, mergeSettings } from '@/lib/settings'
import { backupFilename, buildBackup, buildCsvs, deleteAllData, parseBackupText, restoreBackup, type BackupFile } from '@/lib/data'
import { clearDemoData, loadDemoData } from '@/lib/demo'
import { downloadFile } from '@/lib/utils'
import { Row, Section } from '@/components/ui/row'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'
import { BackupPreview } from './Backup'

export function DataSection() {
  const { settings, update } = useSettings()
  const fileRef = useRef<HTMLInputElement>(null)
  const [importing, setImporting] = useState<BackupFile | null>(null)
  const [busy, setBusy] = useState<string | null>(null)

  const exportJson = async () => {
    const file = await buildBackup()
    downloadFile(backupFilename(), JSON.stringify(file, null, 2))
    toast('Backup exported', { kind: 'success' })
  }

  const exportCsv = async () => {
    const { sessionsCsv, tasksCsv, distractionsCsv } = await buildCsvs()
    const d = format(new Date(), 'yyyy-MM-dd')
    downloadFile(`deepwork-sessions-${d}.csv`, sessionsCsv, 'text/csv')
    setTimeout(() => downloadFile(`deepwork-tasks-${d}.csv`, tasksCsv, 'text/csv'), 300)
    setTimeout(() => downloadFile(`deepwork-distractions-${d}.csv`, distractionsCsv, 'text/csv'), 600)
    toast('Exported 3 CSV files', { kind: 'success' })
  }

  const onFile = async (f: File | undefined) => {
    if (!f) return
    try {
      setImporting(parseBackupText(await f.text()))
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Could not read that file', { kind: 'error' })
    } finally {
      if (fileRef.current) fileRef.current.value = ''
    }
  }

  return (
    <>
      <Section title="Export">
        <Row label="Full backup (JSON)" description="Everything, including settings. Can be imported later.">
          <Button variant="secondary" size="sm" onClick={() => void exportJson()}>
            <FileJson /> Export
          </Button>
        </Row>
        <Row label="Spreadsheets (CSV)" description="Sessions, tasks and distractions as three files.">
          <Button variant="secondary" size="sm" onClick={() => void exportCsv()}>
            <FileSpreadsheet /> Export
          </Button>
        </Row>
      </Section>

      <Section title="Import">
        <Row label="Import from a JSON backup" description="You'll see a preview before anything changes.">
          <Button variant="secondary" size="sm" onClick={() => fileRef.current?.click()}>
            <Upload /> Choose file
          </Button>
          <input ref={fileRef} type="file" accept="application/json,.json" className="hidden" onChange={(e) => void onFile(e.target.files?.[0])} />
        </Row>
      </Section>

      <Section title="Demo data">
        <Row label="Load demo data" description="About 60 days of sample sessions, tasks and reviews to preview Insights. Kept separate from your own data.">
          <Button
            variant="secondary"
            size="sm"
            disabled={!!busy}
            onClick={async () => {
              setBusy('demo')
              const r = await loadDemoData()
              setBusy(null)
              toast(`Loaded ${r.sessions} demo sessions`, { kind: 'success' })
            }}
          >
            <Sparkles /> {settings.demoLoaded ? 'Reload' : 'Load'}
          </Button>
        </Row>
        <Row label="Clear demo data" description="Removes only demo records.">
          <Button
            variant="secondary"
            size="sm"
            disabled={!!busy || !settings.demoLoaded}
            onClick={async () => {
              setBusy('clear')
              await clearDemoData()
              setBusy(null)
              toast('Demo data cleared', { kind: 'success' })
            }}
          >
            Clear
          </Button>
        </Row>
      </Section>

      <Section title="Reset & delete">
        <Row label="Reset all settings" description="Restores default settings. Your tasks, sessions and reviews are kept; app lock and Drive connection are kept.">
          <Button
            variant="secondary"
            size="sm"
            onClick={async () => {
              if (!(await confirmDialog({ title: 'Reset all settings to defaults?', confirmLabel: 'Reset', danger: true }))) return
              await update((s) => {
                const keep = { lock: s.lock, backup: s.backup, demoLoaded: s.demoLoaded, backupOn: s.modules.backup }
                Object.assign(s, mergeSettings(structuredClone(DEFAULT_SETTINGS)))
                s.lock = keep.lock
                s.backup = keep.backup
                s.demoLoaded = keep.demoLoaded
                s.modules.backup = keep.backupOn
              })
              toast('Settings reset', { kind: 'success' })
            }}
          >
            <RotateCcw /> Reset
          </Button>
        </Row>
        <Row label="Delete all data" description="Permanently erases everything on this device. Backups in Google Drive are not touched.">
          <Button
            variant="danger"
            size="sm"
            onClick={async () => {
              const first = await confirmDialog({
                title: 'Delete all data?',
                description: 'All tasks, sessions, distractions, reviews and settings on this device will be erased. This cannot be undone. Consider exporting a backup first.',
                confirmLabel: 'Continue',
                danger: true,
              })
              if (!first) return
              const second = await confirmDialog({ title: 'Are you absolutely sure?', confirmLabel: 'Delete everything', danger: true, typeToConfirm: 'DELETE' })
              if (!second) return
              await deleteAllData()
              toast('All data deleted')
            }}
          >
            <Trash2 /> Delete
          </Button>
        </Row>
      </Section>

      <Dialog
        open={!!importing}
        onOpenChange={(o) => !o && setImporting(null)}
        title="Import this backup?"
        description="All current data on this device will be replaced."
        footer={
          <>
            <Button variant="ghost" onClick={() => setImporting(null)}>
              Cancel
            </Button>
            <Button
              variant="danger"
              onClick={async () => {
                if (!importing) return
                if (!(await confirmDialog({ title: 'Replace all data?', description: 'This cannot be undone.', confirmLabel: 'Import', danger: true }))) return
                await restoreBackup(importing)
                setImporting(null)
                toast('Backup imported', { kind: 'success' })
              }}
            >
              <Database /> Import
            </Button>
          </>
        }
      >
        <div className="pb-4">{importing && <BackupPreview data={importing} />}</div>
      </Dialog>
    </>
  )
}

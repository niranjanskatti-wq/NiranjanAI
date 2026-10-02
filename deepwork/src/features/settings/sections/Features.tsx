import { RotateCcw } from 'lucide-react'
import { useNavigate } from 'react-router'
import { useSettings } from '@/state/settings'
import { MODULES, resetSection } from '@/lib/settings'
import { isAndroid } from '@/lib/native'
import { Row, Section } from '@/components/ui/row'
import { Switch } from '@/components/ui/switch'
import { Button } from '@/components/ui/button'
import { confirmDialog } from '@/components/ui/confirm'
import { toast } from '@/components/ui/toast'

export function FeaturesSection() {
  const { settings, update } = useSettings()
  const navigate = useNavigate()
  return (
    <>
      <p className="mb-4 text-sm text-muted">Every module is optional. Turned-off modules disappear from navigation, Today, notifications and insights.</p>
      <Section
        title="Modules"
        action={
          <Button
            variant="ghost"
            size="sm"
            onClick={async () => {
              if (await confirmDialog({ title: 'Reset modules to defaults?', description: 'All modules except Google Drive backup will be turned on.', confirmLabel: 'Reset' })) {
                await update((s) => resetSection(s, 'modules'))
                toast('Modules reset', { kind: 'success' })
              }
            }}
          >
            <RotateCcw /> Reset
          </Button>
        }
      >
        {MODULES.filter((m) => !m.androidOnly || isAndroid).map((m) => {
          const on = settings.modules[m.key]
          const needsConnect = m.key === 'backup' && !settings.backup.connected
          return (
            <Row
              key={m.key}
              label={m.label}
              description={needsConnect ? 'Connect Google Drive to turn this on.' : m.locked ? 'Always on.' : m.description}
            >
              <Switch
                checked={on}
                disabled={m.locked}
                aria-label={m.label}
                onCheckedChange={(v) => {
                  if (needsConnect && v) {
                    navigate('/settings/backup')
                    return
                  }
                  void update((s) => {
                    s.modules[m.key] = v
                  })
                }}
              />
            </Row>
          )
        })}
      </Section>
    </>
  )
}

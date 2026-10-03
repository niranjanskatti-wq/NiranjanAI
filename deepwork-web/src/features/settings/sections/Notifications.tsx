import { useEffect, useState } from 'react'
import { useSettings } from '@/state/settings'
import { notify, permission, requestPermission } from '@/lib/notify'
import { resetSection } from '@/lib/settings'
import { DAY_NAMES } from '@/lib/date'
import { Row, Section } from '@/components/ui/row'
import { Switch } from '@/components/ui/switch'
import { Button } from '@/components/ui/button'
import { toast } from '@/components/ui/toast'
import { ResetButton, TimeInput } from '../controls'

export function NotificationsSection() {
  const { settings, update } = useSettings()
  const [perm, setPerm] = useState(permission())
  useEffect(() => {
    const iv = setInterval(() => setPerm(permission()), 2000)
    return () => clearInterval(iv)
  }, [])
  const n = settings.notifications
  const master = settings.modules.notifications
  const m = settings.modules

  return (
    <>
      <Section title="Permission">
        <Row
          label={perm === 'granted' ? 'Notifications allowed' : perm === 'denied' ? 'Notifications blocked' : perm === 'unsupported' ? 'Not supported' : 'Not yet allowed'}
          description={
            perm === 'denied'
              ? 'Allow notifications for this site in your browser or system settings.'
              : perm === 'unsupported'
                ? 'This browser does not support notifications. On iPhone, install Deepwork to your Home Screen first.'
                : 'Reminders fire while Deepwork is open or running in the background.'
          }
        >
          {perm === 'default' && (
            <Button variant="primary" size="sm" onClick={async () => setPerm(await requestPermission())}>
              Allow
            </Button>
          )}
          {perm === 'granted' && (
            <Button
              variant="secondary"
              size="sm"
              onClick={async () => {
                const ok = await notify(settings, 'sessionComplete', 'Deepwork', 'Notifications are working.', { force: true })
                if (!ok) toast('Could not show a notification.', { kind: 'error' })
              }}
            >
              Test
            </Button>
          )}
        </Row>
      </Section>

      <Section title="Reminders" action={<ResetButton label="Notifications" onReset={() => update((s) => resetSection(s, 'notifications'))} />}>
        <Row label="All notifications" description="Master switch.">
          <Switch checked={master} onCheckedChange={(v) => void update((s) => void (s.modules.notifications = v))} aria-label="All notifications" />
        </Row>
        <div className={master ? '' : 'pointer-events-none opacity-45'}>
          <Row label="Morning planning" description={!m.priorities ? 'Requires Top priorities.' : 'A nudge to pick today’s priorities.'}>
            <div className="flex items-center gap-2">
              <TimeInput value={n.morning.time} onCommit={(v) => void update((s) => void (s.notifications.morning.time = v))} />
              <Switch checked={n.morning.enabled} onCheckedChange={(v) => void update((s) => void (s.notifications.morning.enabled = v))} aria-label="Morning planning" />
            </div>
          </Row>
          <Row label="Evening review" description={!m.eveningReview ? 'Requires Evening review.' : 'Uses the evening review time.'}>
            <div className="flex items-center gap-2">
              <TimeInput value={settings.eveningReview.time} onCommit={(v) => void update((s) => void (s.eveningReview.time = v))} />
              <Switch checked={n.evening.enabled} onCheckedChange={(v) => void update((s) => void (s.notifications.evening.enabled = v))} aria-label="Evening review reminder" />
            </div>
          </Row>
          <Row label="Weekly review" description={!m.weeklyReview ? 'Requires Weekly review.' : `${DAY_NAMES[settings.weeklyReview.day]}s`}>
            <div className="flex items-center gap-2">
              <TimeInput value={settings.weeklyReview.time} onCommit={(v) => void update((s) => void (s.weeklyReview.time = v))} />
              <Switch checked={n.weekly.enabled} onCheckedChange={(v) => void update((s) => void (s.notifications.weekly.enabled = v))} aria-label="Weekly review reminder" />
            </div>
          </Row>
          <Row label="Break over" description={!m.breaks ? 'Requires Break reminders.' : undefined}>
            <Switch checked={n.breakOver} onCheckedChange={(v) => void update((s) => void (s.notifications.breakOver = v))} aria-label="Break over" />
          </Row>
          <Row label="Session complete">
            <Switch checked={n.sessionComplete} onCheckedChange={(v) => void update((s) => void (s.notifications.sessionComplete = v))} aria-label="Session complete" />
          </Row>
        </div>
      </Section>

      <Section title="Quiet hours">
        <Row label="Quiet hours" description="No notifications during this window.">
          <Switch checked={n.quietHours.enabled} onCheckedChange={(v) => void update((s) => void (s.notifications.quietHours.enabled = v))} aria-label="Quiet hours" />
        </Row>
        {n.quietHours.enabled && (
          <>
            <Row label="From">
              <TimeInput value={n.quietHours.start} onCommit={(v) => void update((s) => void (s.notifications.quietHours.start = v))} />
            </Row>
            <Row label="Until">
              <TimeInput value={n.quietHours.end} onCommit={(v) => void update((s) => void (s.notifications.quietHours.end = v))} />
            </Row>
          </>
        )}
      </Section>
    </>
  )
}

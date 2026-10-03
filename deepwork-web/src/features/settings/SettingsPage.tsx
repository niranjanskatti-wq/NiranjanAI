import { motion } from 'framer-motion'
import { Bell, ChevronLeft, ChevronRight, Cloud, Database, Info, Palette, Shield, SlidersHorizontal, ToggleRight, type LucideIcon } from 'lucide-react'
import { NavLink, useNavigate, useParams } from 'react-router'
import { Page } from '@/components/shared/Page'
import { PageHeader } from '@/components/ui/empty'
import { useMediaQuery } from '@/hooks/useMediaQuery'
import { cn } from '@/lib/utils'
import { FeaturesSection } from './sections/Features'
import { CustomizeSection } from './sections/Customize'
import { AppearanceSection } from './sections/Appearance'
import { NotificationsSection } from './sections/Notifications'
import { PrivacySection } from './sections/Privacy'
import { BackupSection } from './sections/Backup'
import { DataSection } from './sections/Data'
import { AboutSection } from './sections/About'

const SECTIONS: { id: string; label: string; description: string; icon: LucideIcon; Component: () => React.ReactNode }[] = [
  { id: 'features', label: 'Features', description: 'Turn modules on or off', icon: ToggleRight, Component: FeaturesSection },
  { id: 'customize', label: 'Customization', description: 'Fine-tune each module', icon: SlidersHorizontal, Component: CustomizeSection },
  { id: 'appearance', label: 'Appearance', description: 'Theme, accent, font, layout', icon: Palette, Component: AppearanceSection },
  { id: 'notifications', label: 'Notifications', description: 'Reminders and quiet hours', icon: Bell, Component: NotificationsSection },
  { id: 'privacy', label: 'Privacy & Lock', description: 'PIN, biometrics, auto-lock', icon: Shield, Component: PrivacySection },
  { id: 'backup', label: 'Backup', description: 'Weekly Google Drive backup', icon: Cloud, Component: BackupSection },
  { id: 'data', label: 'Data', description: 'Export, import, demo, delete', icon: Database, Component: DataSection },
  { id: 'about', label: 'About', description: 'Version and storage', icon: Info, Component: AboutSection },
]

export default function SettingsPage() {
  const { section } = useParams()
  const navigate = useNavigate()
  const desktop = useMediaQuery('(min-width: 900px)')
  const current = SECTIONS.find((s) => s.id === section)

  if (!desktop) {
    if (!current) {
      return (
        <Page>
          <PageHeader title="Settings" />
          <ul className="card divide-y divide-border/70 overflow-hidden">
            {SECTIONS.map((s) => (
              <li key={s.id}>
                <button onClick={() => navigate(`/settings/${s.id}`)} className="flex w-full items-center gap-3.5 px-4 py-3.5 text-left transition-colors active:bg-card-2">
                  <span className="flex size-9 items-center justify-center rounded-xl bg-card-2 text-muted">
                    <s.icon className="size-[18px]" />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[15px] font-medium">{s.label}</span>
                    <span className="block text-[13px] text-muted">{s.description}</span>
                  </span>
                  <ChevronRight className="size-4 text-muted" />
                </button>
              </li>
            ))}
          </ul>
        </Page>
      )
    }
    return (
      <Page>
        <button onClick={() => navigate('/settings')} className="-ml-1 mb-3 flex items-center gap-1 text-sm font-medium text-muted hover:text-fg">
          <ChevronLeft className="size-4" /> Settings
        </button>
        <PageHeader title={current.label} />
        <current.Component />
      </Page>
    )
  }

  const active = current ?? SECTIONS[0]
  return (
    <Page wide>
      <PageHeader title="Settings" />
      <div className="grid grid-cols-[220px_1fr] gap-8">
        <nav className="sticky top-8 self-start">
          <ul className="space-y-0.5">
            {SECTIONS.map((s) => (
              <li key={s.id}>
                <NavLink
                  to={`/settings/${s.id}`}
                  className={() =>
                    cn(
                      'flex h-10 items-center gap-3 rounded-[12px] px-3 text-sm font-medium transition-colors',
                      active.id === s.id ? 'bg-card text-fg ring-1 ring-border' : 'text-muted hover:bg-card-2/70 hover:text-fg',
                    )
                  }
                >
                  <s.icon className={cn('size-4', active.id === s.id && 'text-accent')} />
                  {s.label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
        <motion.div key={active.id} initial={{ opacity: 0, x: 8 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.22 }} className="min-w-0 max-w-2xl">
          <h2 className="mb-5 text-xl font-semibold tracking-tight">{active.label}</h2>
          <active.Component />
        </motion.div>
      </div>
    </Page>
  )
}

import { AnimatePresence, motion } from 'framer-motion'
import { PanelLeftClose, PanelLeftOpen, Timer } from 'lucide-react'
import type { ReactNode } from 'react'
import { NavLink, useLocation, useNavigate } from 'react-router'
import { useSettings } from '@/state/settings'
import { elapsedSec, useFocus, useNow } from '@/state/focus'
import { formatTimer } from '@/lib/date'
import { cn } from '@/lib/utils'
import { navItems } from './nav'
import { Logo } from './Logo'

export function AppShell({ children }: { children: ReactNode }) {
  const { settings, update } = useSettings()
  const location = useLocation()
  const items = navItems(settings)
  const collapsed = settings.sidebarCollapsed
  const inFocus = location.pathname.startsWith('/focus')
  const { state } = useFocus()
  const focusActive = state.phase !== 'idle' && !inFocus

  return (
    <div className="min-h-dvh">
      {/* Desktop sidebar */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-40 hidden flex-col border-r border-border bg-bg/80 backdrop-blur-xl transition-[width] duration-300 md:flex',
          collapsed ? 'w-[68px]' : 'w-[232px]',
        )}
      >
        <div className={cn('flex h-16 items-center gap-2.5 px-4', collapsed && 'justify-center px-0')}>
          <Logo className="size-7 shrink-0" />
          {!collapsed && <span className="text-[15px] font-semibold tracking-tight">Deepwork</span>}
        </div>
        <nav className="flex flex-1 flex-col gap-0.5 px-2.5 py-2">
          {items.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              title={collapsed ? item.label : undefined}
              className={({ isActive }) =>
                cn(
                  'group relative flex h-10 items-center gap-3 rounded-[12px] px-3 text-[14px] font-medium transition-colors',
                  isActive ? 'text-fg' : 'text-muted hover:bg-card-2/70 hover:text-fg',
                  collapsed && 'justify-center px-0',
                )
              }
            >
              {({ isActive }) => (
                <>
                  {isActive && (
                    <motion.span
                      layoutId="sidebar-active"
                      className="absolute inset-0 rounded-[12px] bg-card ring-1 ring-border"
                      transition={{ type: 'spring', stiffness: 500, damping: 40 }}
                    />
                  )}
                  <item.icon className={cn('relative z-10 size-[18px] shrink-0', isActive && 'text-accent')} />
                  {!collapsed && <span className="relative z-10">{item.label}</span>}
                </>
              )}
            </NavLink>
          ))}
        </nav>
        <button
          onClick={() => update((s) => void (s.sidebarCollapsed = !s.sidebarCollapsed))}
          className={cn('m-2.5 flex h-10 items-center gap-3 rounded-[12px] px-3 text-[13px] text-muted transition-colors hover:bg-card-2 hover:text-fg', collapsed && 'justify-center px-0')}
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {collapsed ? <PanelLeftOpen className="size-[18px]" /> : <PanelLeftClose className="size-[18px]" />}
          {!collapsed && 'Collapse'}
        </button>
      </aside>

      <main
        className={cn(
          'transition-[padding] duration-300',
          collapsed ? 'md:pl-[68px]' : 'md:pl-[232px]',
          !inFocus && 'pb-[calc(84px+env(safe-area-inset-bottom))] md:pb-0',
        )}
      >
        {children}
      </main>

      <AnimatePresence>{focusActive && <FocusPill />}</AnimatePresence>

      {/* Mobile bottom tabs */}
      {!inFocus && (
        <nav className="glass fixed inset-x-0 bottom-0 z-40 border-t border-border safe-bottom md:hidden">
          <div className="mx-auto flex h-[64px] max-w-lg items-stretch justify-around px-2">
            {items
              .filter((i) => i.mobile)
              .map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/'}
                  className={({ isActive }) =>
                    cn('flex flex-1 flex-col items-center justify-center gap-1 text-[11px] font-medium transition-colors active:scale-95', isActive ? 'text-accent' : 'text-muted')
                  }
                >
                  <item.icon className="size-[22px]" strokeWidth={1.8} />
                  {item.label}
                </NavLink>
              ))}
          </div>
        </nav>
      )}
    </div>
  )
}

function FocusPill() {
  const { state } = useFocus()
  const { settings } = useSettings()
  const navigate = useNavigate()
  const running = state.phase === 'running'
  const now = useNow(running || state.phase === 'break', 2)
  let label = 'Session'
  let time = ''
  if (state.phase === 'running' || state.phase === 'paused') {
    const el = elapsedSec(state, now)
    time = formatTimer(state.mode === 'countdown' ? state.plannedSec - el : el, settings.focus.hideSeconds)
    label = state.phase === 'paused' ? 'Paused' : 'Focusing'
  } else if (state.phase === 'break') {
    time = formatTimer(state.breakSec - (now - (state.breakStartedAt ?? now)) / 1000, settings.focus.hideSeconds)
    label = 'Break'
  } else if (state.phase === 'finished') label = 'Session complete — close it out'
  else if (state.phase === 'breakOver') label = 'Break over'
  else if (state.phase === 'closed' || state.phase === 'ended') label = 'Session ended'
  return (
    <motion.button
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 20 }}
      onClick={() => navigate('/focus')}
      className="glass fixed bottom-[calc(76px+env(safe-area-inset-bottom))] left-1/2 z-50 flex -translate-x-1/2 items-center gap-2.5 rounded-full border border-border py-2 pl-3 pr-4 text-sm font-medium shadow-xl active:scale-95 md:bottom-6"
    >
      <span className="relative flex size-6 items-center justify-center rounded-full bg-accent-soft text-accent">
        <Timer className="size-3.5" />
        {running && <span className="absolute inset-0 animate-ping rounded-full bg-accent/30" />}
      </span>
      <span>{label}</span>
      {time && <span className="tabular text-muted">{time}</span>}
    </motion.button>
  )
}

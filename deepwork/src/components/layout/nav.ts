import { ChartColumn, ListChecks, NotebookPen, Settings2, Sun, Timer, type LucideIcon } from 'lucide-react'
import type { Settings } from '@/lib/settings'

export interface NavItem {
  to: string
  label: string
  icon: LucideIcon
  mobile: boolean
}

export function navItems(s: Settings): NavItem[] {
  const items: NavItem[] = [
    { to: '/', label: 'Today', icon: Sun, mobile: true },
    { to: '/focus', label: 'Focus', icon: Timer, mobile: true },
  ]
  if (s.modules.tasks) items.push({ to: '/tasks', label: 'Tasks', icon: ListChecks, mobile: true })
  if (s.modules.insights) items.push({ to: '/insights', label: 'Insights', icon: ChartColumn, mobile: true })
  if (s.modules.eveningReview || s.modules.weeklyReview) items.push({ to: '/reviews', label: 'Reviews', icon: NotebookPen, mobile: false })
  items.push({ to: '/settings', label: 'Settings', icon: Settings2, mobile: true })
  return items
}

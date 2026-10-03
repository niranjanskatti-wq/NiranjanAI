import { useEffect, useState } from 'react'
import type { Settings } from '@/lib/settings'
import { contrastText } from '@/lib/utils'

function systemDark() {
  return typeof window !== 'undefined' && window.matchMedia?.('(prefers-color-scheme: dark)').matches
}

export function useResolvedTheme(theme: Settings['appearance']['theme']): 'dark' | 'light' {
  const [sys, setSys] = useState(systemDark())
  useEffect(() => {
    const mq = window.matchMedia('(prefers-color-scheme: dark)')
    const on = () => setSys(mq.matches)
    mq.addEventListener('change', on)
    return () => mq.removeEventListener('change', on)
  }, [])
  return theme === 'system' ? (sys ? 'dark' : 'light') : theme
}

export function useApplyAppearance(settings: Settings) {
  const a = settings.appearance
  const resolved = useResolvedTheme(a.theme)
  useEffect(() => {
    const root = document.documentElement
    root.classList.toggle('dark', resolved === 'dark')
    root.dataset.font = a.font
    root.dataset.size = a.textSize
    root.dataset.density = a.density
    root.dataset.motion = a.animations
    root.style.setProperty('--accent', a.accent)
    root.style.setProperty('--accent-fg', contrastText(a.accent))
    const meta = document.querySelector('meta[name="theme-color"]')
    meta?.setAttribute('content', resolved === 'dark' ? '#0B0B0F' : '#FAFAFB')
    try {
      localStorage.setItem('deepwork.themeHint', resolved)
    } catch {
      /* ignore */
    }
  }, [resolved, a.font, a.textSize, a.density, a.animations, a.accent])
  return resolved
}

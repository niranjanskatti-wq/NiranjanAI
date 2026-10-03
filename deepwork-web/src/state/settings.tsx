import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, uid } from '@/db'
import { DEFAULT_SETTINGS, mergeSettings, type ModuleKey, type Settings } from '@/lib/settings'

export const DEFAULT_REASONS = ['Phone', 'Person', 'Noise', 'Boredom', 'Unclear task', 'Other']
export const DEFAULT_PROJECTS = [
  { name: 'Work', color: '#7C7CFF' },
  { name: 'Personal', color: '#4ADE80' },
]

export async function seedDefaults() {
  await db.transaction('rw', db.settings, db.distractionReasons, db.projects, async () => {
    const existing = await db.settings.get('app')
    if (existing) return
    await db.settings.put({ key: 'app', value: structuredClone(DEFAULT_SETTINGS) })
    if ((await db.distractionReasons.count()) === 0) {
      await db.distractionReasons.bulkPut(DEFAULT_REASONS.map((label, order) => ({ id: uid(), label, order })))
    }
    if ((await db.projects.count()) === 0) {
      await db.projects.bulkPut(DEFAULT_PROJECTS.map((p, order) => ({ id: uid(), ...p, order })))
    }
  })
}

export async function readSettings(): Promise<Settings> {
  const row = await db.settings.get('app')
  return mergeSettings(row?.value)
}

/** Mutate settings with a draft function and persist atomically. */
export async function updateSettings(fn: (draft: Settings) => void) {
  await db.transaction('rw', db.settings, async () => {
    const row = await db.settings.get('app')
    const draft = mergeSettings(row?.value)
    fn(draft)
    await db.settings.put({ key: 'app', value: draft })
  })
}

interface SettingsCtx {
  settings: Settings
  update: (fn: (draft: Settings) => void) => Promise<void>
  isOn: (m: ModuleKey) => boolean
}

const Ctx = createContext<SettingsCtx | null>(null)

export function SettingsProvider({ children, fallback }: { children: ReactNode; fallback: ReactNode }) {
  const [ready, setReady] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    seedDefaults()
      .then(() => setReady(true))
      .catch((e) => setError(String(e?.message ?? e)))
  }, [])

  const row = useLiveQuery(() => (ready ? db.settings.get('app') : undefined), [ready])
  const settings = useMemo(() => (row ? mergeSettings(row.value) : null), [row])
  const update = useCallback((fn: (draft: Settings) => void) => updateSettings(fn), [])
  const isOn = useCallback((m: ModuleKey) => !!settings?.modules[m], [settings])

  if (error) {
    return (
      <div className="flex min-h-dvh items-center justify-center p-8 text-center">
        <div className="max-w-sm">
          <h1 className="text-xl font-semibold">Storage unavailable</h1>
          <p className="mt-2 text-sm text-muted">
            Deepwork could not open its on-device database. Private browsing modes sometimes block IndexedDB.
          </p>
          <p className="mt-3 font-mono text-xs text-muted">{error}</p>
          <button className="mt-6 rounded-xl bg-accent px-4 py-2 text-sm font-medium text-accent-fg" onClick={() => location.reload()}>
            Reload
          </button>
        </div>
      </div>
    )
  }
  if (!settings) return <>{fallback}</>
  return <Ctx.Provider value={{ settings, update, isOn }}>{children}</Ctx.Provider>
}

export function useSettings() {
  const ctx = useContext(Ctx)
  if (!ctx) throw new Error('useSettings must be used inside SettingsProvider')
  return ctx
}

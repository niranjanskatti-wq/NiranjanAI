import { MotionConfig } from 'framer-motion'
import { lazy, Suspense, useEffect, type ReactNode } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router'
import { isNative } from '@/lib/native'
import { SettingsProvider, useSettings } from '@/state/settings'
import { FocusProvider } from '@/state/focus'
import { useApplyAppearance } from '@/hooks/appearance'
import { useAutoBackup, useReminders } from '@/hooks/background'
import { AppShell } from '@/components/layout/AppShell'
import { LockGate } from '@/features/lock/LockGate'
import { Toaster } from '@/components/ui/toast'
import { ConfirmHost } from '@/components/ui/confirm'
import { Logo } from '@/components/layout/Logo'
import { TodayPage } from '@/features/today/TodayPage'
import { FocusPage } from '@/features/focus/FocusPage'
import type { ModuleKey } from '@/lib/settings'
import { Spinner } from '@/components/ui/empty'

const TasksPage = lazy(() => import('@/features/tasks/TasksPage'))
const InsightsPage = lazy(() => import('@/features/insights/InsightsPage'))
const EveningReviewPage = lazy(() => import('@/features/review/EveningReviewPage'))
const WeeklyReviewPage = lazy(() => import('@/features/review/WeeklyReviewPage'))
const ReviewsPage = lazy(() => import('@/features/review/ReviewsPage'))
const SettingsPage = lazy(() => import('@/features/settings/SettingsPage'))

function Splash() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-4">
      <Logo className="size-11 animate-pulse" />
    </div>
  )
}

function PageFallback() {
  return (
    <div className="flex min-h-[60dvh] items-center justify-center">
      <Spinner />
    </div>
  )
}

function Guard({ module, anyOf, children }: { module?: ModuleKey; anyOf?: ModuleKey[]; children: ReactNode }) {
  const { isOn } = useSettings()
  if (module && !isOn(module)) return <Navigate to="/" replace />
  if (anyOf && !anyOf.some(isOn)) return <Navigate to="/" replace />
  return <>{children}</>
}

/** Android hardware back button: go back within the app, or send the app to the background. */
function NativeBackButton() {
  useEffect(() => {
    if (!isNative) return
    let remove: (() => void) | undefined
    void import('@capacitor/app').then(({ App: CapApp }) =>
      CapApp.addListener('backButton', ({ canGoBack }) => {
        // Close an open dialog first.
        const dialog = document.querySelector('[role="dialog"][data-state="open"]')
        if (dialog) {
          document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))
          return
        }
        if (canGoBack && window.location.pathname !== '/') window.history.back()
        else void CapApp.minimizeApp()
      }).then((h) => (remove = () => void h.remove())),
    )
    return () => remove?.()
  }, [])
  return null
}

function Root() {
  const { settings } = useSettings()
  useApplyAppearance(settings)
  useReminders(settings)
  useAutoBackup(settings)
  const motion = settings.appearance.animations
  return (
    <MotionConfig reducedMotion={motion === 'full' ? 'user' : 'always'} transition={motion === 'off' ? { duration: 0 } : undefined}>
      <FocusProvider>
        <LockGate>
          <BrowserRouter>
            <NativeBackButton />
            <AppShell>
              <Suspense fallback={<PageFallback />}>
                <Routes>
                  <Route path="/" element={<TodayPage />} />
                  <Route path="/focus" element={<FocusPage />} />
                  <Route
                    path="/tasks"
                    element={
                      <Guard module="tasks">
                        <TasksPage />
                      </Guard>
                    }
                  />
                  <Route
                    path="/insights"
                    element={
                      <Guard module="insights">
                        <InsightsPage />
                      </Guard>
                    }
                  />
                  <Route
                    path="/review/evening"
                    element={
                      <Guard module="eveningReview">
                        <EveningReviewPage />
                      </Guard>
                    }
                  />
                  <Route
                    path="/review/weekly"
                    element={
                      <Guard module="weeklyReview">
                        <WeeklyReviewPage />
                      </Guard>
                    }
                  />
                  <Route
                    path="/reviews"
                    element={
                      <Guard anyOf={['eveningReview', 'weeklyReview']}>
                        <ReviewsPage />
                      </Guard>
                    }
                  />
                  <Route path="/settings" element={<SettingsPage />} />
                  <Route path="/settings/:section" element={<SettingsPage />} />
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </Suspense>
            </AppShell>
          </BrowserRouter>
        </LockGate>
        <Toaster />
        <ConfirmHost />
      </FocusProvider>
    </MotionConfig>
  )
}

export default function App() {
  return (
    <SettingsProvider fallback={<Splash />}>
      <Root />
    </SettingsProvider>
  )
}

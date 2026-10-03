import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@fontsource-variable/inter'
import '@fontsource-variable/geist'
import '@fontsource-variable/source-serif-4'
import './index.css'
import App from './App'
import { registerSW } from 'virtual:pwa-register'

// Apply the last-known theme before first paint to avoid a flash.
try {
  const t = localStorage.getItem('deepwork.themeHint')
  if (t === 'light') document.documentElement.classList.remove('dark')
} catch {
  /* ignore */
}

if ('serviceWorker' in navigator) {
  registerSW({ immediate: true })
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)

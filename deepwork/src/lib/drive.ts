// Google Drive backup — the only feature that touches the network.
// Google Identity Services issues a short-lived access token in the browser; all Drive calls go
// directly from this device to Google's REST API using the narrow drive.file scope.
import { DRIVE_FOLDER_NAME, GOOGLE_DRIVE_SCOPE, getClientId } from '@/config/google'
import { Deepwork, isNative } from './native'

const TOKEN_KEY = 'deepwork.driveToken'
const FOLDER_KEY = 'deepwork.driveFolderId'
const GIS_SRC = 'https://accounts.google.com/gsi/client'
const API = 'https://www.googleapis.com/drive/v3'
const UPLOAD = 'https://www.googleapis.com/upload/drive/v3'

export class DriveAuthError extends Error {
  constructor(message = 'Google sign-in expired. Reconnect to continue backing up.') {
    super(message)
    this.name = 'DriveAuthError'
  }
}

export class DriveConfigError extends Error {}

interface TokenResponse {
  access_token?: string
  expires_in?: number
  error?: string
  error_description?: string
}

interface GoogleOAuth2 {
  initTokenClient(cfg: {
    client_id: string
    scope: string
    callback: (r: TokenResponse) => void
    error_callback?: (e: { type: string; message?: string }) => void
  }): { requestAccessToken(o?: { prompt?: string }): void }
  revoke(token: string, done?: () => void): void
}

declare global {
  interface Window {
    google?: { accounts: { oauth2: GoogleOAuth2 } }
  }
}

let gisPromise: Promise<GoogleOAuth2> | null = null

function loadGis(): Promise<GoogleOAuth2> {
  if (window.google?.accounts?.oauth2) return Promise.resolve(window.google.accounts.oauth2)
  if (gisPromise) return gisPromise
  gisPromise = new Promise((resolve, reject) => {
    const s = document.createElement('script')
    s.src = GIS_SRC
    s.async = true
    s.onload = () => (window.google?.accounts?.oauth2 ? resolve(window.google.accounts.oauth2) : reject(new Error('Google sign-in failed to load.')))
    s.onerror = () => {
      gisPromise = null
      reject(new Error('Could not reach Google. Check your internet connection.'))
    }
    document.head.appendChild(s)
  })
  return gisPromise
}

export function isConfigured() {
  // On Android, Google identifies the app by its package name and signing key instead.
  return isNative || getClientId().length > 0
}

export function storedToken(): { token: string; expiresAt: number } | null {
  try {
    const raw = localStorage.getItem(TOKEN_KEY)
    if (!raw) return null
    return JSON.parse(raw)
  } catch {
    return null
  }
}

export function validToken(): string | null {
  const t = storedToken()
  if (!t || Date.now() > t.expiresAt - 60_000) return null
  return t.token
}

function saveToken(token: string, expiresIn: number) {
  try {
    localStorage.setItem(TOKEN_KEY, JSON.stringify({ token, expiresAt: Date.now() + expiresIn * 1000 }))
  } catch {
    /* ignore */
  }
}

export function clearToken() {
  try {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(FOLDER_KEY)
  } catch {
    /* ignore */
  }
}

/** Opens Google's consent popup (must be called from a user gesture). */
export async function requestToken(prompt: '' | 'consent' | 'select_account' = ''): Promise<string> {
  if (isNative) {
    try {
      const r = await Deepwork.googleAuthorize({ interactive: true })
      saveToken(r.accessToken, r.expiresIn)
      return r.accessToken
    } catch (e) {
      throw new Error(e instanceof Error ? e.message : 'Google sign-in failed.')
    }
  }
  const clientId = getClientId()
  if (!clientId) throw new DriveConfigError('No Google OAuth Client ID configured. Add it in src/config/google.ts (see README).')
  const oauth2 = await loadGis()
  return new Promise((resolve, reject) => {
    const client = oauth2.initTokenClient({
      client_id: clientId,
      scope: GOOGLE_DRIVE_SCOPE,
      callback: (r) => {
        if (r.error || !r.access_token) return reject(new Error(r.error_description || r.error || 'Google sign-in was not completed.'))
        saveToken(r.access_token, r.expires_in ?? 3600)
        resolve(r.access_token)
      },
      error_callback: (e) => reject(new Error(e.type === 'popup_closed' ? 'Sign-in window was closed.' : e.message || 'Google sign-in failed.')),
    })
    client.requestAccessToken({ prompt })
  })
}

/** Android only: get a fresh token without any UI when access was granted before. */
export async function silentToken(): Promise<string | null> {
  if (!isNative) return null
  try {
    const r = await Deepwork.googleAuthorize({ interactive: false })
    saveToken(r.accessToken, r.expiresIn)
    return r.accessToken
  } catch {
    return null
  }
}

export async function revokeToken() {
  const t = storedToken()
  clearToken()
  if (!t) return
  if (isNative) {
    try {
      await fetch(`https://oauth2.googleapis.com/revoke?token=${encodeURIComponent(t.token)}`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' } })
    } catch {
      /* offline: the token expires on its own within an hour */
    }
    return
  }
  try {
    const oauth2 = await loadGis()
    await new Promise<void>((r) => oauth2.revoke(t.token, () => r()))
  } catch {
    /* offline: the token simply expires on its own within an hour */
  }
}

async function driveFetch(token: string, url: string, init: RequestInit = {}): Promise<Response> {
  const res = await fetch(url, { ...init, headers: { ...(init.headers || {}), Authorization: `Bearer ${token}` } })
  if (res.status === 401) {
    clearToken()
    throw new DriveAuthError()
  }
  if (!res.ok) {
    let msg = `Google Drive error (${res.status})`
    try {
      const j = await res.json()
      if (j?.error?.message) msg = j.error.message
    } catch {
      /* ignore */
    }
    if (res.status === 403 && /insufficient/i.test(msg)) throw new DriveAuthError('Drive permission was not granted. Reconnect and allow access.')
    throw new Error(msg)
  }
  return res
}

export async function getAccount(token: string): Promise<string | null> {
  const res = await driveFetch(token, `${API}/about?fields=user(emailAddress,displayName)`)
  const j = await res.json()
  return j?.user?.emailAddress ?? j?.user?.displayName ?? null
}

async function ensureFolder(token: string): Promise<string> {
  const cached = localStorage.getItem(FOLDER_KEY)
  if (cached) {
    try {
      const res = await driveFetch(token, `${API}/files/${cached}?fields=id,trashed`)
      const j = await res.json()
      if (j.id && !j.trashed) return cached
    } catch (e) {
      if (e instanceof DriveAuthError) throw e
    }
  }
  const q = encodeURIComponent(`name='${DRIVE_FOLDER_NAME}' and mimeType='application/vnd.google-apps.folder' and trashed=false`)
  const res = await driveFetch(token, `${API}/files?q=${q}&fields=files(id,name)&spaces=drive`)
  const j = await res.json()
  let id: string | undefined = j.files?.[0]?.id
  if (!id) {
    const created = await driveFetch(token, `${API}/files?fields=id`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: DRIVE_FOLDER_NAME, mimeType: 'application/vnd.google-apps.folder' }),
    })
    id = (await created.json()).id
  }
  if (!id) throw new Error('Could not create the Deepwork Backups folder.')
  localStorage.setItem(FOLDER_KEY, id)
  return id
}

export interface DriveBackup {
  id: string
  name: string
  createdTime: string
  modifiedTime: string
  size?: string
}

export async function listBackups(token: string): Promise<DriveBackup[]> {
  const folder = await ensureFolder(token)
  const q = encodeURIComponent(`'${folder}' in parents and trashed=false and mimeType='application/json'`)
  const res = await driveFetch(token, `${API}/files?q=${q}&orderBy=modifiedTime desc&pageSize=200&fields=files(id,name,createdTime,modifiedTime,size,appProperties)`)
  const j = await res.json()
  return ((j.files ?? []) as (DriveBackup & { appProperties?: Record<string, string> })[]).filter(
    (f) => f.appProperties?.deepwork === 'backup' || /^deepwork-backup-.*\.json$/.test(f.name),
  )
}

export async function uploadBackup(token: string, filename: string, json: string): Promise<DriveBackup> {
  const folder = await ensureFolder(token)
  const existing = (await listBackups(token)).find((f) => f.name === filename)
  const boundary = 'deepwork' + Math.random().toString(36).slice(2)
  const meta = existing
    ? { name: filename, mimeType: 'application/json' }
    : { name: filename, mimeType: 'application/json', parents: [folder], appProperties: { deepwork: 'backup' } }
  const body =
    `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${JSON.stringify(meta)}\r\n` +
    `--${boundary}\r\nContent-Type: application/json\r\n\r\n${json}\r\n--${boundary}--`
  const url = existing
    ? `${UPLOAD}/files/${existing.id}?uploadType=multipart&fields=id,name,createdTime,modifiedTime,size`
    : `${UPLOAD}/files?uploadType=multipart&fields=id,name,createdTime,modifiedTime,size`
  const res = await driveFetch(token, url, {
    method: existing ? 'PATCH' : 'POST',
    headers: { 'Content-Type': `multipart/related; boundary=${boundary}` },
    body,
  })
  return res.json()
}

/** Keep the newest `keep` backups; delete older ones the app created. */
export async function pruneBackups(token: string, keep: number) {
  const files = await listBackups(token)
  const old = files.slice(Math.max(1, keep))
  for (const f of old) await driveFetch(token, `${API}/files/${f.id}`, { method: 'DELETE' })
  return old.length
}

export async function downloadBackup(token: string, id: string): Promise<string> {
  const res = await driveFetch(token, `${API}/files/${id}?alt=media`)
  return res.text()
}

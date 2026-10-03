// ============================================================================
//  GOOGLE OAUTH CLIENT ID — PASTE YOURS HERE
// ============================================================================
//  Deepwork backs up to *your own* Google Drive using an OAuth "Web application"
//  client that you create in Google Cloud Console. See README.md → "Google Drive
//  backup setup" for step-by-step instructions.
//
//  Paste the Client ID between the quotes, e.g.
//    export const GOOGLE_CLIENT_ID = '1234567890-abc123.apps.googleusercontent.com'
//
//  Alternatively, set VITE_GOOGLE_CLIENT_ID in a `.env.local` file; the value
//  below takes precedence when it is not empty.
// ============================================================================
export const GOOGLE_CLIENT_ID = ''

// Narrow scope: the app can only see and manage files it created itself.
export const GOOGLE_DRIVE_SCOPE = 'https://www.googleapis.com/auth/drive.file'
export const DRIVE_FOLDER_NAME = 'Deepwork Backups'

export function getClientId(): string {
  return (GOOGLE_CLIENT_ID || (import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined) || '').trim()
}

// Bridge to the native Android layer (Capacitor). On the web every helper here is a no-op.
import { Capacitor, registerPlugin } from '@capacitor/core'

export const isNative = Capacitor.isNativePlatform()
export const isAndroid = Capacitor.getPlatform() === 'android'

export interface InstalledApp {
  packageName: string
  label: string
  icon: string // data: URL
}

export interface BlockedAttempt {
  packageName: string
  label: string
  timestamp: number
}

interface DeepworkPlugin {
  blockerStatus(): Promise<{ serviceEnabled: boolean; active: boolean }>
  openBlockerSettings(): Promise<void>
  getInstalledApps(): Promise<{ apps: InstalledApp[] }>
  startBlocking(o: { until: number; mode: 'block' | 'allow'; packages: string[]; taskTitle: string }): Promise<void>
  stopBlocking(): Promise<void>
  takeBlockedAttempts(): Promise<{ attempts: BlockedAttempt[] }>
  setKeepAwake(o: { on: boolean }): Promise<void>
  biometricAvailable(): Promise<{ available: boolean }>
  authenticate(o: { title: string }): Promise<{ success: boolean; error?: string }>
  googleAuthorize(o: { interactive: boolean }): Promise<{ accessToken: string; expiresIn: number }>
  getSigningInfo(): Promise<{ packageName: string; sha1?: string }>
}

export const Deepwork = registerPlugin<DeepworkPlugin>('Deepwork')

/** Save files on Android by handing them to the system share sheet (Files, Drive, email…). */
export async function shareFiles(files: { name: string; content: string; mime: string }[], title: string) {
  const { Filesystem, Directory, Encoding } = await import('@capacitor/filesystem')
  const { Share } = await import('@capacitor/share')
  const uris: string[] = []
  for (const f of files) {
    const res = await Filesystem.writeFile({ path: f.name, data: f.content, directory: Directory.Cache, encoding: Encoding.UTF8 })
    uris.push(res.uri)
  }
  await Share.share({ title, files: uris, dialogTitle: title })
}

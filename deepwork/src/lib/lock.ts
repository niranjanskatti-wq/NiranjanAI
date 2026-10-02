import { Deepwork, isNative } from './native'

// App lock helpers: salted PIN hashing (WebCrypto) and device biometrics via WebAuthn platform
// authenticators. Everything stays on-device; WebAuthn here is used purely as a local presence check.

function toHex(buf: ArrayBuffer) {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('')
}

function b64url(buf: ArrayBuffer) {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}

function fromB64url(s: string): Uint8Array<ArrayBuffer> {
  const b = atob(s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4))
  const out = new Uint8Array(new ArrayBuffer(b.length))
  for (let i = 0; i < b.length; i++) out[i] = b.charCodeAt(i)
  return out
}

function randomBytes(n: number): Uint8Array<ArrayBuffer> {
  const out = new Uint8Array(new ArrayBuffer(n))
  crypto.getRandomValues(out)
  return out
}

export function newSalt() {
  return toHex(randomBytes(16).buffer)
}

export async function hashPin(pin: string, salt: string): Promise<string> {
  const enc = new TextEncoder()
  const key = await crypto.subtle.importKey('raw', enc.encode(pin), 'PBKDF2', false, ['deriveBits'])
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', salt: enc.encode(salt), iterations: 120_000, hash: 'SHA-256' }, key, 256)
  return toHex(bits)
}

export async function verifyPin(pin: string, salt: string | null, hash: string | null) {
  if (!salt || !hash) return false
  return (await hashPin(pin, salt)) === hash
}

export async function biometricsAvailable(): Promise<boolean> {
  if (isNative) return (await Deepwork.biometricAvailable().catch(() => ({ available: false }))).available
  try {
    if (!window.PublicKeyCredential || !window.isSecureContext) return false
    return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()
  } catch {
    return false
  }
}

/** Register a platform credential (Face ID / Touch ID / Windows Hello). Returns the credential id. */
export async function registerBiometric(): Promise<string> {
  if (isNative) {
    const r = await Deepwork.authenticate({ title: 'Confirm fingerprint unlock' })
    if (!r.success) throw new Error(r.error || 'Biometric setup was cancelled.')
    return 'android'
  }
  const cred = (await navigator.credentials.create({
    publicKey: {
      challenge: randomBytes(32),
      rp: { name: 'Deepwork' },
      user: { id: randomBytes(16), name: 'deepwork-user', displayName: 'Deepwork' },
      pubKeyCredParams: [
        { type: 'public-key', alg: -7 },
        { type: 'public-key', alg: -257 },
      ],
      authenticatorSelection: { authenticatorAttachment: 'platform', userVerification: 'required', residentKey: 'discouraged' },
      timeout: 60000,
      attestation: 'none',
    },
  })) as PublicKeyCredential | null
  if (!cred) throw new Error('Biometric setup was cancelled.')
  return b64url(cred.rawId)
}

export async function verifyBiometric(credentialId: string): Promise<boolean> {
  if (isNative) return (await Deepwork.authenticate({ title: 'Unlock Deepwork' }).catch(() => ({ success: false }))).success
  try {
    const res = await navigator.credentials.get({
      publicKey: {
        challenge: randomBytes(32),
        allowCredentials: [{ type: 'public-key', id: fromB64url(credentialId), transports: ['internal'] }],
        userVerification: 'required',
        timeout: 60000,
      },
    })
    return !!res
  } catch {
    return false
  }
}

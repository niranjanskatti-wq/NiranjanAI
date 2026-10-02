import { isNative, shareFiles } from './native'
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function clamp(n: number, min: number, max: number) {
  return Math.min(max, Math.max(min, n))
}

export function sum(arr: number[]) {
  return arr.reduce((a, b) => a + b, 0)
}

export function groupBy<T, K extends string | number>(arr: T[], key: (t: T) => K): Record<K, T[]> {
  const out = {} as Record<K, T[]>
  for (const item of arr) {
    const k = key(item)
    ;(out[k] ||= []).push(item)
  }
  return out
}

export function pluralize(n: number, one: string, many = one + 's') {
  return `${n} ${n === 1 ? one : many}`
}

export function downloadFile(filename: string, content: string | Blob, type = 'application/json') {
  if (isNative && typeof content === 'string') {
    void shareFiles([{ name: filename, content, mime: type }], filename)
    return
  }
  const blob = typeof content === 'string' ? new Blob([content], { type }) : content
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}

export function hexToRgb(hex: string): [number, number, number] | null {
  const m = /^#?([0-9a-f]{6}|[0-9a-f]{3})$/i.exec(hex.trim())
  if (!m) return null
  let h = m[1]
  if (h.length === 3) h = h.split('').map((c) => c + c).join('')
  const n = parseInt(h, 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}

/** Pick readable text color for a given background color. */
export function contrastText(hex: string): string {
  const rgb = hexToRgb(hex)
  if (!rgb) return '#fff'
  const [r, g, b] = rgb.map((v) => {
    const c = v / 255
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
  })
  const l = 0.2126 * r + 0.7152 * g + 0.0722 * b
  return l > 0.45 ? '#0B0B0F' : '#FFFFFF'
}

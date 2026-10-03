// Renders the app icons (PNG) from an inline SVG using Playwright's Chromium.
// Usage: node scripts/generate-icons.mjs   (requires `playwright` to be resolvable)
import { chromium } from 'playwright'
import { writeFile } from 'node:fs/promises'

const svg = (size, maskable) => {
  const pad = maskable ? size * 0.16 : 0
  const inner = size - pad * 2
  const radius = maskable ? 0 : size * 0.22
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="${size}" height="${size}" rx="${radius}" fill="${maskable ? '#0B0B0F' : '#7C7CFF'}"/>
  <g transform="translate(${pad} ${pad}) scale(${inner / 32})">
    ${maskable ? '<rect width="32" height="32" rx="9" fill="#7C7CFF"/>' : ''}
    <circle cx="16" cy="16" r="8.5" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="2.6"/>
    <path d="M16 7.5a8.5 8.5 0 0 1 8.5 8.5" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round"/>
    <circle cx="16" cy="16" r="2.4" fill="#fff"/>
  </g></svg>`
}

const targets = [
  ['public/pwa-192.png', 192, false],
  ['public/pwa-512.png', 512, false],
  ['public/pwa-maskable-512.png', 512, true],
  ['public/apple-touch-icon.png', 180, true],
]

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined })
const page = await browser.newPage()
for (const [file, size, maskable] of targets) {
  await page.setViewportSize({ width: size, height: size })
  await page.setContent(`<html><body style="margin:0;background:transparent">${svg(size, maskable)}</body></html>`)
  const buf = await page.locator('svg').screenshot({ omitBackground: true })
  await writeFile(file, buf)
  console.log('wrote', file)
}
await browser.close()

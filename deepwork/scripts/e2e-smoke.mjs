import { chromium } from 'playwright'
// Run against `npm run build && npm run preview`. Requires the `playwright` package and a Chromium.
const OUT = process.env.SHOTS_DIR || './e2e-shots'
import { mkdirSync } from 'node:fs'
mkdirSync(OUT, { recursive: true })
const URL = process.env.APP_URL || 'http://localhost:4173'
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined })
const errors = []
async function newPage(ctx) {
  const p = await ctx.newPage()
  p.on('console', (m) => m.type() === 'error' && errors.push(m.text()))
  p.on('pageerror', (e) => errors.push('PAGEERROR ' + e.message))
  return p
}
const step = (s) => console.log('→', s)
// Simulate time passing (e.g. app closed / backgrounded) by shifting stored timestamps, then reopen.
async function advance(p, ms) {
  await p.evaluate((ms) => {
    const s = JSON.parse(localStorage.getItem('deepwork.focus'))
    if (s.startedAt) s.startedAt -= ms
    if (s.pausedAt) s.pausedAt -= ms
    if (s.breakStartedAt) s.breakStartedAt -= ms
    localStorage.setItem('deepwork.focus', JSON.stringify(s))
  }, ms)
  await p.reload()
}

const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 })
const page = await newPage(ctx)
await page.goto(URL)
await page.getByText('Start focus').first().waitFor()
step('today loaded')
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/01-today-empty.png`, fullPage: true })

// add a priority via picker (create task)
await page.getByRole('button', { name: 'Choose priorities' }).click()
await page.getByPlaceholder('Search or create a task').fill('Write chapter outline')
await page.keyboard.press('Enter')
await page.getByText('Write chapter outline').first().waitFor()
step('priority created')

// start focus on it
await page.getByRole('button', { name: /Focus on Write chapter outline/ }).click()
await page.getByRole('button', { name: /Start 25-minute session/ }).click()
await page.getByText('remaining').waitFor()
step('session running')
await advance(page, 300000)
await page.getByRole('button', { name: 'Distracted' }).click()
await page.getByRole('button', { name: 'Phone' }).click()
await page.getByRole('button', { name: 'Log distraction' }).click()
step('distraction logged')
await page.getByRole('button', { name: 'Pause' }).click()
await page.getByText('paused').waitFor()
await page.getByRole('button', { name: 'Resume' }).click()
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/02-focus-running.png` })
await advance(page, 1260000)
await page.getByText('How did it go?').waitFor({ timeout: 5000 })
step('session completed → close')
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/03-session-close.png` })
await page.getByRole('button', { name: /^Stuck/ }).click()
await page.getByPlaceholder('e.g. Write the first heading').fill('List three section headings')
await page.getByRole('button', { name: 'Save session' }).click()
await page.getByText('Session complete').waitFor()
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/04-session-complete.png` })
await page.getByRole('button', { name: /Start 5-minute short break/ }).click()
await page.getByText('short break').waitFor()
await advance(page, 305000)
await page.getByText("Break's over").waitFor()
step('break over')
await page.getByRole('button', { name: 'Done for now' }).click()
await page.getByText('Start focus').first().waitFor()

// end-early flow
await page.goto(URL + '/focus')
await page.getByRole('button', { name: /List three section headings/ }).click()
await page.getByRole('button', { name: /Start 25-minute/ }).click()
await advance(page, 180000)
await page.getByRole('button', { name: 'End' }).click()
await page.getByRole('button', { name: 'Out of energy' }).click()
await page.getByText('Session ended early').waitFor()
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/05-interrupted.png` })
await page.getByRole('button', { name: 'Back to Today', exact: true }).last().click()
step('interrupted flow ok')
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/06-today-after.png`, fullPage: true })

// tasks
await page.getByRole('link', { name: 'Tasks' }).click()
await page.getByPlaceholder('Add a task…').fill('Email supervisor')
await page.keyboard.press('Enter')
await page.getByText('Email supervisor').click()
await page.getByPlaceholder('Add a step').fill('Draft')
await page.keyboard.press('Enter')
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/07-task-sheet.png` })
await page.keyboard.press('Escape')
step('tasks ok')

// demo data + insights
await page.goto(URL + '/settings/data')
await page.getByRole('button', { name: /Load/ }).first().click()
await page.getByText(/Loaded \d+ demo sessions/).waitFor({ timeout: 15000 })
await page.goto(URL + '/insights')
await page.getByText('Focus hours').first().waitFor()
await page.waitForTimeout(800)
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/08-insights.png`, fullPage: true })
step('insights ok')
await page.goto(URL + '/review/weekly')
await page.getByText('Best focus time').first().waitFor()
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/09-weekly.png`, fullPage: true })
await page.goto(URL + '/review/evening')
await page.getByText('Planned vs. done').waitFor()
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/10-evening.png`, fullPage: true })
await page.getByRole('button', { name: 'Save review' }).click()
await page.getByText('Evening review saved').waitFor()
step('reviews ok')

for (const s of ['features', 'customize', 'appearance', 'notifications', 'privacy', 'backup', 'data', 'about']) {
  await page.goto(URL + '/settings/' + s)
  await page.waitForTimeout(300)
  await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/11-settings-${s}.png`, fullPage: true })
}
step('settings pages ok')

// light theme + today with demo
await page.goto(URL + '/settings/appearance')
await page.getByRole('button', { name: 'Light' }).click()
await page.goto(URL + '/')
await page.waitForTimeout(500)
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/12-today-light.png`, fullPage: true })

// turn all modules off
await page.goto(URL + '/settings/features')
const switches = page.getByRole('switch')
const n = await switches.count()
for (let i = 0; i < n; i++) {
  const sw = switches.nth(i)
  if ((await sw.isEnabled()) && (await sw.getAttribute('aria-checked')) === 'true') await sw.click()
}
await page.goto(URL + '/')
await page.waitForTimeout(400)
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/13-today-all-off.png`, fullPage: true })
await page.goto(URL + '/focus')
await page.waitForTimeout(300)
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/14-focus-all-off.png`, fullPage: true })
step('all modules off ok')
await page.goto(URL + '/settings/features')
await page.getByRole('button', { name: 'Reset' }).click()
await page.getByRole('button', { name: 'Reset' }).last().click()

// lock
await page.goto(URL + '/settings/privacy')
await page.getByRole('switch', { name: 'App lock' }).click()
await page.getByRole('textbox', { name: 'PIN' }).fill('1234')
await page.getByRole('button', { name: 'Next' }).click()
await page.getByRole('textbox', { name: 'PIN' }).fill('1234')
await page.getByRole('button', { name: 'Turn on' }).click(); await page.waitForTimeout(800); await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/dbg-lock.png` })
await page.reload()
await page.getByText('Enter your PIN').waitFor()
await page.waitForTimeout(700); await page.screenshot({ path: `${OUT}/15-lock.png` })
for (const d of '1234') await page.getByRole('button', { name: d, exact: true }).click()
await page.getByText('Enter your PIN').waitFor({ state: 'detached' })
step('lock ok')

// desktop
const dctx = await browser.newContext({ viewport: { width: 1360, height: 900 } })
const dp = await newPage(dctx)
await dp.goto(URL)
await dp.getByText('Start focus').first().waitFor()
await dp.waitForTimeout(700); await dp.screenshot({ path: `${OUT}/16-desktop-today.png`, fullPage: true })
await dp.goto(URL + '/settings/customize')
await dp.waitForTimeout(400)
await dp.waitForTimeout(700); await dp.screenshot({ path: `${OUT}/17-desktop-settings.png` })
// offline: wait for SW then reload offline
await dp.waitForFunction(() => navigator.serviceWorker && navigator.serviceWorker.controller, null, { timeout: 15000 }).catch(() => {})
await dp.reload()
await dp.waitForFunction(() => !!navigator.serviceWorker.controller, null, { timeout: 15000 })
await dctx.setOffline(true)
await dp.goto(URL + '/insights')
await dp.getByText('Insights').first().waitFor()
await dp.goto(URL + '/tasks')
await dp.getByText('Tasks').first().waitFor()
await dp.waitForTimeout(700); await dp.screenshot({ path: `${OUT}/18-offline-tasks.png` })
step('offline ok')

console.log('ERRORS:', errors.length ? errors.join('\n') : 'none')
await browser.close()

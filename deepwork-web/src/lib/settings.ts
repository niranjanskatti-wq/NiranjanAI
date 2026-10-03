// Settings schema, defaults, and helpers. Everything here is persisted in IndexedDB.

export type ModuleKey =
  | 'priorities'
  | 'timeBlocks'
  | 'tasks'
  | 'subtasks'
  | 'focus'
  | 'distractions'
  | 'sessionClose'
  | 'breaks'
  | 'ambient'
  | 'streaks'
  | 'eveningReview'
  | 'weeklyReview'
  | 'insights'
  | 'insightCards'
  | 'summary'
  | 'backup'
  | 'notifications'

export const MODULES: { key: ModuleKey; label: string; description: string; locked?: boolean }[] = [
  { key: 'priorities', label: 'Top priorities', description: 'The few things that matter most today.' },
  { key: 'timeBlocks', label: 'Hourly time blocks', description: 'Plan your day on an hourly timeline.' },
  { key: 'tasks', label: 'Task list', description: 'Projects, estimates, due dates and status.' },
  { key: 'subtasks', label: 'Subtasks', description: 'A checklist inside each task.' },
  { key: 'focus', label: 'Focus timer', description: 'The core of the app. Always on.', locked: true },
  { key: 'distractions', label: 'Distraction logging', description: 'Log what pulls you away, without stopping the timer.' },
  { key: 'sessionClose', label: 'Session close', description: 'Record the result and a note after each session.' },
  { key: 'breaks', label: 'Break reminders', description: 'Suggested breaks and a break timer.' },
  { key: 'ambient', label: 'Ambient sounds', description: 'Rain, café, white and brown noise.' },
  { key: 'streaks', label: 'Streaks', description: 'Consecutive days that meet your rule.' },
  { key: 'eveningReview', label: 'Evening review', description: 'A two-minute look back at the day.' },
  { key: 'weeklyReview', label: 'Weekly review', description: 'A ten-minute look back at the week.' },
  { key: 'insights', label: 'Insights & charts', description: 'Charts of focus, distractions and completion.' },
  { key: 'insightCards', label: 'Insight cards', description: 'Plain-language observations from your data.' },
  { key: 'summary', label: 'Daily summary strip', description: 'Focus time, tasks done and goal progress.' },
  { key: 'backup', label: 'Google Drive backup', description: 'Weekly automatic backup to your own Drive.' },
  { key: 'notifications', label: 'Notifications', description: 'Reminders and timer alerts.' },
]

export type HomeSectionId =
  | 'startFocus'
  | 'summary'
  | 'priorities'
  | 'timeline'
  | 'streak'
  | 'eveningReview'
  | 'weeklyReview'
  | 'backup'

export const HOME_SECTIONS: Record<HomeSectionId, { label: string; module?: ModuleKey }> = {
  startFocus: { label: 'Start focus button' },
  summary: { label: 'Daily summary strip', module: 'summary' },
  streak: { label: 'Streak', module: 'streaks' },
  priorities: { label: 'Top priorities', module: 'priorities' },
  timeline: { label: 'Time blocks', module: 'timeBlocks' },
  eveningReview: { label: 'Evening review card', module: 'eveningReview' },
  weeklyReview: { label: 'Weekly review card', module: 'weeklyReview' },
  backup: { label: 'Backup status', module: 'backup' },
}

export type ChartId = 'focusHours' | 'distractionReasons' | 'completionRate' | 'heatmap' | 'byProject'
export const CHARTS: { id: ChartId; label: string; module?: ModuleKey }[] = [
  { id: 'focusHours', label: 'Focus hours' },
  { id: 'distractionReasons', label: 'Distractions by reason', module: 'distractions' },
  { id: 'completionRate', label: 'Completion rate' },
  { id: 'heatmap', label: 'Best hours heatmap' },
  { id: 'byProject', label: 'Sessions by project', module: 'tasks' },
]

export type InsightCardId =
  | 'interruptionTime'
  | 'bestLength'
  | 'priorityCompletion'
  | 'topDistraction'
  | 'bestDay'
  | 'trend'
  | 'bestTime'
  | 'stuckProject'
export const INSIGHT_CARDS: { id: InsightCardId; label: string; module?: ModuleKey }[] = [
  { id: 'interruptionTime', label: 'When interruptions happen', module: 'distractions' },
  { id: 'bestLength', label: 'Best session length' },
  { id: 'priorityCompletion', label: 'Priority completion', module: 'priorities' },
  { id: 'topDistraction', label: 'Top distraction', module: 'distractions' },
  { id: 'bestDay', label: 'Best day of the week' },
  { id: 'trend', label: 'Focus trend' },
  { id: 'bestTime', label: 'Best focus time' },
  { id: 'stuckProject', label: 'Where you get stuck', module: 'tasks' },
]

export type RangeOption = 7 | 14 | 30 | 90 | 0 // 0 = all time
export type AmbientSound = 'rain' | 'cafe' | 'white' | 'brown'
export const AMBIENT_SOUNDS: { id: AmbientSound; label: string }[] = [
  { id: 'rain', label: 'Rain' },
  { id: 'cafe', label: 'Café' },
  { id: 'white', label: 'White noise' },
  { id: 'brown', label: 'Brown noise' },
]

export type TaskField = 'project' | 'estimate' | 'dueDate' | 'flag' | 'status' | 'sessions' | 'subtasks'
export const TASK_FIELDS: { id: TaskField; label: string }[] = [
  { id: 'project', label: 'Project tag' },
  { id: 'estimate', label: 'Estimated sessions' },
  { id: 'sessions', label: 'Sessions spent vs. estimate' },
  { id: 'dueDate', label: 'Due date' },
  { id: 'flag', label: 'Priority flag' },
  { id: 'status', label: 'Status' },
  { id: 'subtasks', label: 'Subtask progress' },
]

export interface Settings {
  version: number
  modules: Record<ModuleKey, boolean>
  priorities: { count: number; label: string }
  timeBlocks: { dayStart: string; dayEnd: string; blockLength: 15 | 30 | 60; showWeekends: boolean }
  tasks: { visibleFields: TaskField[] }
  focus: {
    presets: number[] // minutes
    defaultDuration: number
    allowCustom: boolean
    mode: 'countdown' | 'countup'
    hideSeconds: boolean
    requireTask: boolean
    wakeLock: boolean
  }
  ring: { style: 'thin' | 'bold' | 'segmented'; glow: boolean; completionAnimation: boolean }
  distractions: { noteEnabled: boolean }
  sessionClose: {
    results: { done: boolean; partly: boolean; stuck: boolean }
    note: 'required' | 'optional' | 'hidden'
    stuckPrompt: boolean
  }
  breaks: { short: number; long: number; longAfter: number; autoStartNext: boolean }
  ambient: { available: AmbientSound[]; volume: number; defaultOn: boolean; defaultSound: AmbientSound }
  streaks: { rule: 'strict' | 'neverMissTwice' | 'weekdays'; countsAs: 'session' | 'minutes' | 'tasks'; amount: number }
  eveningReview: { questions: string[]; time: string }
  weeklyReview: { day: number; time: string; questions: string[] }
  insights: { charts: ChartId[]; cards: InsightCardId[]; defaultRange: RangeOption }
  dailyGoal: { type: 'minutes' | 'sessions' | 'tasks'; target: number }
  notifications: {
    morning: { enabled: boolean; time: string }
    evening: { enabled: boolean }
    weekly: { enabled: boolean }
    breakOver: boolean
    sessionComplete: boolean
    quietHours: { enabled: boolean; start: string; end: string }
  }
  appearance: {
    theme: 'dark' | 'light' | 'system'
    accent: string
    font: 'inter' | 'geist' | 'serif'
    textSize: 'small' | 'medium' | 'large'
    density: 'comfortable' | 'compact'
    animations: 'full' | 'reduced' | 'off'
    homeLayout: { id: HomeSectionId; visible: boolean }[]
  }
  lock: {
    enabled: boolean
    pinHash: string | null
    pinSalt: string | null
    pinLength: number
    biometric: boolean
    credentialId: string | null
    autoLockMinutes: number // 0 = when app is hidden
  }
  backup: {
    day: number // 0 = Sunday
    retention: number
    connected: boolean
    account: string | null
    lastBackupAt: number | null
    lastAttemptAt: number | null
    lastError: string | null
    needsReconnect: boolean
  }
  sidebarCollapsed: boolean
  demoLoaded: boolean
}

export const ACCENT_PRESETS = ['#7C7CFF', '#5B8DEF', '#22C3A6', '#4ADE80', '#F59E0B', '#F472B6', '#EF6F6C', '#A78BFA']

export const DEFAULT_SETTINGS: Settings = {
  version: 1,
  modules: {
    priorities: true,
    timeBlocks: true,
    tasks: true,
    subtasks: true,
    focus: true,
    distractions: true,
    sessionClose: true,
    breaks: true,
    ambient: true,
    streaks: true,
    eveningReview: true,
    weeklyReview: true,
    insights: true,
    insightCards: true,
    summary: true,
    backup: false,
    notifications: true,
  },
  priorities: { count: 3, label: 'Top priorities' },
  timeBlocks: { dayStart: '08:00', dayEnd: '18:00', blockLength: 60, showWeekends: true },
  tasks: { visibleFields: ['project', 'estimate', 'sessions', 'dueDate', 'flag', 'status', 'subtasks'] },
  focus: {
    presets: [15, 25, 45, 60, 90],
    defaultDuration: 25,
    allowCustom: true,
    mode: 'countdown',
    hideSeconds: false,
    requireTask: true,
    wakeLock: true,
  },
  ring: { style: 'bold', glow: true, completionAnimation: true },
  distractions: { noteEnabled: true },
  sessionClose: { results: { done: true, partly: true, stuck: true }, note: 'optional', stuckPrompt: true },
  breaks: { short: 5, long: 15, longAfter: 4, autoStartNext: false },
  ambient: { available: ['rain', 'cafe', 'white', 'brown'], volume: 0.5, defaultOn: false, defaultSound: 'rain' },
  streaks: { rule: 'neverMissTwice', countsAs: 'session', amount: 1 },
  eveningReview: { questions: ['One thing to do differently tomorrow?'], time: '20:00' },
  weeklyReview: {
    day: 0,
    time: '17:00',
    questions: ['What went well?', 'What should I cut?', 'Top 3 priorities for next week?'],
  },
  insights: {
    charts: ['focusHours', 'distractionReasons', 'completionRate', 'heatmap', 'byProject'],
    cards: ['interruptionTime', 'bestLength', 'priorityCompletion', 'topDistraction', 'bestDay', 'trend', 'bestTime', 'stuckProject'],
    defaultRange: 14,
  },
  dailyGoal: { type: 'minutes', target: 120 },
  notifications: {
    morning: { enabled: true, time: '08:30' },
    evening: { enabled: true },
    weekly: { enabled: true },
    breakOver: true,
    sessionComplete: true,
    quietHours: { enabled: false, start: '22:00', end: '07:00' },
  },
  appearance: {
    theme: 'dark',
    accent: '#7C7CFF',
    font: 'inter',
    textSize: 'medium',
    density: 'comfortable',
    animations: 'full',
    homeLayout: [
      { id: 'startFocus', visible: true },
      { id: 'summary', visible: true },
      { id: 'streak', visible: true },
      { id: 'eveningReview', visible: true },
      { id: 'weeklyReview', visible: true },
      { id: 'priorities', visible: true },
      { id: 'timeline', visible: true },
      { id: 'backup', visible: true },
    ],
  },
  lock: {
    enabled: false,
    pinHash: null,
    pinSalt: null,
    pinLength: 4,
    biometric: false,
    credentialId: null,
    autoLockMinutes: 5,
  },
  backup: {
    day: 0,
    retention: 8,
    connected: false,
    account: null,
    lastBackupAt: null,
    lastAttemptAt: null,
    lastError: null,
    needsReconnect: false,
  },
  sidebarCollapsed: false,
  demoLoaded: false,
}

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v)
}

/** Deep-merge stored settings over defaults so new keys added in later versions get defaults. */
export function mergeSettings(stored: unknown, defaults: Settings = DEFAULT_SETTINGS): Settings {
  const merge = (d: unknown, s: unknown): unknown => {
    if (s === undefined) return structuredClone(d)
    if (isObj(d) && isObj(s)) {
      const out: Record<string, unknown> = {}
      for (const k of Object.keys(d)) out[k] = merge(d[k], s[k])
      return out
    }
    if (Array.isArray(d)) return Array.isArray(s) ? s : structuredClone(d)
    if (typeof d !== typeof s && d !== null) return d
    return s
  }
  const merged = merge(defaults, stored) as Settings
  // Ensure home layout contains every section exactly once.
  const seen = new Set<HomeSectionId>()
  const layout = merged.appearance.homeLayout.filter((s) => s.id in HOME_SECTIONS && !seen.has(s.id) && seen.add(s.id))
  for (const def of defaults.appearance.homeLayout) if (!seen.has(def.id)) layout.push({ ...def })
  merged.appearance.homeLayout = layout
  merged.modules.focus = true
  return merged
}

/** Per-module reset: which settings keys belong to which customization section. */
export type ResettableSection =
  | 'priorities'
  | 'timeBlocks'
  | 'tasks'
  | 'focus'
  | 'ring'
  | 'distractions'
  | 'sessionClose'
  | 'breaks'
  | 'ambient'
  | 'streaks'
  | 'eveningReview'
  | 'weeklyReview'
  | 'insights'
  | 'dailyGoal'
  | 'notifications'
  | 'appearance'
  | 'modules'

export function resetSection(s: Settings, section: ResettableSection): void {
  if (section === 'modules') {
    // Keep backup state as-is (it depends on whether Drive is connected).
    const backupOn = s.modules.backup
    s.modules = structuredClone(DEFAULT_SETTINGS.modules)
    s.modules.backup = backupOn
    return
  }
  ;(s as unknown as Record<string, unknown>)[section] = structuredClone(DEFAULT_SETTINGS[section])
}

import { AnimatePresence, motion } from 'framer-motion'
import type { ReactNode } from 'react'
import type { Settings } from '@/lib/settings'

export type RingStatus = 'active' | 'paused' | 'complete' | 'interrupted' | 'break' | 'idle'

const SIZE = 320
const C = SIZE / 2

export function ProgressRing({
  progress,
  status,
  ring,
  children,
}: {
  progress: number
  status: RingStatus
  ring: Settings['ring']
  children?: ReactNode
}) {
  const p = Math.max(0, Math.min(1, progress))
  const stroke = ring.style === 'thin' ? 4 : ring.style === 'bold' ? 14 : 12
  const r = C - 24
  const circ = 2 * Math.PI * r
  const color =
    status === 'interrupted' ? 'var(--muted)' : status === 'break' ? 'var(--success)' : 'var(--accent)'
  const glowOn = ring.glow && status !== 'interrupted' && status !== 'idle'
  const glowPx = 4 + 22 * p
  const glowAlpha = status === 'paused' ? 0.25 : 0.35 + 0.5 * p
  const filter = glowOn ? `drop-shadow(0 0 ${glowPx}px color-mix(in oklab, ${color} ${Math.round(glowAlpha * 100)}%, transparent))` : 'none'

  return (
    <div className="relative mx-auto aspect-square w-[min(80vw,360px)] max-h-[48dvh] max-w-full">
      {/* ambient glow behind the ring, intensifying with progress */}
      {glowOn && (
        <div
          className="pointer-events-none absolute -inset-[10%] rounded-full transition-opacity duration-700"
          style={{
            background: `radial-gradient(circle, color-mix(in oklab, ${color} 55%, transparent) 0%, transparent 62%)`,
            opacity: 0.08 + 0.32 * p * (status === 'paused' ? 0.5 : 1),
          }}
        />
      )}
      <motion.svg
        viewBox={`0 0 ${SIZE} ${SIZE}`}
        className="absolute inset-0 size-full -rotate-90 overflow-visible"
        animate={status === 'complete' && ring.completionAnimation ? { scale: [1, 1.045, 1] } : { scale: 1 }}
        transition={{ duration: 0.9, ease: 'easeInOut' }}
      >
        {ring.style === 'segmented' ? (
          <Segments p={p} r={r} stroke={stroke} color={color} filter={filter} status={status} />
        ) : (
          <>
            <circle cx={C} cy={C} r={r} fill="none" stroke="var(--border)" strokeWidth={stroke} opacity={0.8} />
            <motion.circle
              cx={C}
              cy={C}
              r={r}
              fill="none"
              strokeWidth={stroke}
              strokeLinecap="round"
              strokeDasharray={circ}
              initial={false}
              animate={{
                strokeDashoffset: circ * (1 - p),
                stroke: color,
                opacity: status === 'interrupted' ? 0.45 : status === 'paused' ? 0.7 : 1,
              }}
              transition={{ strokeDashoffset: { duration: 0.25, ease: 'linear' }, stroke: { duration: 0.8 }, opacity: { duration: 0.8 } }}
              style={{ filter, transition: 'filter 600ms ease' }}
            />
          </>
        )}
      </motion.svg>
      <AnimatePresence>
        {status === 'complete' && ring.completionAnimation && (
          <motion.div
            key="pulse"
            className="pointer-events-none absolute inset-[7%] rounded-full border-2"
            style={{ borderColor: color }}
            initial={{ opacity: 0.7, scale: 0.95 }}
            animate={{ opacity: 0, scale: 1.25 }}
            transition={{ duration: 1.4, ease: 'easeOut' }}
          />
        )}
      </AnimatePresence>
      <div className="absolute inset-0 flex flex-col items-center justify-center text-center">{children}</div>
    </div>
  )
}

function Segments({ p, r, stroke, color, filter, status }: { p: number; r: number; stroke: number; color: string; filter: string; status: RingStatus }) {
  const n = 60
  const gap = 0.9 // degrees
  const filled = p * n
  const arcs = []
  for (let i = 0; i < n; i++) {
    const a0 = ((i * 360) / n + gap / 2) * (Math.PI / 180)
    const a1 = (((i + 1) * 360) / n - gap / 2) * (Math.PI / 180)
    const d = `M ${C + r * Math.cos(a0)} ${C + r * Math.sin(a0)} A ${r} ${r} 0 0 1 ${C + r * Math.cos(a1)} ${C + r * Math.sin(a1)}`
    const fill = Math.max(0, Math.min(1, filled - i))
    arcs.push(
      <g key={i}>
        <path d={d} fill="none" stroke="var(--border)" strokeWidth={stroke} opacity={0.8} />
        {fill > 0 && (
          <path
            d={d}
            fill="none"
            stroke={color}
            strokeWidth={stroke}
            opacity={(status === 'interrupted' ? 0.45 : 1) * (0.35 + 0.65 * fill)}
            style={{ transition: 'stroke 800ms ease, opacity 300ms ease' }}
          />
        )}
      </g>,
    )
  }
  return <g style={{ filter, transition: 'filter 600ms ease' }}>{arcs}</g>
}

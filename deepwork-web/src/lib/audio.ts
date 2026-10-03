// Ambient sounds and chimes, synthesized on-device with the Web Audio API.
// Nothing is streamed or downloaded: each soundscape is generated into a looping buffer the first
// time it's played, so the sounds ship with the app bundle and work fully offline.
import type { AmbientSound } from './settings'

let ctx: AudioContext | null = null
const buffers = new Map<AmbientSound, AudioBuffer>()

function audioCtx(): AudioContext {
  if (!ctx) {
    const AC = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext
    ctx = new AC()
  }
  if (ctx.state === 'suspended') void ctx.resume()
  return ctx
}

/** Deterministic PRNG so loops sound the same every time. */
function rng(seed: number) {
  let s = seed >>> 0
  return () => {
    s = (s + 0x6d2b79f5) >>> 0
    let t = s
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

/** Crossfade the tail into the head so the buffer loops without a click. */
function makeSeamless(data: Float32Array, sampleRate: number, fadeSec = 0.6) {
  const n = Math.floor(fadeSec * sampleRate)
  const len = data.length
  for (let i = 0; i < n; i++) {
    const a = i / n
    data[i] = data[i] * a + data[len - n + i] * (1 - a)
  }
  return data.subarray(0, len - n)
}

function normalize(data: Float32Array, peak = 0.9) {
  let max = 0
  for (let i = 0; i < data.length; i++) max = Math.max(max, Math.abs(data[i]))
  if (max > 0) for (let i = 0; i < data.length; i++) data[i] = (data[i] / max) * peak
}

function generate(kind: AmbientSound, sr: number): Float32Array[] {
  const seconds = kind === 'white' || kind === 'brown' ? 6 : 18
  const len = Math.floor(seconds * sr)
  const channels = [new Float32Array(len), new Float32Array(len)]
  channels.forEach((data, ch) => {
    const r = rng(kind.length * 1000 + ch * 77 + 13)
    if (kind === 'white') {
      for (let i = 0; i < len; i++) data[i] = (r() * 2 - 1) * 0.6
    } else if (kind === 'brown') {
      let last = 0
      for (let i = 0; i < len; i++) {
        last = (last + 0.02 * (r() * 2 - 1)) / 1.02
        data[i] = last * 3.5
      }
    } else if (kind === 'rain') {
      // Pink-ish bed + high-passed hiss + thousands of tiny droplets.
      let b0 = 0, b1 = 0, b2 = 0, hp = 0, lastW = 0
      for (let i = 0; i < len; i++) {
        const w = r() * 2 - 1
        b0 = 0.99765 * b0 + w * 0.099046
        b1 = 0.963 * b1 + w * 0.2965164
        b2 = 0.57 * b2 + w * 1.0526913
        const pink = (b0 + b1 + b2 + w * 0.1848) * 0.11
        hp = 0.85 * (hp + w - lastW)
        lastW = w
        const swell = 0.85 + 0.15 * Math.sin((i / sr) * 0.35 * Math.PI * 2 + ch)
        data[i] = (pink * 0.9 + hp * 0.18) * swell
      }
      const drops = Math.floor(seconds * 140)
      for (let d = 0; d < drops; d++) {
        const start = Math.floor(r() * len)
        const amp = 0.05 + r() * r() * 0.35
        const freq = 1800 + r() * 4200
        const dur = Math.floor(sr * (0.004 + r() * 0.018))
        for (let k = 0; k < dur && start + k < len; k++) {
          const env = Math.exp(-k / (dur * 0.25))
          data[start + k] += Math.sin((2 * Math.PI * freq * k) / sr) * env * amp * (r() * 0.6 + 0.4)
        }
      }
    } else if (kind === 'cafe') {
      // Low room rumble + murmuring voice-band noise with slow random swells + occasional cup clinks.
      let brown = 0
      let bp1 = 0, bp2 = 0
      let env = 0.5
      let target = 0.5
      for (let i = 0; i < len; i++) {
        const w = r() * 2 - 1
        brown = (brown + 0.02 * w) / 1.02
        // crude band-pass around voice frequencies (two one-pole stages)
        bp1 += 0.12 * (w - bp1)
        bp2 += 0.02 * (bp1 - bp2)
        const voice = bp1 - bp2
        if (i % Math.floor(sr * 0.09) === 0) target = 0.25 + r() * 0.9
        env += (target - env) * 0.0006
        data[i] = brown * 2.2 + voice * env * 1.6
      }
      const clinks = Math.floor(seconds * 0.7)
      for (let c = 0; c < clinks; c++) {
        const start = Math.floor(r() * len)
        const f = 2400 + r() * 2600
        const amp = 0.04 + r() * 0.08
        const dur = Math.floor(sr * 0.35)
        for (let k = 0; k < dur && start + k < len; k++) {
          const e = Math.exp(-k / (sr * 0.06))
          data[start + k] += (Math.sin((2 * Math.PI * f * k) / sr) + 0.5 * Math.sin((2 * Math.PI * f * 2.7 * k) / sr)) * e * amp
        }
      }
    }
    normalize(data, kind === 'white' ? 0.5 : 0.8)
  })
  return channels.map((c) => makeSeamless(c, sr))
}

function getBuffer(kind: AmbientSound): AudioBuffer {
  const c = audioCtx()
  let buf = buffers.get(kind)
  if (!buf) {
    const chans = generate(kind, c.sampleRate)
    buf = c.createBuffer(2, chans[0].length, c.sampleRate)
    chans.forEach((d, i) => buf!.copyToChannel(new Float32Array(d), i))
    buffers.set(kind, buf)
  }
  return buf
}

class AmbientPlayer {
  private source: AudioBufferSourceNode | null = null
  private gain: GainNode | null = null
  current: AmbientSound | null = null
  private volume = 0.5

  play(kind: AmbientSound, volume: number) {
    const c = audioCtx()
    this.volume = volume
    if (this.current === kind && this.source) {
      this.setVolume(volume)
      return
    }
    this.stop(0.25)
    const src = c.createBufferSource()
    src.buffer = getBuffer(kind)
    src.loop = true
    const filter = c.createBiquadFilter()
    filter.type = 'lowpass'
    filter.frequency.value = kind === 'white' ? 9000 : kind === 'brown' ? 900 : kind === 'cafe' ? 5000 : 7000
    const gain = c.createGain()
    gain.gain.value = 0
    gain.gain.linearRampToValueAtTime(this.curve(volume), c.currentTime + 0.8)
    src.connect(filter).connect(gain).connect(c.destination)
    src.start()
    this.source = src
    this.gain = gain
    this.current = kind
  }

  private curve(v: number) {
    return Math.pow(Math.max(0, Math.min(1, v)), 1.6) * 0.9
  }

  setVolume(v: number) {
    this.volume = v
    if (this.gain && ctx) this.gain.gain.setTargetAtTime(this.curve(v), ctx.currentTime, 0.05)
  }

  stop(fade = 0.5) {
    const src = this.source
    const gain = this.gain
    this.source = null
    this.gain = null
    this.current = null
    if (src && gain && ctx) {
      gain.gain.cancelScheduledValues(ctx.currentTime)
      gain.gain.setValueAtTime(gain.gain.value, ctx.currentTime)
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + fade)
      src.stop(ctx.currentTime + fade + 0.05)
    }
  }

  get playing() {
    return !!this.source
  }
  get vol() {
    return this.volume
  }
}

export const ambient = new AmbientPlayer()

/** A soft bell: a few inharmonic partials with exponential decay. */
export function chime(kind: 'complete' | 'break' | 'soft' = 'complete') {
  try {
    const c = audioCtx()
    const now = c.currentTime
    const notes = kind === 'complete' ? [659.25, 987.77] : kind === 'break' ? [523.25, 783.99] : [880]
    notes.forEach((f, idx) => {
      const t0 = now + idx * 0.18
      const master = c.createGain()
      master.gain.setValueAtTime(0, t0)
      master.gain.linearRampToValueAtTime(0.22, t0 + 0.01)
      master.gain.exponentialRampToValueAtTime(0.0001, t0 + 2.2)
      master.connect(c.destination)
      for (const [mult, amp] of [
        [1, 1],
        [2.01, 0.35],
        [3.02, 0.12],
      ] as const) {
        const o = c.createOscillator()
        o.type = 'sine'
        o.frequency.value = f * mult
        const g = c.createGain()
        g.gain.value = amp
        o.connect(g).connect(master)
        o.start(t0)
        o.stop(t0 + 2.3)
      }
    })
  } catch {
    // Audio unavailable — silently ignore.
  }
}

/** Call from a user gesture so later chimes can play on iOS/Safari. */
export function unlockAudio() {
  try {
    const c = audioCtx()
    const b = c.createBuffer(1, 1, c.sampleRate)
    const s = c.createBufferSource()
    s.buffer = b
    s.connect(c.destination)
    s.start()
  } catch {
    /* ignore */
  }
}

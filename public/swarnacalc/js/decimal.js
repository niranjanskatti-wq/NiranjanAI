// Exact fixed-point decimal arithmetic on BigInt (12 fractional digits).
// Every money/weight value in SwarnaCalc goes through this — never through
// binary floating point — so 0.1 + 0.2 is exactly 0.3 and ₹ totals never drift.

const SCALE_DIGITS = 12;
const SCALE = 10n ** BigInt(SCALE_DIGITS);

function divRoundHalfUp(n, d) {
  // Rounds n / d to the nearest integer, ties away from zero.
  if (d < 0n) { n = -n; d = -d; }
  const q = n / d;
  const r = n % d;
  if (r === 0n) return q;
  const twice = (r < 0n ? -r : r) * 2n;
  if (twice >= d) return n < 0n ? q - 1n : q + 1n;
  return q;
}

export class D {
  constructor(raw) { this.raw = raw; } // raw = value × 10^12

  static from(v) {
    if (v instanceof D) return v;
    if (v === null || v === undefined || v === '') return ZERO;
    if (typeof v === 'bigint') return new D(v * SCALE);
    if (typeof v === 'number') {
      if (!Number.isFinite(v)) return ZERO;
      // Number → shortest round-trip string, then parse exactly.
      return D.parse(String(v)) ?? ZERO;
    }
    return D.parse(String(v)) ?? ZERO;
  }

  // Strict parse; returns null for anything that is not a plain decimal.
  static parse(s) {
    s = String(s).trim().replace(/,/g, '').replace(/[०-९]/g, c => String(c.charCodeAt(0) - 0x0966))
      .replace(/[೦-೯]/g, c => String(c.charCodeAt(0) - 0x0CE6));
    if (s === '' || s === '-' || s === '.') return null;
    const m = /^([+-])?(\d*)(?:\.(\d*))?(?:e([+-]?\d+))?$/i.exec(s);
    if (!m || (m[2] === '' && (m[3] ?? '') === '')) return null;
    const neg = m[1] === '-';
    let intPart = m[2] || '0';
    let frac = m[3] || '';
    let exp = m[4] ? parseInt(m[4], 10) : 0;
    // Apply exponent by shifting the decimal point.
    let digits = intPart + frac;
    let point = intPart.length + exp;
    if (point < 0) { digits = '0'.repeat(-point) + digits; point = 0; }
    if (point > digits.length) { digits = digits + '0'.repeat(point - digits.length); }
    intPart = digits.slice(0, point) || '0';
    frac = digits.slice(point);
    // Round the fraction to SCALE_DIGITS (half up).
    let fracScaled;
    if (frac.length <= SCALE_DIGITS) {
      fracScaled = BigInt((frac + '0'.repeat(SCALE_DIGITS - frac.length)) || '0');
    } else {
      fracScaled = BigInt(frac.slice(0, SCALE_DIGITS));
      if (frac.charCodeAt(SCALE_DIGITS) >= 53 /* '5' */) fracScaled += 1n;
    }
    const raw = BigInt(intPart) * SCALE + fracScaled;
    return new D(neg ? -raw : raw);
  }

  static isValid(s) { return D.parse(s) !== null; }

  add(o) { return new D(this.raw + D.from(o).raw); }
  sub(o) { return new D(this.raw - D.from(o).raw); }
  mul(o) { return new D(divRoundHalfUp(this.raw * D.from(o).raw, SCALE)); }
  div(o) {
    const b = D.from(o).raw;
    if (b === 0n) return ZERO;
    return new D(divRoundHalfUp(this.raw * SCALE, b));
  }
  pct(p) { return this.mul(p).div(100); } // this × p%
  neg() { return new D(-this.raw); }
  abs() { return this.raw < 0n ? this.neg() : this; }

  cmp(o) { const b = D.from(o).raw; return this.raw < b ? -1 : this.raw > b ? 1 : 0; }
  eq(o) { return this.cmp(o) === 0; }
  lt(o) { return this.cmp(o) < 0; }
  lte(o) { return this.cmp(o) <= 0; }
  gt(o) { return this.cmp(o) > 0; }
  gte(o) { return this.cmp(o) >= 0; }
  isZero() { return this.raw === 0n; }
  isNeg() { return this.raw < 0n; }

  static max(a, b) { a = D.from(a); b = D.from(b); return a.gte(b) ? a : b; }
  static min(a, b) { a = D.from(a); b = D.from(b); return a.lte(b) ? a : b; }
  static sum(list) { return list.reduce((acc, v) => acc.add(v), ZERO); }

  // Round to `dp` decimal places. mode: 'half-up' | 'floor' | 'ceil'
  round(dp = 2, mode = 'half-up') {
    const unit = 10n ** BigInt(SCALE_DIGITS - dp);
    let q;
    if (mode === 'floor') {
      q = this.raw / unit;
      if (this.raw < 0n && this.raw % unit !== 0n) q -= 1n;
    } else if (mode === 'ceil') {
      q = this.raw / unit;
      if (this.raw > 0n && this.raw % unit !== 0n) q += 1n;
    } else {
      q = divRoundHalfUp(this.raw, unit);
    }
    return new D(q * unit);
  }

  // Round to a multiple of `step` (e.g. 1 or 10 rupees), half up.
  roundTo(step) {
    const s = D.from(step);
    if (s.isZero()) return this;
    const n = divRoundHalfUp(this.raw, s.raw);
    return new D(n * s.raw);
  }

  // Plain string with exactly `dp` decimals (dp = null → trimmed, full precision).
  toFixed(dp = null) {
    const v = dp === null ? this : this.round(dp);
    const neg = v.raw < 0n;
    const a = neg ? -v.raw : v.raw;
    const int = (a / SCALE).toString();
    let frac = (a % SCALE).toString().padStart(SCALE_DIGITS, '0');
    if (dp === null) frac = frac.replace(/0+$/, '');
    else frac = frac.slice(0, dp);
    const s = frac ? `${int}.${frac}` : int;
    return neg && s !== '0' && !/^0(\.0+)?$/.test(s) ? '-' + s : s;
  }

  toString() { return this.toFixed(null); }
  toNumber() { return Number(this.toFixed(null)); }
  toJSON() { return this.toString(); }
}

export const ZERO = new D(0n);
export const ONE = new D(SCALE);

// Indian digit grouping: 1,25,000.50
export function groupIndian(intStr) {
  if (intStr.length <= 3) return intStr;
  const last3 = intStr.slice(-3);
  let rest = intStr.slice(0, -3);
  const parts = [];
  while (rest.length > 2) { parts.unshift(rest.slice(-2)); rest = rest.slice(0, -2); }
  if (rest) parts.unshift(rest);
  return parts.join(',') + ',' + last3;
}

export function groupIntl(intStr) {
  return intStr.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

// format(value, { dp, style: 'indian'|'intl', symbol })
export function fmt(value, { dp = 2, style = 'indian', symbol = '', trimZeros = false } = {}) {
  const d = D.from(value);
  let s = d.toFixed(dp);
  const neg = s.startsWith('-');
  if (neg) s = s.slice(1);
  let [i, f] = s.split('.');
  if (trimZeros && f) { f = f.replace(/0+$/, ''); }
  i = style === 'intl' ? groupIntl(i) : style === 'none' ? i : groupIndian(i);
  return (neg ? '−' : '') + symbol + i + (f ? '.' + f : '');
}

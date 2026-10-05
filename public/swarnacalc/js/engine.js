// SwarnaCalc calculation engine. Pure functions, no DOM — shared by the app and
// the Node test suite. All arithmetic uses exact decimals (decimal.js).
//
//   Net weight        = Gross − Stone weight
//   Chargeable weight = Net + Wastage (VA)
//   Metal value       = Chargeable × Rate (purity-adjusted)
//   Making            = per gram | % of metal value | flat  (− making discount)
//   Subtotal          = Metal + Making + Stones + Hallmark + Other − Discount
//   GST               = Σ component × component GST %
//   Total             = Subtotal + GST, rounded (none / ₹1 / ₹10)
//   Old gold          = deducted AFTER GST → amount to pay / to receive

import { D, ZERO } from './decimal.js';

const W_DP = 3; // weights: 3 decimals
const M_DP = 2; // money: paise

export function toGrams(value, unit, tolaGrams = '11.664') {
  const v = D.from(value);
  switch (unit) {
    case 'mg': return v.div(1000);
    case 'tola': return v.mul(tolaGrams);
    case 'ct': return v.mul('0.2'); // metric carat (stones)
    default: return v;
  }
}

export function findMetal(cfg, metalId) {
  return cfg.metals.find(m => m.id === metalId) || cfg.metals[0];
}

export function findPurity(cfg, metalId, key) {
  const metal = findMetal(cfg, metalId);
  return metal?.purities.find(p => p.key === key) || null;
}

export function purityPct(cfg, item) {
  if (item.purityKey === 'custom') return D.from(item.customPurity);
  const p = findPurity(cfg, item.metal, item.purityKey);
  return p ? D.from(p.pct) : D.from(item.customPurity);
}

export function purityLabel(cfg, item) {
  if (item.purityKey === 'custom') return `${D.from(item.customPurity).toString()}%`;
  return findPurity(cfg, item.metal, item.purityKey)?.key ?? item.purityKey;
}

const isBlank = v => v === undefined || v === null || String(v).trim() === '';
const bad = v => !isBlank(v) && !D.isValid(v);

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------
export function validateItem(cfg, item) {
  const errors = [];
  const add = (field, key, extra) => errors.push({ field, key, ...extra });
  for (const f of ['gross', 'stoneWt', 'rate', 'wastage', 'making', 'hallmarkFee', 'pieces', 'discountMaking', 'customPurity']) {
    if (bad(item[f])) add(f, 'err.number');
  }
  for (const s of item.stones || []) if (bad(s.amount) || bad(s.weight)) add('stones', 'err.number');
  for (const o of item.others || []) if (bad(o.amount)) add('others', 'err.number');
  if (errors.length) return errors;

  const gross = toGrams(item.gross, item.unit, cfg.tolaGrams);
  const stone = toGrams(item.stoneWt, item.stoneUnit || item.unit, cfg.tolaGrams);
  if (isBlank(item.gross) || !gross.gt(0)) add('gross', 'err.grossRequired');
  if (gross.isNeg()) add('gross', 'err.negative');
  if (stone.isNeg()) add('stoneWt', 'err.negative');
  if (stone.gt(0) && stone.gte(gross)) add('stoneWt', 'err.stoneExceedsGross');
  if (isBlank(item.rate) || !D.from(item.rate).gt(0)) add('rate', 'err.rateRequired');
  const p = purityPct(cfg, item);
  if (!p.gt(0) || p.gt(100)) add('customPurity', 'err.purityRange');
  const w = D.from(item.wastage);
  if (w.isNeg()) add('wastage', 'err.negative');
  if (item.wastageType === 'pct' && w.gt(100)) add('wastage', 'err.pctRange');
  const mk = D.from(item.making);
  if (mk.isNeg()) add('making', 'err.negative');
  if (item.makingType === 'pct' && mk.gt(100)) add('making', 'err.pctRange');
  if (D.from(item.hallmarkFee).isNeg()) add('hallmarkFee', 'err.negative');
  if (D.from(item.pieces).isNeg()) add('pieces', 'err.negative');
  const dm = D.from(item.discountMaking);
  if (dm.isNeg()) add('discountMaking', 'err.negative');
  if (item.discountMakingType === 'pct' && dm.gt(100)) add('discountMaking', 'err.pctRange');
  for (const s of item.stones || []) if (D.from(s.amount).isNeg()) add('stones', 'err.negative');
  return errors;
}

export function validateOldGold(cfg, og) {
  const errors = [];
  for (const f of ['weight', 'purity', 'deduction', 'rate']) {
    if (bad(og[f])) errors.push({ field: f, key: 'err.number' });
  }
  if (errors.length) return errors;
  if (isBlank(og.weight) || !D.from(og.weight).gt(0)) errors.push({ field: 'weight', key: 'err.weightRequired' });
  const p = D.from(og.purity);
  if (!p.gt(0) || p.gt(100)) errors.push({ field: 'purity', key: 'err.purityRange' });
  const d = D.from(og.deduction);
  if (d.isNeg() || d.gte(100)) errors.push({ field: 'deduction', key: 'err.pctRange' });
  if (isBlank(og.rate) || !D.from(og.rate).gt(0)) errors.push({ field: 'rate', key: 'err.rateRequired' });
  return errors;
}

// ---------------------------------------------------------------------------
// One jewellery item (before estimate-level discount & GST)
// ---------------------------------------------------------------------------
export function calcItem(cfg, item) {
  const errors = validateItem(cfg, item);
  const safe = v => (D.isValid(v) ? D.from(v) : ZERO);

  const gross = toGrams(safe(item.gross), item.unit, cfg.tolaGrams).round(W_DP);
  let stoneWt = toGrams(safe(item.stoneWt), item.stoneUnit || item.unit, cfg.tolaGrams).round(W_DP);
  if (stoneWt.gt(gross)) stoneWt = gross;
  const net = D.max(gross.sub(stoneWt), 0);

  const wastageG = item.wastageType === 'g'
    ? safe(item.wastage).round(W_DP)
    : net.pct(safe(item.wastage)).round(W_DP);
  const chargeable = net.add(wastageG);

  const metal = findMetal(cfg, item.metal);
  const pPct = purityPct(cfg, item);
  const enteredRate = safe(item.rate);
  let rate = enteredRate;
  let rateNote = null;
  if (item.rateBasis === 'pure') {
    const ref = D.from(metal?.refPurity || '99.9');
    rate = ref.gt(0) ? enteredRate.mul(pPct).div(ref).round(M_DP) : enteredRate;
    rateNote = { enteredRate, pPct, ref };
  }

  const metalValue = chargeable.mul(rate).round(M_DP);

  let making = ZERO;
  const mk = safe(item.making);
  const makingWeight = item.makingWeightBasis === 'chargeable' ? chargeable : net;
  if (item.makingType === 'perGram') making = makingWeight.mul(mk);
  else if (item.makingType === 'pct') making = metalValue.pct(mk);
  else making = mk;
  making = making.round(M_DP);

  let makingDiscount = ZERO;
  const dm = safe(item.discountMaking);
  if (dm.gt(0)) {
    makingDiscount = item.discountMakingType === 'pct' ? making.pct(dm) : dm;
    makingDiscount = D.min(makingDiscount, making).round(M_DP);
  }
  const makingNet = making.sub(makingDiscount);

  const stones = D.sum((item.stones || []).map(s => safe(s.amount))).round(M_DP);
  const pieces = isBlank(item.pieces) ? D.from(1) : safe(item.pieces);
  const hallmark = safe(item.hallmarkFee).mul(pieces).round(M_DP);
  const others = D.sum((item.others || []).map(o => safe(o.amount))).round(M_DP);

  const subtotal = metalValue.add(makingNet).add(stones).add(hallmark).add(others);

  return {
    id: item.id, errors, valid: errors.length === 0,
    gross, stoneWt, net, wastageG, chargeable, makingWeight,
    purityPct: pPct, purityLabel: purityLabel(cfg, item), metalName: metal?.name ?? item.metal,
    enteredRate, rate, rateNote,
    metalValue, making, makingDiscount, makingNet, stones, hallmark, others, subtotal,
  };
}

// ---------------------------------------------------------------------------
// Old gold
// ---------------------------------------------------------------------------
export function calcOldGold(cfg, og) {
  const errors = validateOldGold(cfg, og);
  const safe = v => (D.isValid(v) ? D.from(v) : ZERO);
  const weight = toGrams(safe(og.weight), og.unit, cfg.tolaGrams).round(W_DP);
  const purity = safe(og.purity);
  const deduction = safe(og.deduction);
  const fine = weight.pct(purity).round(W_DP);
  // Melting loss reduces the weight that is paid for.
  const basisWeight = og.rateBasis === 'asis' ? weight : fine;
  const lossG = basisWeight.pct(deduction).round(W_DP);
  const payableWeight = basisWeight.sub(lossG);
  const value = payableWeight.mul(safe(og.rate)).round(M_DP);
  return { id: og.id, errors, valid: errors.length === 0, weight, purity, fine, deduction, basisWeight, lossG, payableWeight, rate: safe(og.rate), value };
}

// ---------------------------------------------------------------------------
// Whole estimate
// ---------------------------------------------------------------------------
export function roundTotal(value, rule) {
  if (rule === '1') return value.roundTo(1);
  if (rule === '10') return value.roundTo(10);
  return value.round(M_DP);
}

export function calcEstimate(cfg, est) {
  const items = (est.mode === 'sell' ? [] : est.items).map(it => calcItem(cfg, it));
  const comp = {
    metal: D.sum(items.map(r => r.metalValue)),
    making: D.sum(items.map(r => r.makingNet)),
    makingGross: D.sum(items.map(r => r.making)),
    makingDiscount: D.sum(items.map(r => r.makingDiscount)),
    stones: D.sum(items.map(r => r.stones)),
    hallmark: D.sum(items.map(r => r.hallmark)),
    other: D.sum(items.map(r => r.others)),
  };
  const preDiscount = comp.metal.add(comp.making).add(comp.stones).add(comp.hallmark).add(comp.other);

  // Discount on total (before GST). Taxable values shrink proportionally.
  let discount = ZERO;
  const dv = D.isValid(est.discountTotal?.value) ? D.from(est.discountTotal.value) : ZERO;
  if (dv.gt(0) && preDiscount.gt(0)) {
    discount = est.discountTotal.type === 'pct' ? preDiscount.pct(D.min(dv, 100)) : dv;
    discount = D.min(discount, preDiscount).round(M_DP);
  }
  const subtotal = preDiscount.sub(discount);
  const factor = preDiscount.gt(0) ? subtotal.div(preDiscount) : ZERO;

  const g = est.gst || cfg.gst;
  const gstRate = k => (D.isValid(g[k]) ? D.from(g[k]) : ZERO);
  const gstLines = ['metal', 'making', 'hallmark', 'stones', 'other'].map(k => {
    const taxable = comp[k].mul(factor).round(M_DP);
    return { key: k, rate: gstRate(k), taxable, amount: taxable.pct(gstRate(k)).round(M_DP) };
  });
  const gst = D.sum(gstLines.map(l => l.amount));
  const unrounded = subtotal.add(gst);
  const total = items.length ? roundTotal(unrounded, est.rounding) : ZERO;
  const roundOff = total.sub(unrounded);

  const ogEnabled = est.mode === 'sell' || est.mode === 'exchange' || (!!est.oldGold?.enabled && est.mode !== 'reverse');
  const oldGold = ogEnabled ? (est.oldGold?.entries || []).map(o => calcOldGold(cfg, o)) : [];
  const oldValue = D.sum(oldGold.map(o => o.value));

  const payableRaw = total.sub(oldValue);
  const payable = oldGold.length ? roundTotal(payableRaw.abs(), est.rounding) : total;
  const direction = payableRaw.isNeg() ? 'receive' : 'pay';

  const errors = [
    ...items.flatMap((r, i) => r.errors.map(e => ({ ...e, scope: 'item', index: i }))),
    ...oldGold.flatMap((r, i) => r.errors.map(e => ({ ...e, scope: 'old', index: i }))),
  ];
  if (bad(est.discountTotal?.value)) errors.push({ scope: 'est', field: 'discountTotal', key: 'err.number' });

  return {
    items, comp, preDiscount, discount, subtotal, factor, gstLines, gst, unrounded, total, roundOff,
    oldGold, oldValue, payable, direction, hasOldGold: oldGold.length > 0, errors, valid: errors.length === 0,
    totalNetWeight: D.sum(items.map(r => r.net)),
    totalGrossWeight: D.sum(items.map(r => r.gross)),
  };
}

// ---------------------------------------------------------------------------
// Reverse calculation — "My budget is ₹50,000, how many grams can I buy?"
// Solves for the net weight of item[index] such that the payable ≤ budget.
// ---------------------------------------------------------------------------
export function reverseCalc(cfg, est, budget, index = 0) {
  const B = D.from(budget);
  if (!B.gt(0) || !est.items[index]) return null;
  const item = est.items[index];
  const unitG = toGrams(1, item.unit, cfg.tolaGrams);
  const stoneG = toGrams(D.isValid(item.stoneWt) ? item.stoneWt : 0, item.stoneUnit || item.unit, cfg.tolaGrams);

  const evalNet = netG => {
    const grossInUnit = netG.add(stoneG).div(unitG).round(6);
    const items = est.items.map((it, i) => (i === index ? { ...it, gross: grossInUnit.toString() } : it));
    // In budget mode the old-gold section is hidden, so it never counts.
    const r = est.mode === 'reverse'
      ? calcEstimate(cfg, { ...est, mode: 'buy', oldGold: { ...est.oldGold, enabled: false }, items })
      : calcEstimate(cfg, { ...est, items });
    const pay = r.direction === 'receive' ? r.payable.neg() : r.payable;
    return { r, pay, grossInUnit };
  };
  const linear = netG => { const { r } = evalNet(netG); return r.unrounded.sub(r.oldValue); };
  const t0 = linear(ZERO);
  const t1 = linear(D.from(1));
  const perGram = t1.sub(t0);
  if (!perGram.gt(0)) return null;
  if (B.lt(t0)) return { net: ZERO, gross: ZERO, fixedCosts: t0, perGram, result: evalNet(ZERO).r, affordable: false };

  let net = B.sub(t0).div(perGram).round(W_DP, 'floor');
  let probe = evalNet(net);
  let guard = 0;
  while (probe.pay.gt(B) && net.gt(0) && guard++ < 50) { net = net.sub('0.001'); probe = evalNet(net); }
  guard = 0;
  while (guard++ < 50) {
    const next = evalNet(net.add('0.001'));
    if (next.pay.gt(B)) break;
    net = net.add('0.001'); probe = next;
  }
  return { net, gross: net.add(stoneG), grossInUnit: probe.grossInUnit, fixedCosts: t0, perGram, result: probe.r, affordable: true };
}

// ---------------------------------------------------------------------------
// "Is this a fair price?" — offline rule check against the user's own
// thresholds and saved presets.
// ---------------------------------------------------------------------------
export function fairCheck(cfg, item, res) {
  const flags = [];
  if (!res.valid || !res.metalValue.gt(0)) return flags;
  const makingPct = res.making.div(res.metalValue).mul(100).round(2);
  const wastagePct = res.net.gt(0) ? res.wastageG.div(res.net).mul(100).round(2) : ZERO;
  const perGram = res.net.gt(0) ? res.making.div(res.net).round(2) : ZERO;

  const presetMax = (field, type) => {
    const vals = cfg.presets.filter(p => p[field.replace('Max', 'Type')] === type || !type)
      .map(p => D.from(p[field])).filter(v => v.gt(0));
    return vals.length ? vals.reduce((a, b) => D.max(a, b)) : null;
  };
  const effMakingPctLimit = D.from(cfg.fair.makingPctMax || 0);
  const effWastageLimit = D.from(cfg.fair.wastagePctMax || 0);
  const perGramLimit = D.from(cfg.fair.makingPerGramMax || 0);

  const level = (v, limit) => (v.gt(limit.mul('1.5')) ? 'veryHigh' : v.gt(limit) ? 'high' : 'ok');

  if (effMakingPctLimit.gt(0)) {
    flags.push({ kind: 'makingPct', value: makingPct, limit: effMakingPctLimit, level: level(makingPct, effMakingPctLimit) });
  }
  if (perGramLimit.gt(0) && item.makingType === 'perGram') {
    flags.push({ kind: 'makingPerGram', value: perGram, limit: perGramLimit, level: level(perGram, perGramLimit) });
  }
  if (effWastageLimit.gt(0)) {
    flags.push({ kind: 'wastagePct', value: wastagePct, limit: effWastageLimit, level: level(wastagePct, effWastageLimit) });
  }
  const pm = presetMax('wastage', 'pct');
  if (pm && wastagePct.gt(pm)) flags.push({ kind: 'wastageVsPreset', value: wastagePct, limit: pm, level: 'high' });
  return flags;
}

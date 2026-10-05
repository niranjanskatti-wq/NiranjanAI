// SwarnaCalc — app shell, views and interactions (vanilla JS, no build step).
import { D, fmt } from './decimal.js';
import { uid, defaultSettings, mergeSettings, newItem, newOldGold, newEstimate, FIELD_KEYS, SHARE_FIELD_KEYS } from './config.js';
import { calcEstimate, calcItem, reverseCalc, fairCheck, findMetal, purityPct } from './engine.js';
import * as store from './store.js';
import { t as translate, LANGUAGES } from './i18n.js';
import { buildWhatsAppText, shareText, shareFile, renderImageCard, renderPdf, downloadBlob, copyText } from './share.js';
import * as ai from './ai.js';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
const S = {
  cfg: defaultSettings(),
  est: null,
  res: null,
  view: 'calc',
  open: {},          // expanded item cards
  breakdown: false,
  touched: new Set(),
  showErrors: false,
  saved: false,      // current estimate exists in history
  history: [],
  hq: { q: '', from: '', to: '', mode: '' },
  compare: null,
  rateChartKey: '22K',
  busy: '',
};

const $ = (sel, el = document) => el.querySelector(sel);
const $$ = (sel, el = document) => [...el.querySelectorAll(sel)];
const t = (k, v, fallback) => translate(S.cfg.language, k, v, fallback);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = (d, dp = 2) => fmt(d, { dp, style: S.cfg.numberStyle, symbol: S.cfg.currencySymbol });
const wt = d => D.from(d).toFixed(3);
const dateStr = ts => new Date(ts).toLocaleDateString(S.cfg.language === 'en' ? 'en-IN' : `${S.cfg.language}-IN`, { day: '2-digit', month: 'short', year: 'numeric' });
const shareCtx = () => ({ cfg: S.cfg, t, money, wt, dateStr });
const hidden = k => S.cfg.hiddenFields.includes(k);
const totalDp = () => (S.est?.rounding === 'none' ? 2 : 0);

function getPath(obj, path) { return path.split('.').reduce((o, k) => (o == null ? o : o[k]), obj); }
function setPath(obj, path, val) {
  const ks = path.split('.');
  let o = obj;
  for (let i = 0; i < ks.length - 1; i++) { if (o[ks[i]] == null) o[ks[i]] = {}; o = o[ks[i]]; }
  o[ks.at(-1)] = val;
}

function haptic(ms = 8) { if (S.cfg.haptics && navigator.vibrate) try { navigator.vibrate(ms); } catch { /* ignore */ } }

let toastTimer;
function toast(msg, kind = '') {
  const el = $('#toast');
  el.textContent = msg; el.className = `toast show ${kind}`;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.className = 'toast'; }, 2600);
}

// ---------------------------------------------------------------------------
// Modal / dialogs
// ---------------------------------------------------------------------------
function modal(html, { onMount, wide } = {}) {
  const root = $('#modal');
  root.innerHTML = `<div class="sheet ${wide ? 'wide' : ''}" role="dialog" aria-modal="true">${html}</div>`;
  root.classList.add('show');
  const close = () => { root.classList.remove('show'); root.innerHTML = ''; };
  root.onclick = e => { if (e.target === root || e.target.closest('[data-close]')) close(); };
  onMount?.(root.firstElementChild, close);
  return close;
}

function confirmDialog(msg, { ok = t('ok'), danger = false } = {}) {
  return new Promise(resolve => {
    const close = modal(`<p class="dlg-msg">${esc(msg)}</p>
      <div class="row-btns"><button class="btn ghost" data-x="no">${t('cancel')}</button>
      <button class="btn ${danger ? 'danger' : 'gold'}" data-x="yes">${esc(ok)}</button></div>`, {
      onMount: el => el.addEventListener('click', e => {
        const x = e.target.closest('[data-x]')?.dataset.x;
        if (x) { close(); resolve(x === 'yes'); }
      }),
    });
  });
}

function promptDialog(msg, value = '') {
  return new Promise(resolve => {
    const close = modal(`<label class="fld"><span>${esc(msg)}</span><input id="pd-in" value="${esc(value)}"></label>
      <div class="row-btns"><button class="btn ghost" data-x="no">${t('cancel')}</button><button class="btn gold" data-x="yes">${t('ok')}</button></div>`, {
      onMount: el => {
        const inp = $('#pd-in', el); inp.focus(); inp.select();
        el.addEventListener('click', e => {
          const x = e.target.closest('[data-x]')?.dataset.x;
          if (x) { close(); resolve(x === 'yes' ? inp.value.trim() : null); }
        });
        inp.addEventListener('keydown', e => { if (e.key === 'Enter') { close(); resolve(inp.value.trim()); } });
      },
    });
  });
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------
let saveCfgTimer, saveDraftTimer;
function saveSettingsSoon() {
  clearTimeout(saveCfgTimer);
  saveCfgTimer = setTimeout(() => store.kv.set('settings', S.cfg), 300);
}
function saveDraftSoon() {
  clearTimeout(saveDraftTimer);
  saveDraftTimer = setTimeout(() => store.kv.set('draft', { est: S.est, saved: S.saved }), 400);
}

async function logRate(purityKey, rate, source = 'manual') {
  const r = D.from(rate);
  if (!r.gt(0)) return;
  await store.rateLog.put({ id: uid(), at: Date.now(), purityKey, rate: r.toString(), source });
}

async function saveRate(purityKey, rate, source) {
  S.cfg.rates[purityKey] = { rate: D.from(rate).toString(), updatedAt: Date.now() };
  saveSettingsSoon();
  await logRate(purityKey, rate, source);
}

// ---------------------------------------------------------------------------
// Calculation & live updates
// ---------------------------------------------------------------------------
function recompute() {
  S.res = calcEstimate(S.cfg, S.est);
  return S.res;
}

function errFor(path) {
  if (!S.res) return null;
  const [scope, idx, field] = path.split('.');
  const sc = scope === 'items' ? 'item' : scope === 'oldGold' ? 'old' : 'est';
  const index = Number(scope === 'oldGold' ? field : idx);
  const f = scope === 'oldGold' ? path.split('.')[3] : field;
  return S.res.errors.find(e => e.scope === sc && e.index === index && e.field === f)
    || (scope === 'discountTotal' ? S.res.errors.find(e => e.scope === 'est') : null);
}

// Only touch the DOM when the markup really changed, so taps aren't lost.
function setHtml(el, html) {
  if (el._html !== html) { el._html = html; el.innerHTML = html; }
}

function updateLive() {
  recompute();
  const r = S.res;
  // per-item subtotals
  r.items.forEach((ir, i) => {
    const el = $(`[data-live="item-${i}"]`);
    if (el) el.textContent = money(ir.subtotal);
    const nw = $(`[data-live="net-${i}"]`);
    if (nw) nw.textContent = `${t('netWt')} ${wt(ir.net)} g · ${t('chargeable')} ${wt(ir.chargeable)} g`;
    const rt = $(`[data-live="rate-${i}"]`);
    if (rt) rt.textContent = S.est.items[i].rateBasis === 'pure' ? `= ${money(ir.rate)}/g ${t('forPurity', { p: ir.purityLabel })}` : '';
    const fc = $(`[data-live="fair-${i}"]`);
    if (fc) setHtml(fc, fairHtml(S.est.items[i], ir));
  });
  r.oldGold.forEach((o, i) => {
    const el = $(`[data-live="old-${i}"]`);
    if (el) el.textContent = money(o.value);
  });
  // errors
  $$('[data-err]').forEach(el => {
    const p = el.dataset.err;
    const e = errFor(p);
    const show = e && (S.showErrors || S.touched.has(p));
    el.textContent = show ? t(e.key) : '';
    el.previousElementSibling?.classList?.toggle('invalid', !!show);
    el.closest('.fld')?.classList.toggle('has-err', !!show);
  });
  // reverse mode
  if (S.est.mode === 'reverse') { const rv = $('#reverse-out'); if (rv) setHtml(rv, reverseHtml()); }
  // breakdown
  const bd = $('#breakdown');
  if (bd) setHtml(bd, breakdownHtml());
  renderTotalBar();
  saveDraftSoon();
}

// ---------------------------------------------------------------------------
// Rendering helpers
// ---------------------------------------------------------------------------
const opt = (v, label, sel) => `<option value="${esc(v)}" ${String(sel) === String(v) ? 'selected' : ''}>${esc(label)}</option>`;

function inputFld({ path, label, value, type = 'decimal', placeholder = '', suffix = '', rerender = false, cls = '', cfg = false, attrs = '' }) {
  const b = cfg ? `cfg:${path}` : path;
  const im = type === 'decimal' ? 'inputmode="decimal"' : type === 'tel' ? 'inputmode="tel" type="tel"' : type === 'number' ? 'inputmode="numeric"' : '';
  return `<label class="fld ${cls}"><span>${label}</span>
    <div class="in-wrap"><input ${im} ${type === 'password' ? 'type="password" autocomplete="off"' : ''} data-b="${esc(b)}" ${rerender ? 'data-r' : ''} value="${esc(value ?? '')}" placeholder="${esc(placeholder)}" ${attrs}>${suffix ? `<em>${suffix}</em>` : ''}</div>
    ${cfg ? '' : `<small class="err" data-err="${esc(path)}"></small>`}</label>`;
}

function selectFld({ path, label, value, options, rerender = true, cls = '', cfg = false }) {
  const b = cfg ? `cfg:${path}` : path;
  return `<label class="fld ${cls}"><span>${label}</span>
    <select data-b="${esc(b)}" ${rerender ? 'data-r' : ''}>${options.map(([v, l]) => opt(v, l, value)).join('')}</select></label>`;
}

function seg({ path, value, options, cfg = false, small = false }) {
  const b = cfg ? `cfg:${path}` : path;
  return `<div class="seg ${small ? 'sm' : ''}" role="radiogroup">${options.map(([v, l]) =>
    `<button type="button" role="radio" aria-checked="${String(value) === String(v)}" class="${String(value) === String(v) ? 'on' : ''}" data-a="seg" data-b="${esc(b)}" data-v="${esc(v)}">${l}</button>`).join('')}</div>`;
}

function toggle({ path, label, value, cfg = false }) {
  const b = cfg ? `cfg:${path}` : path;
  return `<label class="tgl"><input type="checkbox" data-b="${esc(b)}" data-r ${value ? 'checked' : ''}><i></i><span>${label}</span></label>`;
}

const unitOpts = () => [['g', 'g'], ['mg', 'mg'], ['tola', t('tola')]];
const metalOpts = () => S.cfg.metals.map(m => [m.id, m.name]);
const purityOpts = metalId => [...(findMetal(S.cfg, metalId)?.purities || []).map(p => [p.key, p.label]), ['custom', t('customPct')]];

// ---------------------------------------------------------------------------
// Calculator view
// ---------------------------------------------------------------------------
const MODES = () => [['buy', t('mode.buy')], ['sell', t('mode.sell')], ['exchange', t('mode.exchange')], ['coin', t('mode.coin')], ['reverse', t('mode.reverse')]];

function viewCalc() {
  const e = S.est;
  const r = S.res;
  const aiOn = S.cfg.ai.enabled;
  return `
  <div class="modes">${seg({ path: 'mode', value: e.mode, options: MODES() })}</div>

  ${e.mode !== 'sell' ? `<div class="tools">
    ${S.cfg.presets.map(p => `<button class="chip" data-a="apply-preset" data-id="${p.id}">✦ ${esc(p.name)}</button>`).join('')}
    <button class="chip" data-a="voice" title="${t('voice')}">🎤 ${t('voice')}</button>
    ${aiOn ? `<button class="chip" data-a="scan">📷 ${t('scanBill')}</button>` : ''}
  </div>` : ''}

  ${e.mode === 'reverse' ? `<section class="card glow">
    <h3>${t('budgetTitle')}</h3>
    ${inputFld({ path: 'budget', label: t('budget'), value: e.budget, suffix: S.cfg.currencySymbol, cls: 'big' })}
    <div id="reverse-out">${reverseHtml()}</div>
  </section>` : ''}

  ${hidden('customer') ? '' : `<details class="card" ${e.customer.name || e.customer.phone ? 'open' : ''}>
    <summary>👤 ${t('customerDetails')} <small>${esc(e.customer.name || '')}</small></summary>
    <div class="grid2">
      ${inputFld({ path: 'customer.name', label: t('customerName'), value: e.customer.name, type: 'text' })}
      ${inputFld({ path: 'customer.phone', label: t('phone'), value: e.customer.phone, type: 'tel' })}
    </div>
    ${inputFld({ path: 'jeweller', label: t('jewellerName'), value: e.jeweller, type: 'text' })}
  </details>`}

  ${e.mode !== 'sell' ? `
    <div id="items">${e.items.map((it, i) => itemCard(it, i, r.items[i])).join('')}</div>
    ${e.mode !== 'reverse' ? `<button class="btn add" data-a="add-item">＋ ${t('addItem')}</button>` : ''}
  ` : ''}

  ${oldGoldSection()}

  ${e.mode !== 'sell' ? `<details class="card">
    <summary>⚙️ ${t('billOptions')}</summary>
    ${hidden('discountTotal') ? '' : `<div class="lbl">${t('discountOnTotal')}</div>
    <div class="grid2">
      ${seg({ path: 'discountTotal.type', value: e.discountTotal.type, options: [['pct', '%'], ['amt', S.cfg.currencySymbol]], small: true })}
      ${inputFld({ path: 'discountTotal.value', label: '', value: e.discountTotal.value, placeholder: '0' })}
    </div>`}
    <div class="lbl">${t('gstPerComponent')}</div>
    <div class="grid3">
      ${['metal', 'making', 'hallmark', 'stones', 'other'].map(k => inputFld({ path: `gst.${k}`, label: t(`gst.${k}`), value: e.gst[k], suffix: '%' })).join('')}
    </div>
    ${selectFld({ path: 'rounding', label: t('rounding'), value: e.rounding, options: [['none', t('round.none')], ['1', t('round.1')], ['10', t('round.10')]] })}
    ${hidden('notes') ? '' : `<label class="fld"><span>${t('notes')}</span><textarea data-b="notes" rows="2">${esc(e.notes)}</textarea></label>`}
  </details>` : ''}

  <section class="card breakdown-card">
    <button class="bd-toggle" data-a="toggle-breakdown" aria-expanded="${S.breakdown}">🧮 ${t('stepByStep')} <span>${S.breakdown ? '▲' : '▼'}</span></button>
    <div id="breakdown" ${S.breakdown ? '' : 'hidden'}>${breakdownHtml()}</div>
  </section>

  <p class="disclaimer">${esc(S.cfg.disclaimer)}</p>
  <div class="spacer"></div>`;
}

function itemCard(it, i, r) {
  const open = S.open[it.id] ?? (S.est.items.length === 1);
  const mode = S.est.mode;
  const coin = mode === 'coin';
  const p = `items.${i}`;
  const cs = S.cfg.currencySymbol;
  return `<section class="card item ${open ? 'open' : ''}" data-item="${i}">
    <header class="item-h" data-a="toggle-item" data-id="${it.id}">
      ${it.photo ? `<img class="thumb" src="${it.photo}" alt="">` : `<span class="thumb ph">💍</span>`}
      <div class="item-t"><b>${esc(it.name || `${t('item')} ${i + 1}`)}</b>
        <small>${esc(r.metalName)} · ${esc(r.purityLabel)} · <span data-live="net-${i}">${t('netWt')} ${wt(r.net)} g</span></small></div>
      <strong class="item-amt" data-live="item-${i}">${money(r.subtotal)}</strong>
      <span class="chev">${open ? '▲' : '▼'}</span>
    </header>
    ${open ? `<div class="item-b">
      <div class="row-name">
        ${inputFld({ path: `${p}.name`, label: t('jewelleryName'), value: it.name, type: 'text', placeholder: t('namePlaceholder'), cls: 'grow' })}
        ${hidden('photo') ? '' : `<label class="photo-btn" title="${t('photo')}">${it.photo ? `<img src="${it.photo}" alt="">` : '📷'}<input type="file" accept="image/*" data-a="photo" data-i="${i}" hidden></label>`}
      </div>
      ${it.photo ? `<button class="link" data-a="remove-photo" data-i="${i}">${t('removePhoto')}</button>` : ''}
      <div class="grid2">
        ${hidden('category') ? '' : selectFld({ path: `${p}.category`, label: t('category'), value: it.category, options: S.cfg.categories.map(c => [c, t(`cat.${c}`, null, c)]) })}
        ${selectFld({ path: `${p}.metal`, label: t('metal'), value: it.metal, options: metalOpts() })}
      </div>
      <div class="grid2">
        ${selectFld({ path: `${p}.purityKey`, label: t('purity'), value: it.purityKey, options: purityOpts(it.metal) })}
        ${it.purityKey === 'custom' ? inputFld({ path: `${p}.customPurity`, label: t('purityPct'), value: it.customPurity, suffix: '%' }) : `<div class="fld"><span>${t('purityPct')}</span><div class="ro">${purityPct(S.cfg, it).toString()}%</div></div>`}
      </div>

      <div class="lbl">${t('ratePerGram')}</div>
      ${seg({ path: `${p}.rateBasis`, value: it.rateBasis, options: [['purity', t('rateForSelected')], ['pure', t('rateFor24k')]], small: true })}
      <div class="row-rate">
        ${inputFld({ path: `${p}.rate`, label: '', value: it.rate, suffix: `${cs}/g`, cls: 'grow big' })}
        <button class="btn sm ghost" data-a="save-rate" data-i="${i}" title="${t('saveRate')}">💾</button>
      </div>
      <small class="hint" data-live="rate-${i}">${it.rateBasis === 'pure' ? `= ${money(r.rate)}/g ${t('forPurity', { p: r.purityLabel })}` : ''}</small>

      <div class="grid2">
        ${inputFld({ path: `${p}.gross`, label: t('grossWt'), value: it.gross, cls: 'big', placeholder: '0.000' })}
        ${selectFld({ path: `${p}.unit`, label: t('unit'), value: it.unit, options: unitOpts() })}
      </div>
      ${hidden('stoneWt') || coin ? '' : `<div class="grid2">
        ${inputFld({ path: `${p}.stoneWt`, label: t('stoneWt'), value: it.stoneWt, placeholder: '0.000' })}
        ${selectFld({ path: `${p}.stoneUnit`, label: t('unit'), value: it.stoneUnit || it.unit, options: [...unitOpts(), ['ct', t('carat')]] })}
      </div>`}

      ${hidden('wastage') || coin ? '' : `<div class="lbl">${t('wastageVA')}</div>
      <div class="grid2">
        ${seg({ path: `${p}.wastageType`, value: it.wastageType, options: [['pct', t('pctOfNet')], ['g', t('fixedGrams')]], small: true })}
        ${inputFld({ path: `${p}.wastage`, label: '', value: it.wastage, suffix: it.wastageType === 'pct' ? '%' : 'g' })}
      </div>`}

      ${hidden('making') ? '' : `<div class="lbl">${t('makingCharges')}</div>
      ${seg({ path: `${p}.makingType`, value: it.makingType, options: [['perGram', t('perGram')], ['pct', t('pctOfMetal')], ['flat', t('flat')]], small: true })}
      <div class="grid2">
        ${inputFld({ path: `${p}.making`, label: '', value: it.making, suffix: it.makingType === 'pct' ? '%' : it.makingType === 'perGram' ? `${cs}/g` : cs })}
        ${it.makingType === 'perGram' ? selectFld({ path: `${p}.makingWeightBasis`, label: t('onWeight'), value: it.makingWeightBasis, options: [['net', t('netWt')], ['chargeable', t('chargeable')]] }) : '<div></div>'}
      </div>`}

      ${hidden('discountMaking') ? '' : `<div class="lbl">${t('makingDiscount')}</div>
      <div class="grid2">
        ${seg({ path: `${p}.discountMakingType`, value: it.discountMakingType, options: [['pct', '%'], ['amt', cs]], small: true })}
        ${inputFld({ path: `${p}.discountMaking`, label: '', value: it.discountMaking, placeholder: '0' })}
      </div>`}

      ${hidden('stones') || coin ? '' : listEditor(`${p}.stones`, it.stones, t('stoneCharges'), t('stoneLabel'), '💎')}

      ${hidden('hallmark') ? '' : `<div class="grid2">
        ${inputFld({ path: `${p}.hallmarkFee`, label: t('hallmarkFee'), value: it.hallmarkFee, suffix: cs })}
        ${inputFld({ path: `${p}.pieces`, label: t('pieces'), value: it.pieces, type: 'number' })}
      </div>`}

      ${hidden('others') ? '' : listEditor(`${p}.others`, it.others, t('otherCharges'), t('chargeLabel'), '➕')}

      <div class="fair" data-live="fair-${i}">${fairHtml(it, r)}</div>

      <div class="item-actions">
        <button class="btn sm ghost" data-a="save-preset" data-i="${i}">✦ ${t('saveAsPreset')}</button>
        <button class="btn sm ghost" data-a="dup-item" data-i="${i}">⧉ ${t('duplicate')}</button>
        ${S.est.items.length > 1 ? `<button class="btn sm danger-ghost" data-a="del-item" data-i="${i}">🗑 ${t('delete')}</button>` : ''}
      </div>
    </div>` : ''}
  </section>`;
}

function listEditor(path, list, title, labelPh, icon) {
  return `<div class="lbl">${icon} ${title}</div>
    <div class="list-ed">
      ${(list || []).map((s, j) => `<div class="li">
        <input data-b="${path}.${j}.label" value="${esc(s.label)}" placeholder="${esc(labelPh)}" class="li-label">
        <div class="in-wrap"><input inputmode="decimal" data-b="${path}.${j}.amount" value="${esc(s.amount)}" placeholder="0"><em>${S.cfg.currencySymbol}</em></div>
        <button class="x" data-a="list-del" data-path="${path}" data-j="${j}" aria-label="${t('delete')}">✕</button>
      </div>`).join('')}
      <button class="link" data-a="list-add" data-path="${path}">＋ ${t('add')}</button>
      <small class="err" data-err="${path.replace(/\.(stones|others)$/, '.$1')}"></small>
    </div>`;
}

function fairHtml(it, r) {
  if (!r?.valid) return '';
  const flags = fairCheck(S.cfg, it, r);
  const worst = flags.find(f => f.level === 'veryHigh') || flags.find(f => f.level === 'high');
  if (!worst) return flags.length ? `<span class="badge ok">✓ ${t('fair.ok')}</span>` : '';
  const msgs = flags.filter(f => f.level !== 'ok').map(f => t(`fair.${f.kind}`, { v: f.value.toFixed(1), l: f.limit.toString() }));
  return `<span class="badge ${worst.level === 'veryHigh' ? 'bad' : 'warn'}">⚠ ${t(`fair.${worst.level}`)}</span> <small>${msgs.map(esc).join(' · ')}</small>`;
}

function oldGoldSection() {
  const e = S.est;
  const forced = e.mode === 'exchange' || e.mode === 'sell';
  if (e.mode === 'reverse') return '';
  const on = forced || e.oldGold.enabled;
  const cs = S.cfg.currencySymbol;
  return `<section class="card old ${on ? 'on' : ''}">
    <div class="old-h">
      <h3>♻️ ${e.mode === 'sell' ? t('sellOldGold') : t('oldGoldExchange')}</h3>
      ${forced ? '' : toggle({ path: 'oldGold.enabled', label: '', value: e.oldGold.enabled })}
    </div>
    ${on ? `${e.oldGold.entries.map((o, j) => {
      const p = `oldGold.entries.${j}`;
      const r = S.res.oldGold[j];
      return `<div class="old-entry">
        <div class="old-row1">
          <input class="li-label" data-b="${p}.label" value="${esc(o.label)}" placeholder="${t('oldGold')}">
          <strong data-live="old-${j}">${r ? money(r.value) : ''}</strong>
          ${e.oldGold.entries.length > 1 || e.mode !== 'sell' ? `<button class="x" data-a="old-del" data-j="${j}">✕</button>` : ''}
        </div>
        <div class="grid2">
          ${inputFld({ path: `${p}.weight`, label: t('weight'), value: o.weight, placeholder: '0.000' })}
          ${selectFld({ path: `${p}.unit`, label: t('unit'), value: o.unit, options: unitOpts() })}
          ${inputFld({ path: `${p}.purity`, label: t('testedPurity'), value: o.purity, suffix: '%' })}
          ${inputFld({ path: `${p}.deduction`, label: t('meltingLoss'), value: o.deduction, suffix: '%' })}
        </div>
        ${seg({ path: `${p}.rateBasis`, value: o.rateBasis, options: [['fine', t('ratePerFine')], ['asis', t('ratePerAsIs')]], small: true })}
        ${inputFld({ path: `${p}.rate`, label: t('buybackRate'), value: o.rate, suffix: `${cs}/g` })}
      </div>`;
    }).join('')}
    <button class="link" data-a="old-add">＋ ${t('addOldGold')}</button>` : `<small class="hint">${t('oldGoldHint')}</small>`}
  </section>`;
}

function reverseHtml() {
  const e = S.est;
  if (!D.isValid(e.budget) || !D.from(e.budget).gt(0)) return `<small class="hint">${t('budgetHint')}</small>`;
  const rv = reverseCalc(S.cfg, e, e.budget, 0);
  if (!rv) return `<small class="hint">${t('budgetNeedRate')}</small>`;
  if (!rv.affordable) return `<div class="rev bad">${t('budgetTooLow', { v: money(rv.fixedCosts) })}</div>`;
  const it = S.res.items[0];
  return `<div class="rev">
    <div class="rev-big">${wt(rv.net)} <small>g ${t('netWt')}</small></div>
    <div>${t('ofPurity', { p: esc(it.purityLabel) })} · ${t('grossWt')} ${wt(rv.gross)} g</div>
    <small class="hint">${t('perGramAllIn')}: ${money(rv.perGram)} · ${t('fixedCosts')}: ${money(rv.fixedCosts)}</small>
    <div class="rev-total">${t('total')}: <b>${money(rv.result.payable, totalDp())}</b></div>
    <button class="btn gold sm" data-a="use-reverse" data-g="${rv.grossInUnit}">${t('useThisWeight')}</button>
  </div>`;
}

function breakdownHtml() {
  const r = S.res; const e = S.est; const cs = S.cfg.currencySymbol;
  const L = [];
  r.items.forEach((ir, i) => {
    const it = e.items[i];
    const st = [];
    st.push([t('bd.net'), `${wt(ir.gross)} − ${wt(ir.stoneWt)}`, `${wt(ir.net)} g`]);
    if (it.wastageType === 'pct') st.push([t('bd.wastage'), `${D.from(it.wastage || 0).toString()}% × ${wt(ir.net)}`, `${wt(ir.wastageG)} g`]);
    else st.push([t('bd.wastage'), t('fixedGrams'), `${wt(ir.wastageG)} g`]);
    st.push([t('bd.chargeable'), `${wt(ir.net)} + ${wt(ir.wastageG)}`, `${wt(ir.chargeable)} g`]);
    if (ir.rateNote) st.push([t('bd.rate'), `${money(ir.rateNote.enteredRate)} × ${ir.rateNote.pPct.toString()} ÷ ${ir.rateNote.ref.toString()}`, `${money(ir.rate)}/g`]);
    else st.push([t('bd.rate'), ir.purityLabel, `${money(ir.rate)}/g`]);
    st.push([t('bd.metal'), `${wt(ir.chargeable)} g × ${money(ir.rate)}`, money(ir.metalValue)]);
    const mk = D.from(D.isValid(it.making) ? it.making : 0);
    const mkExpr = it.makingType === 'perGram' ? `${wt(ir.makingWeight)} g × ${cs}${mk.toString()}` : it.makingType === 'pct' ? `${mk.toString()}% × ${money(ir.metalValue)}` : t('flat');
    st.push([t('bd.making'), mkExpr, money(ir.making)]);
    if (ir.makingDiscount.gt(0)) st.push([t('makingDiscount'), '', `−${money(ir.makingDiscount)}`]);
    if (ir.stones.gt(0)) st.push([t('stones'), (it.stones || []).map(s => s.label || '•').join(', '), money(ir.stones)]);
    if (ir.hallmark.gt(0)) st.push([t('hallmark'), `${cs}${D.from(it.hallmarkFee || 0).toString()} × ${D.from(it.pieces || 1).toString()}`, money(ir.hallmark)]);
    if (ir.others.gt(0)) st.push([t('otherCharges'), (it.others || []).map(s => s.label || '•').join(', '), money(ir.others)]);
    L.push(`<div class="bd-item"><h4>${esc(it.name || `${t('item')} ${i + 1}`)} <small>${esc(ir.purityLabel)}</small></h4>
      <ol>${st.map(([a, b, c]) => `<li><span>${a}</span><em>${esc(b)}</em><b>${c}</b></li>`).join('')}</ol>
      <div class="bd-sub"><span>${t('itemTotal')}</span><b>${money(ir.subtotal)}</b></div></div>`);
  });
  if (r.items.length) {
    const g = [];
    g.push([t('subtotal'), t('bd.subtotalExpr'), money(r.preDiscount)]);
    if (r.discount.gt(0)) g.push([t('discount'), e.discountTotal.type === 'pct' ? `${D.from(e.discountTotal.value).toString()}%` : '', `−${money(r.discount)}`]);
    for (const l of r.gstLines) if (l.rate.gt(0) || l.amount.gt(0)) g.push([`GST · ${t(`gst.${l.key}`)}`, `${l.rate.toString()}% × ${money(l.taxable)}`, money(l.amount)]);
    g.push([t('bd.beforeRound'), '', money(r.unrounded)]);
    if (!r.roundOff.isZero()) g.push([t('roundOff'), t(`round.${e.rounding}`), money(r.roundOff)]);
    L.push(`<div class="bd-item"><h4>${t('billTotal')}</h4><ol>${g.map(([a, b, c]) => `<li><span>${a}</span><em>${esc(b)}</em><b>${c}</b></li>`).join('')}</ol>
      <div class="bd-sub grand"><span>${t('total')}</span><b>${money(r.total, totalDp())}</b></div></div>`);
  }
  if (r.hasOldGold) {
    const g = r.oldGold.map((o, j) => {
      const og = e.oldGold.entries[j];
      return `<li><span>${esc(og.label || t('oldGold'))}</span><em>${og.rateBasis === 'fine' ? `${wt(o.weight)} g × ${o.purity.toString()}% = ${wt(o.fine)} g; ` : ''}−${o.deduction.toString()}% (${wt(o.lossG)} g) → ${wt(o.payableWeight)} g × ${money(o.rate)}</em><b>−${money(o.value)}</b></li>`;
    });
    L.push(`<div class="bd-item"><h4>♻️ ${t('oldGold')}</h4><ol>${g.join('')}</ol>
      <div class="bd-sub grand"><span>${r.direction === 'receive' ? t('amountToReceive') : t('amountToPay')}</span><b>${money(r.payable, totalDp())}</b></div></div>`);
  }
  return L.join('') || `<small class="hint">${t('enterValues')}</small>`;
}

function renderTotalBar() {
  const bar = $('#totalbar');
  if (S.view !== 'calc') { bar.hidden = true; return; }
  bar.hidden = false;
  const r = S.res;
  const label = r.hasOldGold ? (r.direction === 'receive' ? t('amountToReceive') : t('amountToPay')) : t('total');
  const amt = r.hasOldGold ? r.payable : r.total;
  const sub = r.items.length ? `${t('gstShort')} ${money(r.gst, 0)} · ${wt(r.totalNetWeight)} g` : '';
  // Build the buttons once and only update text afterwards, so a tap that
  // blurs an input (which triggers a live update) is never lost.
  if (bar.dataset.lang !== S.cfg.language) {
    bar.dataset.lang = S.cfg.language;
    bar.innerHTML = `
    <button class="tb-main" data-a="toggle-breakdown" aria-label="${t('stepByStep')}">
      <small><span class="tb-label"></span> <span class="warn-dot" title="${t('checkInputs')}">⚠</span></small>
      <strong class="tb-amt"></strong>
      <small class="tb-sub"></small>
    </button>
    <div class="tb-acts">
      <button class="btn ghost sq" data-a="save" aria-label="${t('save')}">💾<small>${t('save')}</small></button>
      <button class="btn wa sq" data-a="share-wa" aria-label="WhatsApp">${WA_ICON}<small>WhatsApp</small></button>
      <button class="btn gold sq" data-a="share-menu" aria-label="${t('share')}">⤴<small>${t('share')}</small></button>
    </div>`;
  }
  $('.tb-label', bar).textContent = label;
  $('.warn-dot', bar).hidden = r.valid;
  $('.tb-amt', bar).textContent = money(amt, totalDp());
  $('.tb-sub', bar).textContent = sub;
}

const WA_ICON = '<svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path fill="currentColor" d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2Zm0 18.2a8.2 8.2 0 0 1-4.2-1.2l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2Zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8s-.4-.1-.6.1-.7.8-.8 1-.3.2-.5.1a6.7 6.7 0 0 1-3.3-2.9c-.3-.4.3-.4.7-1.3a.5.5 0 0 0 0-.4l-.8-1.9c-.2-.5-.4-.4-.6-.4h-.5a1 1 0 0 0-.7.3 3 3 0 0 0-.9 2.2 5.2 5.2 0 0 0 1.1 2.7 11.8 11.8 0 0 0 4.5 4c1.7.7 2.3.8 3.2.6a2.7 2.7 0 0 0 1.8-1.2 2.2 2.2 0 0 0 .1-1.3c0-.1-.2-.2-.4-.3Z"/></svg>';

// ---------------------------------------------------------------------------
// History view
// ---------------------------------------------------------------------------
function estTitle(e) {
  const names = (e.items || []).map(i => i.name || i.category).filter(Boolean);
  if (e.mode === 'sell') return t('mode.sell');
  return names.length ? names.join(', ') : t('estimate');
}

function viewHistory() {
  const q = S.hq;
  const ql = q.q.trim().toLowerCase();
  const from = q.from ? new Date(q.from).getTime() : 0;
  const to = q.to ? new Date(q.to).getTime() + 86400000 : Infinity;
  const list = S.history
    .filter(e => (!ql || [estTitle(e), e.customer?.name, e.customer?.phone, e.jeweller, e.notes].join(' ').toLowerCase().includes(ql)))
    .filter(e => e.updatedAt >= from && e.updatedAt < to)
    .filter(e => !q.mode || e.mode === q.mode)
    .sort((a, b) => b.updatedAt - a.updatedAt);
  return `<h2 class="vh">${t('history')}</h2>
  <div class="card filters">
    <input type="search" id="hq" placeholder="🔍 ${t('searchHint')}" value="${esc(q.q)}">
    <div class="grid3">
      <label class="fld"><span>${t('from')}</span><input type="date" id="hfrom" value="${esc(q.from)}"></label>
      <label class="fld"><span>${t('to')}</span><input type="date" id="hto" value="${esc(q.to)}"></label>
      <label class="fld"><span>${t('mode')}</span><select id="hmode">${opt('', t('all'), q.mode)}${MODES().map(([v, l]) => opt(v, l, q.mode)).join('')}</select></label>
    </div>
  </div>
  ${list.length ? list.map(e => {
    const s = e.summary || {};
    return `<article class="card hist">
      <div class="hist-top" data-a="h-open" data-id="${e.id}">
        <div><b>${esc(estTitle(e))}</b>
        <small>${dateStr(e.updatedAt)} · ${t(`mode.${e.mode}`)}${e.customer?.name ? ` · 👤 ${esc(e.customer.name)}` : ''}${e.jeweller ? ` · 🏪 ${esc(e.jeweller)}` : ''}</small></div>
        <strong>${s.amount ? money(s.amount, 0) : ''}${s.direction === 'receive' ? ` <small>${t('receive')}</small>` : ''}</strong>
      </div>
      <div class="hist-acts">
        <button class="btn sm ghost" data-a="h-open" data-id="${e.id}">✎ ${t('edit')}</button>
        <button class="btn sm ghost" data-a="h-dup" data-id="${e.id}">⧉ ${t('duplicate')}</button>
        <button class="btn sm ghost" data-a="h-wa" data-id="${e.id}">${WA_ICON}</button>
        <button class="btn sm danger-ghost" data-a="h-del" data-id="${e.id}">🗑</button>
      </div>
    </article>`;
  }).join('') : `<div class="empty">📜<p>${t('noHistory')}</p></div>`}
  <div class="spacer"></div>`;
}

// ---------------------------------------------------------------------------
// Compare view — up to 3 jewellers' quotes side by side
// ---------------------------------------------------------------------------
function newQuote(n) {
  const d = S.cfg.defaults;
  return { id: uid(), jeweller: `${t('jeweller')} ${n}`, rate: S.cfg.rates[S.compare?.base?.purityKey || d.purityKey]?.rate ?? '', wastageType: 'pct', wastage: d.wastage, makingType: d.makingType, making: d.making, stones: '', hallmarkFee: d.hallmarkFee, other: '' };
}

function ensureCompare() {
  if (S.compare) return;
  const d = S.cfg.defaults;
  S.compare = { base: { metal: d.metal, purityKey: d.purityKey, unit: S.cfg.weightUnit, gross: '', stoneWt: '' }, quotes: [] };
  S.compare.quotes = [newQuote(1), newQuote(2)];
}

function compareResults() {
  const b = S.compare.base;
  return S.compare.quotes.map(q => {
    const item = newItem(S.cfg, {
      metal: b.metal, purityKey: b.purityKey, unit: b.unit, stoneUnit: b.unit, gross: b.gross, stoneWt: b.stoneWt, rate: q.rate, rateBasis: 'purity',
      wastageType: q.wastageType, wastage: q.wastage, makingType: q.makingType, making: q.making, hallmarkFee: q.hallmarkFee,
      stones: q.stones ? [{ label: t('stones'), amount: q.stones }] : [], others: q.other ? [{ label: t('other'), amount: q.other }] : [],
    });
    const est = { ...newEstimate(S.cfg, 'buy'), items: [item], rounding: S.cfg.rounding };
    return { q, item, est, r: calcEstimate(S.cfg, est) };
  });
}

function viewCompare() {
  ensureCompare();
  const b = S.compare.base;
  const res = compareResults();
  const valid = res.filter(x => x.r.valid);
  const cheapest = valid.length > 1 ? valid.reduce((a, c) => (c.r.total.lt(a.r.total) ? c : a)) : null;
  const rows = viewCompareRows();
  const cs = S.cfg.currencySymbol;
  return `<h2 class="vh">${t('compareQuotes')}</h2>
  <section class="card">
    <div class="grid2">
      ${selectFld({ path: 'base.metal', label: t('metal'), value: b.metal, options: metalOpts(), cls: 'cmp' }).replace(/data-b="/g, 'data-b="cmp:')}
      ${selectFld({ path: 'base.purityKey', label: t('purity'), value: b.purityKey, options: purityOpts(b.metal).filter(([k]) => k !== 'custom') }).replace(/data-b="/g, 'data-b="cmp:')}
      ${inputFld({ path: 'base.gross', label: t('grossWt'), value: b.gross, placeholder: '0.000' }).replace(/data-b="/g, 'data-b="cmp:')}
      ${inputFld({ path: 'base.stoneWt', label: t('stoneWt'), value: b.stoneWt, placeholder: '0.000' }).replace(/data-b="/g, 'data-b="cmp:')}
    </div>
  </section>
  <section class="card cmp-table" id="cmp-table">${compareTable(res, rows, cheapest)}</section>
  <div class="cmp-quotes">
  ${S.compare.quotes.map((q, i) => `<section class="card quote">
    <div class="old-row1"><input class="li-label" data-b="cmp:quotes.${i}.jeweller" value="${esc(q.jeweller)}">
      ${S.compare.quotes.length > 1 ? `<button class="x" data-a="cmp-del" data-j="${i}">✕</button>` : ''}</div>
    ${[
      inputFld({ path: `quotes.${i}.rate`, label: t('ratePerGram'), value: q.rate, suffix: `${cs}/g` }),
      `<div class="fld"><span>${t('wastageVA')}</span>${seg({ path: `quotes.${i}.wastageType`, value: q.wastageType, options: [['pct', '%'], ['g', 'g']], small: true })}</div>`,
      inputFld({ path: `quotes.${i}.wastage`, label: '', value: q.wastage, suffix: q.wastageType === 'pct' ? '%' : 'g' }),
      `<div class="fld"><span>${t('makingCharges')}</span>${seg({ path: `quotes.${i}.makingType`, value: q.makingType, options: [['perGram', '/g'], ['pct', '%'], ['flat', cs]], small: true })}</div>`,
      inputFld({ path: `quotes.${i}.making`, label: '', value: q.making }),
      inputFld({ path: `quotes.${i}.stones`, label: t('stoneCharges'), value: q.stones, suffix: cs }),
      inputFld({ path: `quotes.${i}.hallmarkFee`, label: t('hallmarkFee'), value: q.hallmarkFee, suffix: cs }),
      inputFld({ path: `quotes.${i}.other`, label: t('otherCharges'), value: q.other, suffix: cs }),
    ].join('').replace(/data-b="/g, 'data-b="cmp:')}
    <button class="btn sm ghost" data-a="cmp-open" data-j="${i}">→ ${t('openInCalc')}</button>
  </section>`).join('')}
  </div>
  ${S.compare.quotes.length < 3 ? `<button class="btn add" data-a="cmp-add">＋ ${t('addQuote')}</button>` : ''}
  <p class="disclaimer">${esc(S.cfg.disclaimer)}</p>
  <div class="spacer"></div>`;
}

function compareTable(res, rows, cheapest) {
  return `<div class="cmp-grid" style="--n:${res.length}">
    <div class="cg-h"></div>${res.map(x => `<div class="cg-h ${x === cheapest ? 'best' : ''}">${x === cheapest ? '👑 ' : ''}${esc(x.q.jeweller)}</div>`).join('')}
    ${rows.map(([label, f]) => `<div class="cg-l">${label}</div>${res.map(x => `<div class="cg-v ${x === cheapest ? 'best' : ''}">${x.r.valid ? f(x) : '—'}</div>`).join('')}`).join('')}
    <div class="cg-l tot">${t('total')}</div>${res.map(x => `<div class="cg-v tot ${x === cheapest ? 'best' : ''}">${x.r.valid ? money(x.r.total, 0) : '—'}</div>`).join('')}
  </div>
  ${cheapest ? `<p class="cmp-note">👑 ${t('cheapestIs', { j: esc(cheapest.q.jeweller), v: money(res.filter(x => x.r.valid).map(x => x.r.total).reduce((a, c) => D.max(a, c)).sub(cheapest.r.total), 0) })}</p>` : `<p class="hint">${t('compareHint')}</p>`}`;
}

// ---------------------------------------------------------------------------
// Rates view — today's rates, live fetch, rate log chart
// ---------------------------------------------------------------------------
let rateLogCache = [];

function viewRates() {
  const cs = S.cfg.currencySymbol;
  const lr = S.cfg.liveRate;
  return `<h2 class="vh">${t('ratesTitle')}</h2>
  ${S.cfg.metals.map(m => `<section class="card">
    <h3>${esc(m.name)}</h3>
    ${m.purities.map(p => {
      const r = S.cfg.rates[p.key];
      return `<div class="rate-row">
        <div><b>${esc(p.label)}</b><small>${r?.updatedAt ? `${t('updated')} ${dateStr(r.updatedAt)}` : t('notSet')}</small></div>
        <div class="in-wrap"><input inputmode="decimal" data-rate="${esc(p.key)}" value="${esc(r?.rate ?? '')}" placeholder="0"><em>${cs}/g</em></div>
      </div>`;
    }).join('')}
    <button class="link" data-a="derive-rates" data-m="${esc(m.id)}">⚖ ${t('deriveFrom24')}</button>
  </section>`).join('')}
  <div class="row-btns">
    <button class="btn gold" data-a="save-rates">💾 ${t('saveRates')}</button>
    ${lr.url ? `<button class="btn ghost" data-a="live-rate">🌐 ${t('fetchLive')}</button>` : ''}
  </div>
  <section class="card">
    <h3>📈 ${t('rateLog')}</h3>
    <select id="rate-chart-key">${S.cfg.metals.flatMap(m => m.purities).map(p => opt(p.key, p.label, S.rateChartKey)).join('')}</select>
    <div id="rate-chart">${rateChartHtml()}</div>
  </section>
  <div class="spacer"></div>`;
}

function rateChartHtml() {
  const pts = rateLogCache.filter(r => r.purityKey === S.rateChartKey).sort((a, b) => a.at - b.at);
  if (!pts.length) return `<p class="hint">${t('noRateLog')}</p>`;
  const W = 340, H = 180, P = { l: 52, r: 12, t: 14, b: 26 };
  const vals = pts.map(p => Number(p.rate));
  let lo = Math.min(...vals), hi = Math.max(...vals);
  if (lo === hi) { lo *= 0.98; hi *= 1.02; }
  const pad = (hi - lo) * 0.1; lo -= pad; hi += pad;
  const t0 = pts[0].at, t1 = pts.at(-1).at;
  const x = at => P.l + (t1 === t0 ? (W - P.l - P.r) / 2 : ((at - t0) / (t1 - t0)) * (W - P.l - P.r));
  const y = v => P.t + (1 - (v - lo) / (hi - lo)) * (H - P.t - P.b);
  const path = pts.map((p, i) => `${i ? 'L' : 'M'}${x(p.at).toFixed(1)},${y(Number(p.rate)).toFixed(1)}`).join('');
  const ticks = [lo + pad, (lo + hi) / 2, hi - pad];
  const short = v => fmt(String(Math.round(v)), { dp: 0, style: S.cfg.numberStyle });
  const svg = `<svg viewBox="0 0 ${W} ${H}" class="chart" role="img" aria-label="${t('rateLog')} ${esc(S.rateChartKey)}">
    ${ticks.map(v => `<line x1="${P.l}" x2="${W - P.r}" y1="${y(v)}" y2="${y(v)}" class="grid"/><text x="${P.l - 6}" y="${y(v) + 4}" class="ax" text-anchor="end">${short(v)}</text>`).join('')}
    <text x="${P.l}" y="${H - 6}" class="ax">${dateStr(t0)}</text>
    ${t1 !== t0 ? `<text x="${W - P.r}" y="${H - 6}" class="ax" text-anchor="end">${dateStr(t1)}</text>` : ''}
    <path d="${path}" class="line"/>
    ${pts.map((p, i) => `<circle cx="${x(p.at)}" cy="${y(Number(p.rate))}" r="4" class="dot" data-i="${i}"/>`).join('')}
    <line class="xhair" y1="${P.t}" y2="${H - P.b}" x1="0" x2="0" visibility="hidden"/>
    <rect x="${P.l}" y="0" width="${W - P.l - P.r}" height="${H}" fill="transparent" class="hit"/>
  </svg><div class="tip" hidden></div>`;
  const table = `<details><summary>${t('table')} (${pts.length})</summary><table class="tbl">${[...pts].reverse().map(p =>
    `<tr><td>${dateStr(p.at)} ${new Date(p.at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</td><td>${money(p.rate, 0)}</td><td><small>${esc(p.source || '')}</small></td><td><button class="x" data-a="rl-del" data-id="${p.id}">✕</button></td></tr>`).join('')}</table></details>`;
  setTimeout(() => wireChart(pts, x, y), 0);
  return svg + table;
}

function wireChart(pts, x, y) {
  const box = $('#rate-chart'); if (!box) return;
  const svg = $('svg', box), tip = $('.tip', box), xh = $('.xhair', box), hit = $('.hit', box);
  if (!svg || !hit) return;
  const move = ev => {
    const pt = svg.createSVGPoint();
    const e = ev.touches ? ev.touches[0] : ev;
    pt.x = e.clientX; pt.y = e.clientY;
    const loc = pt.matrixTransform(svg.getScreenCTM().inverse());
    let best = 0, bd = Infinity;
    pts.forEach((p, i) => { const d = Math.abs(x(p.at) - loc.x); if (d < bd) { bd = d; best = i; } });
    const p = pts[best];
    xh.setAttribute('x1', x(p.at)); xh.setAttribute('x2', x(p.at)); xh.setAttribute('visibility', 'visible');
    $$('.dot', svg).forEach((d, i) => d.classList.toggle('on', i === best));
    tip.hidden = false;
    tip.innerHTML = `<b>${money(p.rate, 0)}/g</b><br>${dateStr(p.at)}`;
    const bx = svg.getBoundingClientRect();
    const px = (x(p.at) / 340) * bx.width;
    tip.style.left = `${Math.min(Math.max(px - 60, 0), bx.width - 120)}px`;
    tip.style.top = `${(y(Number(p.rate)) / 180) * bx.height - 54}px`;
  };
  const leave = () => { tip.hidden = true; xh.setAttribute('visibility', 'hidden'); $$('.dot', svg).forEach(d => d.classList.remove('on')); };
  hit.addEventListener('pointermove', move);
  hit.addEventListener('pointerdown', move);
  hit.addEventListener('pointerleave', leave);
}

// ---------------------------------------------------------------------------
// Settings view
// ---------------------------------------------------------------------------
function viewSettings() {
  const c = S.cfg; const d = c.defaults; const cs = c.currencySymbol;
  const sec = (icon, title, body, open = false) => `<details class="card set" ${open ? 'open' : ''}><summary>${icon} ${title}</summary>${body}</details>`;
  const allPurities = c.metals.flatMap(m => m.purities.map(p => [p.key, `${m.name} · ${p.label}`]));
  return `<h2 class="vh">${t('settings')}</h2>
  ${sec('🏪', t('shopProfile'), `
    <div class="logo-row">
      <label class="logo-btn">${c.profile.logo ? `<img src="${c.profile.logo}" alt="">` : '🖼'}<input type="file" accept="image/*" data-a="logo" hidden></label>
      <div><small class="hint">${t('logoHint')}</small>${c.profile.logo ? `<button class="link" data-a="logo-del">${t('remove')}</button>` : ''}</div>
    </div>
    ${inputFld({ path: 'profile.name', label: t('shopName'), value: c.profile.name, type: 'text', cfg: true })}
    <label class="fld"><span>${t('address')}</span><textarea data-b="cfg:profile.address" rows="2">${esc(c.profile.address)}</textarea></label>
    <div class="grid2">
      ${inputFld({ path: 'profile.phone', label: t('phone'), value: c.profile.phone, type: 'tel', cfg: true })}
      ${inputFld({ path: 'profile.gstin', label: 'GSTIN', value: c.profile.gstin, type: 'text', cfg: true })}
    </div>
    ${inputFld({ path: 'profile.footer', label: t('invoiceFooter'), value: c.profile.footer, type: 'text', cfg: true })}
  `)}
  ${sec('🎨', t('appearance'), `
    ${selectFld({ path: 'language', label: t('language'), value: c.language, options: LANGUAGES.map(l => [l.code, l.name]), cfg: true })}
    <div class="lbl">${t('theme')}</div>
    ${seg({ path: 'theme', value: c.theme, options: [['dark', t('dark')], ['light', t('light')], ['auto', t('auto')]], cfg: true })}
    <label class="fld"><span>${t('fontSize')} (${Math.round(c.fontScale * 100)}%)</span><input type="range" min="0.85" max="1.4" step="0.05" value="${c.fontScale}" data-b="cfg:fontScale" data-num></label>
    ${toggle({ path: 'haptics', label: t('haptics'), value: c.haptics, cfg: true })}
  `)}
  ${sec('🧮', t('calcDefaults'), `
    <div class="grid2">
      ${selectFld({ path: 'defaults.metal', label: t('metal'), value: d.metal, options: metalOpts(), cfg: true })}
      ${selectFld({ path: 'defaults.purityKey', label: t('purity'), value: d.purityKey, options: purityOpts(d.metal).filter(([k]) => k !== 'custom'), cfg: true })}
      ${selectFld({ path: 'defaults.category', label: t('category'), value: d.category, options: c.categories.map(x => [x, x]), cfg: true })}
      ${selectFld({ path: 'weightUnit', label: t('unit'), value: c.weightUnit, options: unitOpts(), cfg: true })}
    </div>
    <div class="lbl">${t('rateBasis')}</div>
    ${seg({ path: 'rateBasis', value: c.rateBasis, options: [['purity', t('rateForSelected')], ['pure', t('rateFor24k')]], cfg: true, small: true })}
    <div class="lbl">${t('wastageVA')}</div>
    <div class="grid2">${seg({ path: 'defaults.wastageType', value: d.wastageType, options: [['pct', '%'], ['g', 'g']], cfg: true, small: true })}
      ${inputFld({ path: 'defaults.wastage', label: '', value: d.wastage, cfg: true })}</div>
    <div class="lbl">${t('makingCharges')}</div>
    ${seg({ path: 'defaults.makingType', value: d.makingType, options: [['perGram', t('perGram')], ['pct', t('pctOfMetal')], ['flat', t('flat')]], cfg: true, small: true })}
    <div class="grid2">${inputFld({ path: 'defaults.making', label: '', value: d.making, cfg: true })}
      ${selectFld({ path: 'defaults.makingWeightBasis', label: t('onWeight'), value: d.makingWeightBasis, options: [['net', t('netWt')], ['chargeable', t('chargeable')]], cfg: true })}</div>
    <div class="grid2">
      ${inputFld({ path: 'defaults.hallmarkFee', label: t('hallmarkFee'), value: d.hallmarkFee, suffix: cs, cfg: true })}
      ${selectFld({ path: 'rounding', label: t('rounding'), value: c.rounding, options: [['none', t('round.none')], ['1', t('round.1')], ['10', t('round.10')]], cfg: true })}
      ${selectFld({ path: 'numberStyle', label: t('numberStyle'), value: c.numberStyle, options: [['indian', '1,25,000'], ['intl', '125,000']], cfg: true })}
      ${inputFld({ path: 'currencySymbol', label: t('currencySymbol'), value: c.currencySymbol, type: 'text', cfg: true })}
      ${inputFld({ path: 'tolaGrams', label: t('tolaGrams'), value: c.tolaGrams, suffix: 'g', cfg: true })}
    </div>
  `)}
  ${sec('🧾', t('gstDefaults'), `<div class="grid3">${['metal', 'making', 'hallmark', 'stones', 'other'].map(k => inputFld({ path: `gst.${k}`, label: t(`gst.${k}`), value: c.gst[k], suffix: '%', cfg: true })).join('')}</div>`)}
  ${sec('✦', t('presets'), `
    ${c.presets.map((p, i) => `<div class="preset">
      <div class="old-row1"><input class="li-label" data-b="cfg:presets.${i}.name" value="${esc(p.name)}"><button class="x" data-a="preset-del" data-j="${i}">✕</button></div>
      ${seg({ path: `presets.${i}.makingType`, value: p.makingType, options: [['perGram', t('perGram')], ['pct', t('pctOfMetal')], ['flat', t('flat')]], cfg: true, small: true })}
      <div class="grid3">
        ${inputFld({ path: `presets.${i}.making`, label: t('making'), value: p.making, cfg: true })}
        ${inputFld({ path: `presets.${i}.wastage`, label: `${t('wastage')} (${p.wastageType === 'g' ? 'g' : '%'})`, value: p.wastage, cfg: true })}
        ${inputFld({ path: `presets.${i}.hallmarkFee`, label: t('hallmark'), value: p.hallmarkFee, cfg: true })}
      </div>
    </div>`).join('')}
    <button class="link" data-a="preset-add">＋ ${t('addPreset')}</button>
  `)}
  ${sec('🪙', t('metalsPurities'), `
    ${c.metals.map((m, mi) => `<div class="preset">
      <div class="old-row1"><input class="li-label" data-b="cfg:metals.${mi}.name" value="${esc(m.name)}">
        ${c.metals.length > 1 ? `<button class="x" data-a="metal-del" data-j="${mi}">✕</button>` : ''}</div>
      ${inputFld({ path: `metals.${mi}.refPurity`, label: t('refPurity'), value: m.refPurity, suffix: '%', cfg: true })}
      ${m.purities.map((p, pi) => `<div class="li pur">
        <input data-b="cfg:metals.${mi}.purities.${pi}.key" value="${esc(p.key)}" placeholder="22K" class="k">
        <input data-b="cfg:metals.${mi}.purities.${pi}.label" value="${esc(p.label)}" class="li-label">
        <div class="in-wrap"><input inputmode="decimal" data-b="cfg:metals.${mi}.purities.${pi}.pct" value="${esc(p.pct)}"><em>%</em></div>
        <button class="x" data-a="purity-del" data-m="${mi}" data-j="${pi}">✕</button></div>`).join('')}
      <button class="link" data-a="purity-add" data-m="${mi}">＋ ${t('addPurity')}</button>
    </div>`).join('')}
    <button class="link" data-a="metal-add">＋ ${t('addMetal')}</button>
  `)}
  ${sec('🏷', t('categories'), `<div class="chips">${c.categories.map((x, i) => `<span class="chip">${esc(x)} <button class="x" data-a="cat-del" data-j="${i}">✕</button></span>`).join('')}</div>
    <button class="link" data-a="cat-add">＋ ${t('addCategory')}</button>`)}
  ${sec('👁', t('showHideFields'), `<div class="checks">${FIELD_KEYS.map(k => `<label class="tgl"><input type="checkbox" data-a="field-vis" data-k="${k}" ${hidden(k) ? '' : 'checked'}><i></i><span>${t(`field.${k}`)}</span></label>`).join('')}</div>`)}
  ${sec('💬', t('shareFields'), `<div class="checks">${SHARE_FIELD_KEYS.map(k => `<label class="tgl"><input type="checkbox" data-a="share-vis" data-k="${k}" ${c.shareFields.includes(k) ? 'checked' : ''}><i></i><span>${t(`sf.${k}`)}</span></label>`).join('')}</div>`)}
  ${sec('⚖️', t('fairLimits'), `<p class="hint">${t('fairHint')}</p><div class="grid3">
    ${inputFld({ path: 'fair.makingPctMax', label: t('fairMakingPct'), value: c.fair.makingPctMax, suffix: '%', cfg: true })}
    ${inputFld({ path: 'fair.makingPerGramMax', label: t('fairPerGram'), value: c.fair.makingPerGramMax, suffix: cs, cfg: true })}
    ${inputFld({ path: 'fair.wastagePctMax', label: t('fairWastage'), value: c.fair.wastagePctMax, suffix: '%', cfg: true })}</div>`)}
  ${sec('✨', t('aiOnline'), `
    <p class="hint">${t('aiHint')}</p>
    ${toggle({ path: 'ai.enabled', label: t('enableAI'), value: c.ai.enabled, cfg: true })}
    ${inputFld({ path: 'ai.apiKey', label: t('apiKey'), value: c.ai.apiKey, type: 'password', cfg: true, placeholder: 'sk-ant-…' })}
    ${inputFld({ path: 'ai.model', label: t('aiModel'), value: c.ai.model, type: 'text', cfg: true })}
    ${selectFld({ path: 'ai.voiceLang', label: t('voiceLang'), value: c.ai.voiceLang, options: [['en-IN', 'English (India)'], ['kn-IN', 'ಕನ್ನಡ'], ['hi-IN', 'हिन्दी']], cfg: true })}
    <div class="lbl">🌐 ${t('liveRate')}</div>
    <p class="hint">${t('liveRateHint')}</p>
    ${inputFld({ path: 'liveRate.url', label: 'URL', value: c.liveRate.url, type: 'text', cfg: true, placeholder: 'https://…' })}
    <div class="grid3">
      ${inputFld({ path: 'liveRate.path', label: t('jsonPath'), value: c.liveRate.path, type: 'text', cfg: true, placeholder: 'data.gold24' })}
      ${inputFld({ path: 'liveRate.perGrams', label: t('pricePerGrams'), value: c.liveRate.perGrams, cfg: true })}
      ${selectFld({ path: 'liveRate.purityKey', label: t('purity'), value: c.liveRate.purityKey, options: allPurities, cfg: true })}
    </div>
  `)}
  ${sec('💾', t('data'), `
    <div class="row-btns wrap">
      <button class="btn ghost" data-a="backup">⬇ ${t('backup')}</button>
      <label class="btn ghost">⬆ ${t('restore')}<input type="file" accept="application/json,.json" data-a="restore" hidden></label>
    </div>
    <div class="row-btns wrap">
      <button class="btn danger-ghost" data-a="reset-settings">${t('resetSettings')}</button>
      <button class="btn danger-ghost" data-a="clear-history">${t('clearHistory')}</button>
    </div>
  `)}
  ${sec('📜', t('disclaimerTitle'), `<label class="fld"><textarea data-b="cfg:disclaimer" rows="3">${esc(c.disclaimer)}</textarea></label>`)}
  <p class="about">SwarnaCalc · ${t('appTagline')}<br><small>${t('offlineNote')}</small></p>
  <div class="spacer"></div>`;
}

// ---------------------------------------------------------------------------
// Render
// ---------------------------------------------------------------------------
function applyAppearance() {
  const root = document.documentElement;
  const theme = S.cfg.theme === 'auto' ? (matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark') : S.cfg.theme;
  root.dataset.theme = theme;
  root.style.fontSize = `${16 * (Number(S.cfg.fontScale) || 1)}px`;
  root.lang = S.cfg.language;
  $('meta[name="theme-color"]')?.setAttribute('content', theme === 'dark' ? '#0b0a08' : '#fbf7ee');
}

function render() {
  recompute();
  applyAppearance();
  const v = $('#view');
  const scroll = window.scrollY;
  // Keep expanded sections open across re-renders of the same view.
  const key = d => d.querySelector('summary')?.textContent.trim().slice(0, 40);
  if (v.dataset.view === S.view) S.openDetails = new Map($$('details', v).map(d => [key(d), d.open]));
  else S.openDetails = null;
  v.dataset.view = S.view;
  v.innerHTML = S.view === 'calc' ? viewCalc()
    : S.view === 'history' ? viewHistory()
      : S.view === 'compare' ? viewCompare()
        : S.view === 'rates' ? viewRates()
          : viewSettings();
  if (S.openDetails) $$('details', v).forEach(d => { const o = S.openDetails.get(key(d)); if (o !== undefined) d.open = o; });
  $$('#nav button').forEach(b => b.classList.toggle('on', b.dataset.view === S.view));
  $$('#nav [data-label]').forEach(el => { el.textContent = t(el.dataset.label); });
  $('#hdr-sub').textContent = headerRate();
  $('#new-btn').textContent = `＋ ${t('new')}`;
  renderTotalBar();
  document.body.classList.toggle('has-total', S.view === 'calc');
  window.scrollTo(0, scroll);
  if (S.view === 'calc') updateLive();
}

function headerRate() {
  const k = S.cfg.defaults.purityKey;
  const r = S.cfg.rates[k];
  return r ? `${k} ${money(r.rate, 0)}/g · ${dateStr(r.updatedAt)}` : t('setTodaysRate');
}

async function go(view) {
  S.view = view;
  if (view === 'history') S.history = await store.estimates.all();
  if (view === 'rates') rateLogCache = await store.rateLog.all();
  window.scrollTo(0, 0);
  render();
}

// ---------------------------------------------------------------------------
// Input binding
// ---------------------------------------------------------------------------
function targetFor(b) {
  if (b.startsWith('cfg:')) return [S.cfg, b.slice(4), 'cfg'];
  if (b.startsWith('cmp:')) return [S.compare, b.slice(4), 'cmp'];
  return [S.est, b, 'est'];
}

function onBoundChange(el, value) {
  const [obj, path, kind] = targetFor(el.dataset.b);
  const prev = getPath(obj, path);
  setPath(obj, path, value);
  if (kind === 'est') {
    S.touched.add(path);
    S.est.updatedAt = Date.now();
    // Changing metal resets purity to the first available; purity change refreshes rate.
    const m = /^items\.(\d+)\.(metal|purityKey)$/.exec(path);
    if (m) {
      const it = S.est.items[Number(m[1])];
      if (m[2] === 'metal' && prev !== value) it.purityKey = findMetal(S.cfg, value).purities[0]?.key || 'custom';
      const saved = it.rateBasis === 'pure' ? S.cfg.rates[findMetal(S.cfg, it.metal).purities[0]?.key] : S.cfg.rates[it.purityKey];
      if (saved?.rate) it.rate = saved.rate;
    }
    if (path === 'mode') switchMode(value, prev);
  }
  if (kind === 'cfg') {
    if (path === 'defaults.metal') S.cfg.defaults.purityKey = findMetal(S.cfg, value).purities[0]?.key || '';
    saveSettingsSoon();
  }
  if (kind === 'cmp') {
    if (path === 'base.metal') S.compare.base.purityKey = findMetal(S.cfg, value).purities[0]?.key || '';
    if (path === 'base.purityKey') S.compare.quotes.forEach(q => { const r = S.cfg.rates[value]; if (r) q.rate = r.rate; });
  }
  if (el.hasAttribute('data-r') || el.dataset.a === 'seg' || kind === 'cfg' && /^(language|theme|fontScale|metals|presets|categories|defaults\.metal)/.test(path)) {
    if (kind === 'cfg' && el.tagName === 'INPUT' && el.type !== 'checkbox') { applyAppearance(); return; }
    render();
  } else if (kind === 'est') {
    updateLive();
  } else if (kind === 'cmp') {
    const res = compareResults();
    const valid = res.filter(x => x.r.valid);
    const cheapest = valid.length > 1 ? valid.reduce((a, c) => (c.r.total.lt(a.r.total) ? c : a)) : null;
    const rows = viewCompareRows();
    $('#cmp-table').innerHTML = compareTable(res, rows, cheapest);
  }
}

function viewCompareRows() {
  return [
    [t('rate'), x => `${money(x.r.items[0].rate, 0)}`],
    [t('chargeable'), x => `${wt(x.r.items[0].chargeable)} g`],
    [t('metalValue'), x => money(x.r.items[0].metalValue, 0)],
    [t('making'), x => money(x.r.items[0].makingNet, 0)],
    [t('stones') + ' + ' + t('other'), x => money(x.r.items[0].stones.add(x.r.items[0].others), 0)],
    [t('hallmark'), x => money(x.r.items[0].hallmark, 0)],
    ['GST', x => money(x.r.gst, 0)],
  ];
}

function switchMode(mode, prev) {
  const e = S.est;
  if ((prev === 'sell' || prev === 'exchange') && (mode === 'buy' || mode === 'coin')) e.oldGold.enabled = false;
  if ((mode === 'exchange' || mode === 'sell') && !e.oldGold.entries.length) e.oldGold.entries.push(newOldGold(S.cfg));
  if (mode === 'exchange') e.oldGold.enabled = true;
  if (mode !== 'sell' && !e.items.length) e.items.push(newItem(S.cfg));
  if (mode === 'coin' && prev !== 'coin') {
    const rate = S.cfg.rates['24K']?.rate ?? '';
    e.items.forEach(it => Object.assign(it, { category: 'Coin', purityKey: '24K', metal: 'gold', rate, wastage: '0', stoneWt: '', stones: [] }));
    const p = S.cfg.presets.find(x => /coin|bar/i.test(x.name));
    if (p) e.items.forEach(it => applyPresetTo(it, p));
  }
  if (mode === 'reverse') { e.items = e.items.slice(0, 1); }
}

function applyPresetTo(it, p) {
  Object.assign(it, { makingType: p.makingType, making: p.making, wastageType: p.wastageType || 'pct', wastage: p.wastage, hallmarkFee: p.hallmarkFee ?? it.hallmarkFee });
}

document.addEventListener('input', e => {
  const el = e.target;
  if (el.id === 'hq') { S.hq.q = el.value; const pos = el.selectionStart; render(); const n = $('#hq'); n.focus(); n.setSelectionRange(pos, pos); return; }
  if (el.dataset.rate !== undefined) return;
  if (!el.dataset.b || el.dataset.a === 'seg') return;
  if (el.tagName === 'SELECT' || el.type === 'checkbox') return; // handled on change
  let v = el.value;
  if (el.dataset.num !== undefined) v = Number(v);
  onBoundChange(el, v);
});

document.addEventListener('change', e => {
  const el = e.target;
  if (el.id === 'hfrom') { S.hq.from = el.value; render(); return; }
  if (el.id === 'hto') { S.hq.to = el.value; render(); return; }
  if (el.id === 'hmode') { S.hq.mode = el.value; render(); return; }
  if (el.id === 'rate-chart-key') { S.rateChartKey = el.value; $('#rate-chart').innerHTML = rateChartHtml(); return; }
  if (el.dataset.a === 'photo') return onPhoto(el);
  if (el.dataset.a === 'logo') return onLogo(el);
  if (el.dataset.a === 'restore') return onRestore(el);
  if (el.dataset.a === 'field-vis') {
    const k = el.dataset.k;
    S.cfg.hiddenFields = el.checked ? S.cfg.hiddenFields.filter(x => x !== k) : [...new Set([...S.cfg.hiddenFields, k])];
    saveSettingsSoon(); return;
  }
  if (el.dataset.a === 'share-vis') {
    const k = el.dataset.k;
    S.cfg.shareFields = el.checked ? [...new Set([...S.cfg.shareFields, k])] : S.cfg.shareFields.filter(x => x !== k);
    saveSettingsSoon(); return;
  }
  if (!el.dataset.b) return;
  if (el.tagName === 'SELECT') onBoundChange(el, el.value);
  else if (el.type === 'checkbox') onBoundChange(el, el.checked);
  else if (el.type === 'range') render();
});

// Mark fields as touched when leaving them so errors appear.
document.addEventListener('focusout', e => {
  const b = e.target.dataset?.b;
  if (b && !b.includes(':')) { S.touched.add(b); if (S.view === 'calc') updateLive(); }
});

// ---------------------------------------------------------------------------
// Click actions
// ---------------------------------------------------------------------------
const actions = {
  seg(el) { onBoundChange(el, el.dataset.v); },
  'toggle-item'(el) {
    const id = el.dataset.id;
    S.open[id] = !(S.open[id] ?? (S.est.items.length === 1));
    render();
  },
  'toggle-breakdown'() {
    if (S.view !== 'calc') return;
    S.breakdown = !S.breakdown;
    render();
    if (S.breakdown) $('.breakdown-card')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  },
  'add-item'() {
    S.est.items.forEach(it => { S.open[it.id] = false; });
    const prev = S.est.items.at(-1);
    const it = newItem(S.cfg, prev ? { metal: prev.metal, purityKey: prev.purityKey, rate: prev.rate, rateBasis: prev.rateBasis } : {});
    S.est.items.push(it); S.open[it.id] = true; render();
    $(`[data-item="${S.est.items.length - 1}"]`)?.scrollIntoView({ behavior: 'smooth' });
  },
  'dup-item'(el) {
    const i = Number(el.dataset.i);
    const copy = JSON.parse(JSON.stringify(S.est.items[i])); copy.id = uid(); copy.name = copy.name ? `${copy.name} (2)` : '';
    S.est.items.splice(i + 1, 0, copy); S.open[copy.id] = true; render(); toast(t('duplicated'));
  },
  async 'del-item'(el) {
    if (!(await confirmDialog(t('confirmDeleteItem'), { ok: t('delete'), danger: true }))) return;
    S.est.items.splice(Number(el.dataset.i), 1); render();
  },
  'remove-photo'(el) { S.est.items[Number(el.dataset.i)].photo = null; render(); },
  'list-add'(el) {
    const list = getPath(S.est, el.dataset.path);
    list.push({ id: uid(), label: '', amount: '' }); render();
    const inputs = $$(`[data-b^="${el.dataset.path}."]`); inputs.at(-2)?.focus();
  },
  'list-del'(el) { getPath(S.est, el.dataset.path).splice(Number(el.dataset.j), 1); render(); },
  'old-add'() { S.est.oldGold.entries.push(newOldGold(S.cfg)); render(); },
  'old-del'(el) { S.est.oldGold.entries.splice(Number(el.dataset.j), 1); if (!S.est.oldGold.entries.length && S.est.mode === 'buy') S.est.oldGold.enabled = false; render(); },
  'apply-preset'(el) {
    const p = S.cfg.presets.find(x => x.id === el.dataset.id);
    if (!p) return;
    const idx = Math.max(0, S.est.items.findIndex(it => S.open[it.id]));
    const it = S.est.items[idx] || S.est.items[0];
    if (!it) return;
    applyPresetTo(it, p); render(); toast(t('presetApplied', { p: p.name }));
  },
  async 'save-preset'(el) {
    const it = S.est.items[Number(el.dataset.i)];
    const name = await promptDialog(t('presetName'), it.name ? `${it.name} style` : '');
    if (!name) return;
    S.cfg.presets.push({ id: uid(), name, makingType: it.makingType, making: it.making, wastageType: it.wastageType, wastage: it.wastage, hallmarkFee: it.hallmarkFee });
    saveSettingsSoon(); render(); toast(t('presetSaved'));
  },
  async 'save-rate'(el) {
    const it = S.est.items[Number(el.dataset.i)];
    if (!D.isValid(it.rate) || !D.from(it.rate).gt(0)) { toast(t('err.rateRequired'), 'bad'); return; }
    const key = it.rateBasis === 'pure' ? findMetal(S.cfg, it.metal).purities[0]?.key : it.purityKey;
    await saveRate(key, it.rate, 'calculator');
    $('#hdr-sub').textContent = headerRate();
    toast(t('rateSaved', { k: key }));
  },
  'use-reverse'(el) {
    const it = S.est.items[0];
    it.gross = D.from(el.dataset.g).round(3).toString();
    S.est.mode = 'buy'; render();
  },
  async voice() {
    if (!ai.voiceSupported()) { toast(t('voiceUnsupported'), 'bad'); return; }
    const close = modal(`<div class="listening"><div class="mic">🎤</div><p>${t('listening')}</p><small>${t('voiceExample')}</small></div>`);
    try {
      const text = await ai.listen(S.cfg.ai.voiceLang);
      close();
      let patch = ai.parseVoice(text);
      if (!Object.keys(patch).length && S.cfg.ai.enabled && S.cfg.ai.apiKey && navigator.onLine) {
        toast(t('aiThinking'));
        const out = await ai.parseWithClaude(S.cfg, text);
        if (out.items?.[0]) patch = ai.aiItemToPatch(out.items[0]);
      }
      const idx = Math.max(0, S.est.items.findIndex(it => S.open[it.id]));
      if (!S.est.items.length) S.est.items.push(newItem(S.cfg));
      Object.assign(S.est.items[idx], patch);
      if (patch.purityKey && !patch.rate) { const r = S.cfg.rates[patch.purityKey]; if (r) S.est.items[idx].rate = r.rate; }
      render();
      toast(Object.keys(patch).length ? `🎤 “${text}”` : t('voiceNotUnderstood', { s: text }), Object.keys(patch).length ? '' : 'bad');
    } catch (err) {
      close();
      toast(err.message === 'network' || !navigator.onLine ? t('voiceOffline') : t('voiceFailed'), 'bad');
    }
  },
  scan() {
    const inp = document.createElement('input');
    inp.type = 'file'; inp.accept = 'image/*'; inp.capture = 'environment';
    inp.onchange = async () => {
      const f = inp.files[0]; if (!f) return;
      if (!navigator.onLine) { toast(t('needOnline'), 'bad'); return; }
      const close = modal(`<div class="listening"><div class="mic spin">✨</div><p>${t('scanning')}</p></div>`);
      try {
        const dataUrl = await resizeImage(f, 1600, 'image/jpeg', 0.85);
        const out = await ai.scanBill(S.cfg, dataUrl);
        close();
        if (!out.items?.length) { toast(t('scanNothing'), 'bad'); return; }
        const rest = S.est.items.filter(it => it.gross || it.name);
        const items = out.items.map(x => newItem(S.cfg, ai.aiItemToPatch(x)));
        S.est.items = [...rest, ...items];
        if (out.customerName) S.est.customer.name = out.customerName;
        if (out.shopName) S.est.jeweller = out.shopName;
        if (out.gstPercent) for (const k of ['metal', 'making', 'hallmark']) S.est.gst[k] = String(out.gstPercent);
        if (S.est.mode === 'sell' || S.est.mode === 'reverse') S.est.mode = 'buy';
        render(); toast(t('scanDone', { n: items.length }));
      } catch (err) {
        close();
        toast(err.message === 'no-key' ? t('needApiKey') : err.message === 'offline' ? t('needOnline') : `${t('scanFailed')} (${err.message})`, 'bad');
      }
    };
    inp.click();
  },
  async save() {
    S.showErrors = true;
    recompute();
    if (!S.res.valid) { updateLive(); toast(t('checkInputs'), 'bad'); const first = $('.has-err'); first?.scrollIntoView({ behavior: 'smooth', block: 'center' }); return; }
    await persistEstimate();
    toast(t('saved'));
  },
  'share-wa'() { shareWhatsApp(S.est, S.res); },
  'share-menu'() { openShareMenu(); },
  async 'h-open'(el) {
    const e = S.history.find(x => x.id === el.dataset.id); if (!e) return;
    S.est = JSON.parse(JSON.stringify(e)); delete S.est.summary;
    S.saved = true; S.open = {}; S.touched = new Set(); S.showErrors = false;
    go('calc');
  },
  async 'h-dup'(el) {
    const e = S.history.find(x => x.id === el.dataset.id); if (!e) return;
    const copy = JSON.parse(JSON.stringify(e));
    copy.id = uid(); copy.createdAt = copy.updatedAt = Date.now();
    copy.items.forEach(i => { i.id = uid(); });
    await store.estimates.put(copy);
    S.history = await store.estimates.all(); render(); toast(t('duplicated'));
  },
  'h-wa'(el) {
    const e = S.history.find(x => x.id === el.dataset.id); if (!e) return;
    shareWhatsApp(e, calcEstimate(S.cfg, e));
  },
  async 'h-del'(el) {
    if (!(await confirmDialog(t('confirmDelete'), { ok: t('delete'), danger: true }))) return;
    await store.estimates.del(el.dataset.id);
    if (S.est.id === el.dataset.id) S.saved = false;
    S.history = await store.estimates.all(); render();
  },
  'cmp-add'() { S.compare.quotes.push(newQuote(S.compare.quotes.length + 1)); render(); },
  'cmp-del'(el) { S.compare.quotes.splice(Number(el.dataset.j), 1); render(); },
  'cmp-open'(el) {
    const x = compareResults()[Number(el.dataset.j)];
    S.est = { ...x.est, id: uid(), jeweller: x.q.jeweller };
    S.saved = false; S.open = {}; go('calc');
  },
  'derive-rates'(el) {
    const m = findMetal(S.cfg, el.dataset.m);
    const pure = $(`[data-rate="${m.purities[0].key}"]`)?.value;
    if (!D.isValid(pure) || !D.from(pure).gt(0)) { toast(t('enterTopRate', { k: m.purities[0].label }), 'bad'); return; }
    m.purities.slice(1).forEach(p => {
      const inp = $(`[data-rate="${p.key}"]`);
      if (inp) inp.value = D.from(pure).mul(p.pct).div(m.refPurity || '99.9').round(0).toString();
    });
    toast(t('derived'));
  },
  async 'save-rates'() {
    let n = 0;
    for (const inp of $$('[data-rate]')) {
      const key = inp.dataset.rate; const v = inp.value.trim();
      const cur = S.cfg.rates[key]?.rate;
      if (!v) { if (cur) { delete S.cfg.rates[key]; n++; } continue; }
      if (!D.isValid(v) || !D.from(v).gt(0)) { toast(t('err.number'), 'bad'); inp.focus(); return; }
      if (cur !== D.from(v).toString() || !S.cfg.rates[key]?.updatedAt) { await saveRate(key, v, 'rates'); n++; }
    }
    saveSettingsSoon();
    rateLogCache = await store.rateLog.all();
    render(); toast(n ? t('ratesSaved') : t('noChanges'));
  },
  async 'live-rate'() {
    const lr = S.cfg.liveRate;
    try {
      toast(t('fetching'));
      const rate = await ai.fetchLiveRate(lr);
      const r = D.from(String(rate)).round(2);
      if (await confirmDialog(t('useLiveRate', { k: lr.purityKey, v: money(r) }), { ok: t('useIt') })) {
        await saveRate(lr.purityKey, r.toString(), 'live');
        rateLogCache = await store.rateLog.all(); render(); toast(t('rateSaved', { k: lr.purityKey }));
      }
    } catch (err) {
      toast(err.message === 'offline' ? t('needOnline') : `${t('liveFailed')} (${err.message})`, 'bad');
    }
  },
  async 'rl-del'(el) { await store.rateLog.del(el.dataset.id); rateLogCache = await store.rateLog.all(); $('#rate-chart').innerHTML = rateChartHtml(); },
  'logo-del'() { S.cfg.profile.logo = null; saveSettingsSoon(); render(); },
  'preset-add'() { const d = S.cfg.defaults; S.cfg.presets.push({ id: uid(), name: t('newPreset'), makingType: d.makingType, making: d.making, wastageType: d.wastageType, wastage: d.wastage, hallmarkFee: d.hallmarkFee }); saveSettingsSoon(); render(); },
  async 'preset-del'(el) { if (await confirmDialog(t('confirmDelete'), { ok: t('delete'), danger: true })) { S.cfg.presets.splice(Number(el.dataset.j), 1); saveSettingsSoon(); render(); } },
  'metal-add'() { S.cfg.metals.push({ id: uid(), name: t('newMetal'), refPurity: '99.9', purities: [{ key: `M${S.cfg.metals.length}`, label: '999', pct: '99.9' }] }); saveSettingsSoon(); render(); },
  async 'metal-del'(el) {
    if (!(await confirmDialog(t('confirmDelete'), { ok: t('delete'), danger: true }))) return;
    S.cfg.metals.splice(Number(el.dataset.j), 1);
    if (!S.cfg.metals.find(m => m.id === S.cfg.defaults.metal)) { S.cfg.defaults.metal = S.cfg.metals[0].id; S.cfg.defaults.purityKey = S.cfg.metals[0].purities[0]?.key || ''; }
    saveSettingsSoon(); render();
  },
  'purity-add'(el) { const m = S.cfg.metals[Number(el.dataset.m)]; m.purities.push({ key: `P${uid().slice(-3)}`, label: t('newPurity'), pct: '' }); saveSettingsSoon(); render(); },
  'purity-del'(el) { const m = S.cfg.metals[Number(el.dataset.m)]; if (m.purities.length <= 1) { toast(t('keepOne'), 'bad'); return; } m.purities.splice(Number(el.dataset.j), 1); saveSettingsSoon(); render(); },
  async 'cat-add'() { const name = await promptDialog(t('categoryName')); if (name) { S.cfg.categories.push(name); saveSettingsSoon(); render(); } },
  'cat-del'(el) { S.cfg.categories.splice(Number(el.dataset.j), 1); saveSettingsSoon(); render(); },
  async backup() {
    const data = await store.exportAll();
    data.settings = S.cfg;
    downloadBlob(new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }), `swarnacalc-backup-${new Date().toISOString().slice(0, 10)}.json`);
    toast(t('backupDone'));
  },
  async 'reset-settings'() {
    if (!(await confirmDialog(t('confirmReset'), { ok: t('reset'), danger: true }))) return;
    const keep = { rates: S.cfg.rates, profile: S.cfg.profile };
    S.cfg = { ...defaultSettings(), ...keep };
    await store.kv.set('settings', S.cfg); render(); toast(t('done'));
  },
  async 'clear-history'() {
    if (!(await confirmDialog(t('confirmClearHistory'), { ok: t('delete'), danger: true }))) return;
    await store.estimates.clear(); S.saved = false; toast(t('done'));
  },
};

document.addEventListener('click', e => {
  const nav = e.target.closest('#nav button');
  if (nav) { haptic(); go(nav.dataset.view); return; }
  const el = e.target.closest('[data-a]');
  if (!el || el.tagName === 'INPUT' && el.type !== 'button') return;
  const fn = actions[el.dataset.a];
  if (fn) { haptic(); fn(el, e); }
});

async function newEst(mode = 'buy') {
  if (!S.saved && S.est.items.some(i => i.gross) && !(await confirmDialog(t('confirmNew'), { ok: t('newEstimate') }))) return;
  S.est = newEstimate(S.cfg, mode);
  S.saved = false; S.open = {}; S.touched = new Set(); S.showErrors = false; S.breakdown = false;
  go('calc');
}

async function persistEstimate() {
  const r = recompute();
  S.est.updatedAt = Date.now();
  const rec = JSON.parse(JSON.stringify(S.est));
  rec.summary = { amount: (r.hasOldGold ? r.payable : r.total).toString(), direction: r.direction };
  await store.estimates.put(rec);
  for (const it of S.est.items) if (D.isValid(it.rate) && D.from(it.rate).gt(0) && it.rateBasis === 'purity' && !S.cfg.rates[it.purityKey]) await saveRate(it.purityKey, it.rate, 'estimate');
  S.saved = true; saveDraftSoon();
}

// ---------------------------------------------------------------------------
// Sharing
// ---------------------------------------------------------------------------
async function shareWhatsApp(est, res) {
  const text = buildWhatsAppText(shareCtx(), est, res);
  await shareText(text, est.customer?.phone);
}

function openShareMenu() {
  const close = modal(`<h3 class="sheet-h">${t('share')}</h3>
    <div class="share-grid">
      <button data-x="wa">${WA_ICON}<span>${t('waText')}</span></button>
      ${S.est.customer.phone ? `<button data-x="wa-cust">👤<span>${t('waCustomer')}</span></button>` : ''}
      <button data-x="sys">📤<span>${t('shareText')}</span></button>
      <button data-x="img">🖼<span>${t('shareImage')}</span></button>
      <button data-x="pdf">📄<span>${t('sharePdf')}</span></button>
      <button data-x="copy">📋<span>${t('copyText')}</span></button>
      <button data-x="fields">☑️<span>${t('chooseFields')}</span></button>
    </div>
    <pre class="preview">${esc(buildWhatsAppText(shareCtx(), S.est, S.res))}</pre>
    <button class="btn ghost full" data-close>${t('close')}</button>`, {
    onMount: el => el.addEventListener('click', async e => {
      const x = e.target.closest('[data-x]')?.dataset.x; if (!x) return;
      haptic();
      const text = buildWhatsAppText(shareCtx(), S.est, S.res);
      try {
        if (x === 'wa') { close(); await shareText(text, ''); }
        if (x === 'wa-cust') { close(); await shareText(text, S.est.customer.phone); }
        if (x === 'sys') { close(); await shareText(text, '', { whatsapp: false }); }
        if (x === 'copy') { await copyText(text); toast(t('copied')); }
        if (x === 'img') { toast(t('generating')); const blob = await renderImageCard(shareCtx(), S.est, S.res); close(); await shareFile(blob, `estimate-${fileStamp()}.png`, text); }
        if (x === 'pdf') { toast(t('generating')); const blob = await renderPdf(shareCtx(), S.est, S.res); close(); await shareFile(blob, `estimate-${fileStamp()}.pdf`, ''); }
        if (x === 'fields') { close(); S.view = 'settings'; render(); const d = $$('details.set')[8]; if (d) { d.open = true; d.scrollIntoView({ behavior: 'smooth' }); } }
      } catch (err) { console.error(err); toast(t('shareFailed'), 'bad'); }
    }),
  });
}

const fileStamp = () => {
  const n = (S.est.customer.name || S.est.items[0]?.name || 'swarnacalc').replace(/[^\wऀ-ॿಀ-೿]+/g, '-').slice(0, 24);
  return `${n}-${new Date().toISOString().slice(0, 10)}`;
};

// ---------------------------------------------------------------------------
// Files: photos, logo, restore
// ---------------------------------------------------------------------------
function resizeImage(file, max, type = 'image/jpeg', q = 0.82) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      const s = Math.min(1, max / Math.max(img.width, img.height));
      const c = document.createElement('canvas');
      c.width = Math.round(img.width * s); c.height = Math.round(img.height * s);
      c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
      URL.revokeObjectURL(url);
      resolve(c.toDataURL(type, q));
    };
    img.onerror = () => { URL.revokeObjectURL(url); reject(new Error('bad-image')); };
    img.src = url;
  });
}

async function onPhoto(el) {
  const f = el.files[0]; if (!f) return;
  try { S.est.items[Number(el.dataset.i)].photo = await resizeImage(f, 900); render(); } catch { toast(t('photoFailed'), 'bad'); }
}
async function onLogo(el) {
  const f = el.files[0]; if (!f) return;
  try { S.cfg.profile.logo = await resizeImage(f, 320, 'image/png'); saveSettingsSoon(); render(); } catch { toast(t('photoFailed'), 'bad'); }
}
async function onRestore(el) {
  const f = el.files[0]; if (!f) return;
  try {
    const data = JSON.parse(await f.text());
    if (!(await confirmDialog(t('confirmRestore', { n: (data.estimates || []).length }), { ok: t('restore'), danger: true }))) return;
    await store.importAll(data);
    S.cfg = mergeSettings(data.settings);
    render(); toast(t('restoreDone'));
  } catch (err) { toast(`${t('restoreFailed')} (${err.message})`, 'bad'); }
}

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------
async function boot() {
  try {
    S.cfg = mergeSettings(await store.kv.get('settings'));
    const draft = await store.kv.get('draft');
    if (draft?.est) { S.est = draft.est; S.saved = !!draft.saved; }
  } catch (e) { console.warn(e); }
  if (!S.est) S.est = newEstimate(S.cfg, 'buy');
  S.rateChartKey = S.cfg.defaults.purityKey;
  const params = new URLSearchParams(location.search);
  const m = params.get('mode');
  if (m && ['buy', 'sell', 'exchange', 'coin', 'reverse'].includes(m)) { S.est = newEstimate(S.cfg, m); }
  render();
  $('#new-btn').addEventListener('click', () => { haptic(); newEst(S.est.mode === 'reverse' ? 'buy' : S.est.mode); });
  $('#hdr-sub').addEventListener('click', () => go('rates'));
  matchMedia('(prefers-color-scheme: light)').addEventListener?.('change', applyAppearance);
  const splash = $('#splash');
  setTimeout(() => { splash.classList.add('hide'); setTimeout(() => splash.remove(), 600); }, 700);
  store.requestPersistence();
  // The Android app ships the files inside the APK, so it needs no service worker.
  if ('serviceWorker' in navigator && location.protocol !== 'file:' && !window.SwarnaAndroid) {
    navigator.serviceWorker.register('./sw.js').catch(err => console.warn('SW', err));
  }
  const net = () => document.body.classList.toggle('offline', !navigator.onLine);
  addEventListener('online', net); addEventListener('offline', net); net();
}

boot();

// Android back key: close a dialog, then return to the calculator, then exit.
function back() {
  if ($('#modal').classList.contains('show')) { $('#modal').classList.remove('show'); $('#modal').innerHTML = ''; return true; }
  if (S.view !== 'calc') { go('calc'); return true; }
  return false;
}

// Exposed for the Android shell and for debugging / automated checks
window.SwarnaCalc = { S, calcEstimate, calcItem, back };

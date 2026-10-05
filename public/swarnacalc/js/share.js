// Sharing: WhatsApp text, premium image card and PDF estimate.
// Everything is generated on the device, so it works offline.

import { D } from './decimal.js';

// ctx = { cfg, t, money(d), wt(d), dateStr(ts) }

const has = (cfg, k) => cfg.shareFields.includes(k);

export function buildWhatsAppText(ctx, est, res) {
  const { cfg, t, money, wt } = ctx;
  const L = [];
  const p = cfg.profile;
  if (has(cfg, 'shop') && (p.name || est.jeweller)) {
    L.push(`✨ *${p.name || est.jeweller}*`);
    if (p.phone) L.push(`📞 ${p.phone}`);
  }
  if (has(cfg, 'customer') && (est.customer?.name || est.customer?.phone)) {
    L.push(`👤 ${[est.customer.name, est.customer.phone].filter(Boolean).join(' · ')}`);
  }
  if (L.length) L.push('');

  res.items.forEach((r, i) => {
    const item = est.items[i];
    const title = item.name || item.category || t('item');
    if (has(cfg, 'item')) L.push(`💍 ${res.items.length > 1 ? `${i + 1}. ` : ''}${t('wa.jewellery')}: ${title} (${r.purityLabel})`);
    const parts = [];
    if (has(cfg, 'weights')) {
      if (r.stoneWt.gt(0)) parts.push(`${t('gross')}: ${wt(r.gross)} g`);
      parts.push(`${t('netWt')}: ${wt(r.net)} g`);
    }
    if (has(cfg, 'rate')) parts.push(`${t('rate')}: ${money(r.rate, 0)}/g`);
    if (parts.length) L.push(`⚖️ ${parts.join(' | ')}`);
    if (has(cfg, 'wastage') && r.wastageG.gt(0)) L.push(`🔥 ${t('wastage')}: ${wt(r.wastageG)} g → ${t('chargeable')}: ${wt(r.chargeable)} g`);
    if (has(cfg, 'metal')) L.push(`🪙 ${t('metalValue')}: ${money(r.metalValue)}`);
    const mk = [];
    if (has(cfg, 'making')) mk.push(`🔨 ${t('making')}: ${money(r.makingNet)}${r.makingDiscount.gt(0) ? ` (−${money(r.makingDiscount)})` : ''}`);
    if (has(cfg, 'stones') && r.stones.gt(0)) mk.push(`💎 ${t('stones')}: ${money(r.stones)}`);
    if (mk.length) L.push(mk.join(' | '));
    const hm = [];
    if (has(cfg, 'hallmark') && r.hallmark.gt(0)) hm.push(`🏷️ ${t('hallmark')}: ${money(r.hallmark)}`);
    if (has(cfg, 'others') && r.others.gt(0)) {
      for (const o of item.others) if (D.from(o.amount || 0).gt(0)) hm.push(`➕ ${o.label || t('other')}: ${money(D.from(o.amount))}`);
    }
    if (hm.length) L.push(hm.join(' | '));
    if (res.items.length > 1) L.push(`   ${t('itemTotal')}: ${money(r.subtotal)}`);
    L.push('');
  });

  if (res.items.length) {
    if (has(cfg, 'discount') && res.discount.gt(0)) L.push(`🎁 ${t('discount')}: −${money(res.discount)}`);
    if (has(cfg, 'gst')) {
      const rates = [...new Set(res.gstLines.filter(l => l.amount.gt(0)).map(l => l.rate.toString()))];
      L.push(`🧾 GST${rates.length === 1 ? ` (${rates[0]}%)` : ''}: ${money(res.gst)}`);
    }
    if (has(cfg, 'total')) L.push(`💰 *${t('wa.total')}: ${money(res.total, 0)}*`);
  }
  if (has(cfg, 'oldGold') && res.hasOldGold) {
    res.oldGold.forEach((o, i) => {
      L.push(`♻️ ${est.oldGold.entries[i].label || t('oldGold')}: ${wt(o.weight)} g @ ${o.purity.toString()}% → −${money(o.value)}`);
    });
    L.push(`👉 *${res.direction === 'receive' ? t('amountToReceive') : t('amountToPay')}: ${money(res.payable, 0)}*`);
  }
  if (has(cfg, 'date')) L.push(`📅 ${ctx.dateStr(est.updatedAt || Date.now())} | ${t('estimateOnly')}`);
  if (has(cfg, 'disclaimer')) L.push(`_${cfg.disclaimer}_`);
  return L.join('\n').replace(/\n{3,}/g, '\n\n').trim();
}

// Inside the Android app (android/ folder) a native bridge replaces the
// browser-only Web Share / download APIs.
const native = () => (typeof window !== 'undefined' ? window.SwarnaAndroid : undefined);

function openUrl(url) {
  if (native()) native().openUrl(url);
  else window.open(url, '_blank');
}

// whatsapp: true → go straight to WhatsApp; false → system share sheet.
export async function shareText(text, phone, { whatsapp = true } = {}) {
  const digits = (phone || '').replace(/\D/g, '');
  if (digits) {
    const num = digits.length === 10 ? '91' + digits : digits;
    openUrl(`https://wa.me/${num}?text=${encodeURIComponent(text)}`);
    return 'wa';
  }
  if (native()) { native().shareText(text, whatsapp ? 'com.whatsapp' : ''); return 'shared'; }
  if (navigator.share) {
    try { await navigator.share({ text }); return 'shared'; } catch (e) { if (e.name === 'AbortError') return 'cancel'; }
  }
  openUrl(`https://wa.me/?text=${encodeURIComponent(text)}`);
  return 'wa';
}

async function blobToBase64(blob) {
  const buf = new Uint8Array(await blob.arrayBuffer());
  let bin = '';
  for (let i = 0; i < buf.length; i += 0x8000) bin += String.fromCharCode.apply(null, buf.subarray(i, i + 0x8000));
  return btoa(bin);
}

export async function shareFile(blob, filename, text) {
  if (native()) { native().shareFile(await blobToBase64(blob), filename, blob.type, text || ''); return 'shared'; }
  const file = new File([blob], filename, { type: blob.type });
  if (navigator.canShare && navigator.canShare({ files: [file] })) {
    try { await navigator.share({ files: [file], title: filename, text }); return 'shared'; } catch (e) { if (e.name === 'AbortError') return 'cancel'; }
  }
  downloadBlob(blob, filename);
  return 'downloaded';
}

export async function downloadBlob(blob, filename) {
  if (native()) { native().saveFile(await blobToBase64(blob), filename, blob.type || 'application/octet-stream'); return; }
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 4000);
}

export function copyText(text) {
  if (native()) { native().copyText(text); return Promise.resolve(); }
  return navigator.clipboard.writeText(text);
}

// ---------------------------------------------------------------------------
// Canvas helpers
// ---------------------------------------------------------------------------
const SERIF = '"Playfair Display", Georgia, "Noto Serif", "Noto Serif Kannada", "Noto Serif Devanagari", serif';
const SANS = 'system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans", "Noto Sans Kannada", "Noto Sans Devanagari", sans-serif';

function loadImage(src) {
  return new Promise(resolve => {
    if (!src) { resolve(null); return; }
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => resolve(null);
    img.src = src;
  });
}

function goldGradient(ctx, x0, y0, x1, y1) {
  const g = ctx.createLinearGradient(x0, y0, x1, y1);
  g.addColorStop(0, '#8a6a1f');
  g.addColorStop(0.25, '#e9c766');
  g.addColorStop(0.5, '#fff1b8');
  g.addColorStop(0.75, '#d4a93c');
  g.addColorStop(1, '#8a6a1f');
  return g;
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function fitText(ctx, text, maxW) {
  if (ctx.measureText(text).width <= maxW) return text;
  let s = text;
  while (s.length > 1 && ctx.measureText(s + '…').width > maxW) s = s.slice(0, -1);
  return s + '…';
}

function drawCover(ctx, img, x, y, w, h) {
  const r = Math.max(w / img.width, h / img.height);
  const sw = w / r, sh = h / r;
  ctx.drawImage(img, (img.width - sw) / 2, (img.height - sh) / 2, sw, sh, x, y, w, h);
}

const toBlob = (canvas, type, q) => new Promise(res => canvas.toBlob(res, type, q));

// ---------------------------------------------------------------------------
// Premium image card (gold on black)
// ---------------------------------------------------------------------------
export async function renderImageCard(c, est, res) {
  const { cfg, t, money, wt } = c;
  const W = 1080, PAD = 72;
  const photoSrc = est.items.find(i => i.photo)?.photo;
  const [photo, logo] = await Promise.all([loadImage(photoSrc), loadImage(cfg.profile.logo)]);

  // Build rows first to know the height.
  const rows = [];
  res.items.forEach((r, i) => {
    const it = est.items[i];
    rows.push({ type: 'title', text: `${res.items.length > 1 ? `${i + 1}. ` : ''}${it.name || it.category || t('item')}`, sub: `${r.metalName} · ${r.purityLabel}` });
    rows.push({ type: 'kv', k: `${t('netWt')}${r.stoneWt.gt(0) ? ` (${t('gross')} ${wt(r.gross)} g)` : ''}`, v: `${wt(r.net)} g` });
    if (r.wastageG.gt(0)) rows.push({ type: 'kv', k: `${t('wastage')} → ${t('chargeable')}`, v: `${wt(r.wastageG)} → ${wt(r.chargeable)} g` });
    rows.push({ type: 'kv', k: `${t('rate')}`, v: `${money(r.rate, 0)}/g` });
    rows.push({ type: 'kv', k: t('metalValue'), v: money(r.metalValue) });
    rows.push({ type: 'kv', k: t('making'), v: money(r.makingNet) });
    if (r.stones.gt(0)) rows.push({ type: 'kv', k: t('stones'), v: money(r.stones) });
    if (r.hallmark.gt(0)) rows.push({ type: 'kv', k: t('hallmark'), v: money(r.hallmark) });
    if (r.others.gt(0)) rows.push({ type: 'kv', k: t('otherCharges'), v: money(r.others) });
    rows.push({ type: 'gap' });
  });
  if (res.items.length) {
    rows.push({ type: 'rule' });
    if (res.discount.gt(0)) rows.push({ type: 'kv', k: t('discount'), v: `−${money(res.discount)}` });
    rows.push({ type: 'kv', k: 'GST', v: money(res.gst) });
    if (!res.roundOff.isZero()) rows.push({ type: 'kv', k: t('roundOff'), v: money(res.roundOff) });
  }
  if (res.hasOldGold) {
    if (res.items.length) rows.push({ type: 'kv', k: t('total'), v: money(res.total, 0), strong: true });
    res.oldGold.forEach((o, i) => rows.push({ type: 'kv', k: `♻ ${est.oldGold.entries[i].label || t('oldGold')} (${wt(o.weight)} g)`, v: `−${money(o.value)}` }));
  }

  const rowH = r => ({ title: 92, kv: 54, gap: 18, rule: 36 }[r.type]);
  const headerH = logo ? 300 : 270;
  const photoH = photo ? 520 : 0;
  const totalH = 230;
  const footerH = 150;
  const H = headerH + photoH + rows.reduce((s, r) => s + rowH(r), 0) + totalH + footerH + 40;

  const canvas = document.createElement('canvas');
  canvas.width = W; canvas.height = H;
  const ctx = canvas.getContext('2d');

  // Background
  const bg = ctx.createRadialGradient(W / 2, 0, 50, W / 2, H / 2, H);
  bg.addColorStop(0, '#2a2112');
  bg.addColorStop(0.45, '#0f0d09');
  bg.addColorStop(1, '#050505');
  ctx.fillStyle = bg; ctx.fillRect(0, 0, W, H);
  // Borders
  ctx.strokeStyle = goldGradient(ctx, 0, 0, W, H); ctx.lineWidth = 6;
  roundRect(ctx, 24, 24, W - 48, H - 48, 36); ctx.stroke();
  ctx.lineWidth = 1.5; ctx.globalAlpha = 0.6;
  roundRect(ctx, 40, 40, W - 80, H - 80, 28); ctx.stroke();
  ctx.globalAlpha = 1;

  let y = 70;
  // Header
  const shop = cfg.profile.name || est.jeweller || 'SwarnaCalc';
  if (logo) {
    ctx.save(); ctx.beginPath(); ctx.arc(W / 2, y + 44, 44, 0, Math.PI * 2); ctx.clip();
    drawCover(ctx, logo, W / 2 - 44, y, 88, 88); ctx.restore();
    y += 100;
  } else {
    ctx.fillStyle = goldGradient(ctx, W / 2 - 40, 0, W / 2 + 40, 0);
    ctx.font = `48px ${SERIF}`; ctx.textAlign = 'center';
    ctx.fillText('✦', W / 2, y + 50); y += 70;
  }
  ctx.textAlign = 'center';
  ctx.fillStyle = goldGradient(ctx, PAD, 0, W - PAD, 0);
  ctx.font = `600 58px ${SERIF}`;
  ctx.fillText(fitText(ctx, shop, W - PAD * 2), W / 2, y + 52);
  ctx.fillStyle = '#b9a77a'; ctx.font = `26px ${SANS}`;
  const sub = [cfg.profile.phone, cfg.profile.gstin && `GSTIN ${cfg.profile.gstin}`].filter(Boolean).join('  ·  ') || t('appTagline');
  ctx.fillText(fitText(ctx, sub, W - PAD * 2), W / 2, y + 96);
  y = headerH;

  if (photo) {
    ctx.save();
    roundRect(ctx, PAD, y, W - PAD * 2, photoH - 40, 28); ctx.clip();
    drawCover(ctx, photo, PAD, y, W - PAD * 2, photoH - 40);
    ctx.restore();
    ctx.strokeStyle = goldGradient(ctx, PAD, y, W - PAD, y + photoH); ctx.lineWidth = 3;
    roundRect(ctx, PAD, y, W - PAD * 2, photoH - 40, 28); ctx.stroke();
    y += photoH;
  }

  // Rows
  for (const r of rows) {
    if (r.type === 'title') {
      ctx.textAlign = 'left'; ctx.fillStyle = '#f6e7b4'; ctx.font = `600 44px ${SERIF}`;
      ctx.fillText(fitText(ctx, r.text, W - PAD * 2 - 260), PAD, y + 52);
      ctx.textAlign = 'right'; ctx.fillStyle = '#d4af37'; ctx.font = `500 28px ${SANS}`;
      ctx.fillText(r.sub, W - PAD, y + 50);
      ctx.strokeStyle = 'rgba(212,175,55,.35)'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(PAD, y + 74); ctx.lineTo(W - PAD, y + 74); ctx.stroke();
    } else if (r.type === 'kv') {
      ctx.textAlign = 'left'; ctx.fillStyle = r.strong ? '#f6e7b4' : '#a89c80'; ctx.font = `${r.strong ? 600 : 400} 30px ${SANS}`;
      ctx.fillText(fitText(ctx, r.k, W - PAD * 2 - 360), PAD, y + 38);
      ctx.textAlign = 'right'; ctx.fillStyle = '#f3ead2'; ctx.font = `${r.strong ? 700 : 500} 32px ${SANS}`;
      ctx.fillText(r.v, W - PAD, y + 38);
    } else if (r.type === 'rule') {
      ctx.strokeStyle = goldGradient(ctx, PAD, 0, W - PAD, 0); ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(PAD, y + 18); ctx.lineTo(W - PAD, y + 18); ctx.stroke();
    }
    y += rowH(r);
  }

  // Total panel
  y += 10;
  const panelGrad = ctx.createLinearGradient(PAD, y, W - PAD, y + 190);
  panelGrad.addColorStop(0, 'rgba(212,175,55,.18)'); panelGrad.addColorStop(1, 'rgba(212,175,55,.05)');
  ctx.fillStyle = panelGrad; roundRect(ctx, PAD, y, W - PAD * 2, 190, 26); ctx.fill();
  ctx.strokeStyle = goldGradient(ctx, PAD, y, W - PAD, y); ctx.lineWidth = 2; ctx.stroke();
  const label = res.hasOldGold ? (res.direction === 'receive' ? t('amountToReceive') : t('amountToPay')) : t('total');
  const amount = res.hasOldGold ? res.payable : res.total;
  ctx.textAlign = 'center'; ctx.fillStyle = '#d9c48c'; ctx.font = `500 30px ${SANS}`;
  ctx.fillText(label.toUpperCase(), W / 2, y + 58);
  ctx.fillStyle = goldGradient(ctx, PAD, 0, W - PAD, 0); ctx.font = `700 92px ${SERIF}`;
  ctx.fillText(fitText(ctx, money(amount, 0), W - PAD * 2 - 40), W / 2, y + 150);
  y += totalH;

  // Footer
  ctx.fillStyle = '#8f8467'; ctx.font = `26px ${SANS}`; ctx.textAlign = 'center';
  ctx.fillText(`${c.dateStr(est.updatedAt || Date.now())}  ·  ${t('estimateOnly')}`, W / 2, y + 20);
  ctx.font = `22px ${SANS}`; ctx.fillStyle = '#6f6650';
  wrapLines(ctx, cfg.disclaimer, W - PAD * 2).slice(0, 2).forEach((ln, i) => ctx.fillText(ln, W / 2, y + 60 + i * 30));

  return toBlob(canvas, 'image/png');
}

function wrapLines(ctx, text, maxW) {
  const words = String(text || '').split(/\s+/);
  const lines = [];
  let cur = '';
  for (const w of words) {
    const tryL = cur ? cur + ' ' + w : w;
    if (ctx.measureText(tryL).width > maxW && cur) { lines.push(cur); cur = w; } else cur = tryL;
  }
  if (cur) lines.push(cur);
  return lines;
}

// ---------------------------------------------------------------------------
// PDF estimate / invoice: pages drawn on canvas → JPEG → tiny PDF writer.
// ---------------------------------------------------------------------------
const PW = 1240, PH = 1754; // A4 at 150 dpi

export async function renderPdf(c, est, res, { title } = {}) {
  const { cfg, t, money, wt } = c;
  const logo = await loadImage(cfg.profile.logo);
  const pages = [];
  const M = 80;
  const cols = [
    { k: '#', w: 40, a: 'left' },
    { k: t('item'), w: 250, a: 'left' },
    { k: t('purity'), w: 90, a: 'left' },
    { k: `${t('netWt')} (g)`, w: 120, a: 'right' },
    { k: t('rate'), w: 110, a: 'right' },
    { k: t('metalValue'), w: 160, a: 'right' },
    { k: t('making'), w: 140, a: 'right' },
    { k: t('amount'), w: 0, a: 'right' },
  ];
  const usedW = cols.slice(0, -1).reduce((s, x) => s + x.w, 0);
  cols[cols.length - 1].w = PW - M * 2 - usedW;

  const newPage = () => {
    const canvas = document.createElement('canvas');
    canvas.width = PW; canvas.height = PH;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, PW, PH);
    pages.push(canvas);
    return ctx;
  };

  const drawHeader = (ctx, pageNo) => {
    ctx.fillStyle = '#111'; ctx.fillRect(0, 0, PW, 190);
    ctx.fillStyle = goldGradient(ctx, 0, 0, PW, 0); ctx.fillRect(0, 190, PW, 6);
    let x = M;
    if (logo) { drawCover(ctx, logo, M, 40, 110, 110); x = M + 135; }
    ctx.textAlign = 'left';
    ctx.fillStyle = goldGradient(ctx, x, 0, x + 600, 0); ctx.font = `600 46px ${SERIF}`;
    ctx.fillText(fitText(ctx, cfg.profile.name || est.jeweller || 'SwarnaCalc', 650), x, 88);
    ctx.fillStyle = '#d8ccab'; ctx.font = `20px ${SANS}`;
    const lines = [cfg.profile.address, [cfg.profile.phone, cfg.profile.gstin && `GSTIN: ${cfg.profile.gstin}`].filter(Boolean).join('   ')].filter(Boolean);
    lines.slice(0, 2).forEach((l, i) => ctx.fillText(fitText(ctx, l, 680), x, 122 + i * 28));
    ctx.textAlign = 'right';
    ctx.fillStyle = '#f6e7b4'; ctx.font = `600 34px ${SERIF}`;
    ctx.fillText(title || t('estimate').toUpperCase(), PW - M, 82);
    ctx.fillStyle = '#d8ccab'; ctx.font = `20px ${SANS}`;
    ctx.fillText(`${t('date')}: ${c.dateStr(est.updatedAt || Date.now())}`, PW - M, 118);
    ctx.fillText(`#${String(est.id).slice(-6).toUpperCase()}  ·  ${t('page')} ${pageNo}`, PW - M, 146);
  };

  const drawFooter = ctx => {
    ctx.fillStyle = '#777'; ctx.font = `18px ${SANS}`; ctx.textAlign = 'center';
    wrapLines(ctx, cfg.disclaimer, PW - M * 2).slice(0, 2).forEach((l, i) => ctx.fillText(l, PW / 2, PH - 70 + i * 24));
    if (cfg.profile.footer) ctx.fillText(fitText(ctx, cfg.profile.footer, PW - M * 2), PW / 2, PH - 100);
  };

  const drawTableHead = (ctx, y) => {
    ctx.fillStyle = '#f5ecd2'; ctx.fillRect(M, y, PW - M * 2, 46);
    ctx.fillStyle = '#5b4510'; ctx.font = `600 19px ${SANS}`;
    let x = M;
    for (const col of cols) {
      ctx.textAlign = col.a;
      ctx.fillText(col.k, col.a === 'right' ? x + col.w - 10 : x + 10, y + 30);
      x += col.w;
    }
    return y + 46;
  };

  let ctx = newPage(); let page = 1;
  drawHeader(ctx, page);
  let y = 240;
  if (est.customer?.name || est.customer?.phone) {
    ctx.textAlign = 'left'; ctx.fillStyle = '#555'; ctx.font = `20px ${SANS}`;
    ctx.fillText(t('customer').toUpperCase(), M, y);
    ctx.fillStyle = '#111'; ctx.font = `600 24px ${SANS}`;
    ctx.fillText([est.customer.name, est.customer.phone].filter(Boolean).join('  ·  '), M, y + 34);
    y += 70;
  }
  if (res.items.length) y = drawTableHead(ctx, y);

  const rowLines = (r, i) => {
    const it = est.items[i];
    const extra = [];
    if (r.stoneWt.gt(0)) extra.push(`${t('gross')} ${wt(r.gross)} − ${t('stoneWt')} ${wt(r.stoneWt)}`);
    if (r.wastageG.gt(0)) extra.push(`${t('wastage')} ${wt(r.wastageG)} g → ${wt(r.chargeable)} g`);
    if (r.stones.gt(0)) extra.push(`${t('stones')} ${money(r.stones)}`);
    if (r.hallmark.gt(0)) extra.push(`${t('hallmark')} ${money(r.hallmark)}`);
    for (const o of it.others || []) if (D.from(o.amount || 0).gt(0)) extra.push(`${o.label || t('other')} ${money(D.from(o.amount))}`);
    if (r.makingDiscount.gt(0)) extra.push(`${t('makingDiscount')} −${money(r.makingDiscount)}`);
    return extra;
  };

  for (let i = 0; i < res.items.length; i++) {
    const r = res.items[i];
    const it = est.items[i];
    const extra = rowLines(r, i);
    ctx.font = `17px ${SANS}`;
    const extraLines = wrapLines(ctx, extra.join('  ·  '), cols[1].w + cols[2].w + cols[3].w + cols[4].w - 20);
    const h = 54 + extraLines.length * 24;
    if (y + h > PH - 520) { drawFooter(ctx); ctx = newPage(); page++; drawHeader(ctx, page); y = drawTableHead(ctx, 240); }
    const vals = [String(i + 1), it.name || it.category || t('item'), r.purityLabel, wt(r.net), money(r.rate, 0), money(r.metalValue), money(r.makingNet), money(r.subtotal)];
    let x = M;
    ctx.fillStyle = '#111'; ctx.font = `500 20px ${SANS}`;
    cols.forEach((col, ci) => {
      ctx.textAlign = col.a;
      ctx.font = `${ci === 1 || ci === 7 ? 600 : 400} 20px ${SANS}`;
      ctx.fillText(fitText(ctx, vals[ci], col.w - 16), col.a === 'right' ? x + col.w - 10 : x + 10, y + 34);
      x += col.w;
    });
    ctx.fillStyle = '#666'; ctx.font = `17px ${SANS}`; ctx.textAlign = 'left';
    extraLines.forEach((l, li) => ctx.fillText(l, M + cols[0].w + 10, y + 60 + li * 24));
    y += h;
    ctx.strokeStyle = '#e6dcc0'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(M, y); ctx.lineTo(PW - M, y); ctx.stroke();
  }

  // Summary block
  const sum = [];
  if (res.items.length) {
    sum.push([t('subtotal'), money(res.preDiscount)]);
    if (res.discount.gt(0)) sum.push([t('discount'), `−${money(res.discount)}`]);
    for (const l of res.gstLines) if (l.amount.gt(0)) sum.push([`GST ${l.rate.toString()}% · ${t('gst.' + l.key)}`, money(l.amount)]);
    if (!res.roundOff.isZero()) sum.push([t('roundOff'), money(res.roundOff)]);
    sum.push([t('total'), money(res.total), true]);
  }
  if (res.hasOldGold) {
    res.oldGold.forEach((o, i) => sum.push([`${est.oldGold.entries[i].label || t('oldGold')}: ${wt(o.weight)} g @ ${o.purity.toString()}%, −${o.deduction.toString()}% → ${wt(o.payableWeight)} g × ${money(o.rate, 0)}`, `−${money(o.value)}`]));
    sum.push([res.direction === 'receive' ? t('amountToReceive') : t('amountToPay'), money(res.payable), true]);
  }
  const needed = sum.length * 42 + 80;
  if (y + needed > PH - 140) { drawFooter(ctx); ctx = newPage(); page++; drawHeader(ctx, page); y = 240; }
  y += 30;
  for (const [k, v, strong] of sum) {
    if (strong) {
      ctx.fillStyle = '#111'; ctx.fillRect(PW / 2 - 40, y, PW / 2 - M + 40, 54);
      ctx.fillStyle = '#f6e7b4'; ctx.font = `700 26px ${SANS}`;
      ctx.textAlign = 'left'; ctx.fillText(k, PW / 2 - 20, y + 36);
      ctx.textAlign = 'right'; ctx.fillText(v, PW - M - 20, y + 36);
      y += 64;
    } else {
      ctx.fillStyle = '#444'; ctx.font = `19px ${SANS}`;
      ctx.textAlign = 'left'; ctx.fillText(fitText(ctx, k, PW / 2 + 40 - M - 180), M + 300, y + 28);
      ctx.textAlign = 'right'; ctx.fillStyle = '#111'; ctx.fillText(v, PW - M - 20, y + 28);
      y += 40;
    }
  }
  if (est.notes) {
    y += 20; ctx.textAlign = 'left'; ctx.fillStyle = '#555'; ctx.font = `19px ${SANS}`;
    wrapLines(ctx, `${t('notes')}: ${est.notes}`, PW - M * 2).slice(0, 4).forEach((l, i) => ctx.fillText(l, M, y + i * 26));
  }
  drawFooter(ctx);

  const jpegs = [];
  for (const cv of pages) {
    const b = await toBlob(cv, 'image/jpeg', 0.9);
    jpegs.push(new Uint8Array(await b.arrayBuffer()));
  }
  return new Blob([buildPdf(jpegs, PW, PH)], { type: 'application/pdf' });
}

// Minimal PDF 1.4 writer: one full-page JPEG per page.
export function buildPdf(jpegs, pxW, pxH) {
  const enc = new TextEncoder();
  const ptW = 595.28, ptH = 841.89;
  const chunks = [];
  const offsets = [];
  let len = 0;
  const push = data => { const b = typeof data === 'string' ? enc.encode(data) : data; chunks.push(b); len += b.length; };
  const obj = (n, body) => { offsets[n] = len; push(`${n} 0 obj\n`); body(); push('\nendobj\n'); };

  push('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');
  const nPages = jpegs.length;
  // 1 catalog, 2 pages, then per page: page, contents, image
  const pageIds = jpegs.map((_, i) => 3 + i * 3);
  obj(1, () => push('<< /Type /Catalog /Pages 2 0 R >>'));
  obj(2, () => push(`<< /Type /Pages /Count ${nPages} /Kids [${pageIds.map(id => `${id} 0 R`).join(' ')}] >>`));
  jpegs.forEach((jpg, i) => {
    const pid = pageIds[i], cid = pid + 1, iid = pid + 2;
    obj(pid, () => push(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${ptW} ${ptH}] /Resources << /XObject << /Im${i} ${iid} 0 R >> >> /Contents ${cid} 0 R >>`));
    const content = `q ${ptW} 0 0 ${ptH} 0 0 cm /Im${i} Do Q`;
    obj(cid, () => push(`<< /Length ${content.length} >>\nstream\n${content}\nendstream`));
    obj(iid, () => {
      push(`<< /Type /XObject /Subtype /Image /Width ${pxW} /Height ${pxH} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpg.length} >>\nstream\n`);
      push(jpg);
      push('\nendstream');
    });
  });
  const xref = len;
  const count = 3 + nPages * 3;
  let x = `xref\n0 ${count}\n0000000000 65535 f \n`;
  for (let n = 1; n < count; n++) x += `${String(offsets[n]).padStart(10, '0')} 00000 n \n`;
  push(x);
  push(`trailer\n<< /Size ${count} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`);
  const out = new Uint8Array(len);
  let o = 0;
  for (const c of chunks) { out.set(c, o); o += c.length; }
  return out;
}

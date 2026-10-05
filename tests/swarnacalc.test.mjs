// Run with: node --test tests/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { D, fmt } from '../public/swarnacalc/js/decimal.js';
import { defaultSettings, newEstimate, newItem } from '../public/swarnacalc/js/config.js';
import { calcItem, calcEstimate, reverseCalc, fairCheck, toGrams } from '../public/swarnacalc/js/engine.js';

const cfg = defaultSettings();
const s = d => d.toFixed(2);

test('decimal math has no floating point error', () => {
  assert.equal(D.from('0.1').add('0.2').toString(), '0.3');
  assert.equal(D.from('10.26').mul('6800').toFixed(2), '69768.00');
  assert.equal(D.from('2.675').round(2).toString(), '2.68');
  assert.equal(D.from('76799.5').roundTo(1).toString(), '76800');
  assert.equal(D.from('76794.99').roundTo(10).toString(), '76790');
  assert.equal(D.parse('abc'), null);
  assert.equal(D.parse('१२.५').toString(), '12.5'); // Devanagari digits
});

test('Indian number formatting', () => {
  assert.equal(fmt('125000', { dp: 0, symbol: '₹' }), '₹1,25,000');
  assert.equal(fmt('12345678.5', { dp: 2 }), '1,23,45,678.50');
  assert.equal(fmt('999', { dp: 0 }), '999');
  assert.equal(fmt('-1500', { dp: 0, symbol: '₹' }), '−₹1,500');
});

test('unit conversion (tola = 11.664 g)', () => {
  assert.equal(toGrams('1', 'tola').toString(), '11.664');
  assert.equal(toGrams('500', 'mg').toString(), '0.5');
  assert.equal(toGrams('1', 'ct').toString(), '0.2');
});

// Spec example: 22K, gross 10 g, stone 0.5 g, rate ₹6,800/g (22K), wastage 8%,
// making ₹500/g, hallmark ₹45, GST 3%.
test('spec example — full breakdown', () => {
  const est = newEstimate(cfg, 'buy');
  Object.assign(est.items[0], {
    name: 'Lakshmi Haar', purityKey: '22K', rate: '6800', rateBasis: 'purity',
    gross: '10', stoneWt: '0.5', wastageType: 'pct', wastage: '8',
    makingType: 'perGram', making: '500', hallmarkFee: '45',
  });
  const r = calcEstimate(cfg, est);
  const it = r.items[0];
  assert.equal(r.valid, true);
  assert.equal(it.net.toFixed(3), '9.500');          // 10 − 0.5
  assert.equal(it.wastageG.toFixed(3), '0.760');     // 8% of 9.5
  assert.equal(it.chargeable.toFixed(3), '10.260');  // 9.5 + 0.76
  assert.equal(s(it.metalValue), '69768.00');        // 10.26 × 6800
  assert.equal(s(it.making), '4750.00');             // 9.5 × 500
  assert.equal(s(it.hallmark), '45.00');
  assert.equal(s(r.subtotal), '74563.00');
  assert.equal(s(r.gst), '2236.89');                 // 3% of 74,563
  assert.equal(s(r.unrounded), '76799.89');
  assert.equal(s(r.total), '76800.00');              // nearest ₹1
  assert.equal(s(r.roundOff), '0.11');
});

test('rate entered for 24K converts to purity', () => {
  const item = newItem(cfg, { purityKey: '22K', rate: '7500', rateBasis: 'pure', gross: '1', wastage: '0', making: '0', hallmarkFee: '0' });
  const r = calcItem(cfg, item);
  // 7500 × 91.6 / 99.9
  assert.equal(s(r.rate), '6876.88');
});

test('making as % and flat, with making discount', () => {
  const pct = calcItem(cfg, newItem(cfg, { rate: '1000', gross: '10', wastage: '0', makingType: 'pct', making: '12', discountMakingType: 'pct', discountMaking: '50', hallmarkFee: '0' }));
  assert.equal(s(pct.metalValue), '10000.00');
  assert.equal(s(pct.making), '1200.00');
  assert.equal(s(pct.makingNet), '600.00');
  const flat = calcItem(cfg, newItem(cfg, { rate: '1000', gross: '10', wastage: '0', makingType: 'flat', making: '1500', discountMakingType: 'amt', discountMaking: '9999', hallmarkFee: '0' }));
  assert.equal(s(flat.makingNet), '0.00'); // discount capped at making
});

test('validation: stone weight cannot exceed gross', () => {
  const r = calcItem(cfg, newItem(cfg, { rate: '1000', gross: '2', stoneWt: '3' }));
  assert.equal(r.valid, false);
  assert.ok(r.errors.some(e => e.key === 'err.stoneExceedsGross'));
  const r2 = calcItem(cfg, newItem(cfg, { rate: 'abc', gross: '2' }));
  assert.ok(r2.errors.some(e => e.key === 'err.number'));
});

test('multi-item estimate with stones, other charges, total discount and per-component GST', () => {
  const est = newEstimate(cfg, 'buy');
  est.items = [
    newItem(cfg, { rate: '1000', gross: '10', wastage: '0', makingType: 'flat', making: '1000', hallmarkFee: '45', stones: [{ label: 'Ruby', amount: '2000' }] }),
    newItem(cfg, { rate: '1000', gross: '5', wastage: '0', makingType: 'flat', making: '500', hallmarkFee: '45', others: [{ label: 'Polish', amount: '100' }] }),
  ];
  est.gst = { metal: '3', making: '3', hallmark: '3', stones: '3', other: '18' };
  est.discountTotal = { type: 'amt', value: '0' };
  est.rounding = 'none';
  const r = calcEstimate(cfg, est);
  assert.equal(s(r.preDiscount), '18690.00'); // 15000 + 1500 + 2000 + 90 + 100
  // GST: 3% × (15000 + 1500 + 90 + 2000) + 18% × 100 = 557.70 + 18
  assert.equal(s(r.gst), '575.70');
  assert.equal(s(r.total), '19265.70');

  est.discountTotal = { type: 'pct', value: '10' };
  const r2 = calcEstimate(cfg, est);
  assert.equal(s(r2.discount), '1869.00');
  assert.equal(s(r2.subtotal), '16821.00');
  assert.equal(s(r2.gst), '518.13'); // GST on 90% of each component
});

test('old gold exchange deducted after GST; sell mode receives', () => {
  const est = newEstimate(cfg, 'exchange');
  Object.assign(est.items[0], { rate: '6800', gross: '10', stoneWt: '0', wastage: '0', makingType: 'flat', making: '0', hallmarkFee: '0' });
  Object.assign(est.oldGold.entries[0], { weight: '5', purity: '91.6', deduction: '2', rate: '7000', rateBasis: 'fine' });
  const r = calcEstimate(cfg, est);
  assert.equal(s(r.total), '70040.00'); // 68000 + 3%
  // fine 4.58 g, loss 0.092 g → 4.488 g × 7000
  assert.equal(s(r.oldValue), '31416.00');
  assert.equal(s(r.payable), '38624.00');
  assert.equal(r.direction, 'pay');

  const sell = newEstimate(cfg, 'sell');
  Object.assign(sell.oldGold.entries[0], { weight: '10', purity: '91.6', deduction: '0', rate: '7000' });
  const rs = calcEstimate(cfg, sell);
  assert.equal(rs.direction, 'receive');
  assert.equal(s(rs.payable), '64120.00');
});

test('reverse calc: budget → grams', () => {
  const est = newEstimate(cfg, 'reverse');
  Object.assign(est.items[0], { rate: '6800', stoneWt: '', wastage: '8', makingType: 'perGram', making: '500', hallmarkFee: '45' });
  const rv = reverseCalc(cfg, est, '50000');
  assert.ok(rv.affordable);
  const pay = rv.result.payable;
  assert.ok(pay.lte('50000'), `payable ${pay} must be within budget`);
  // one more milligram must exceed the budget
  const over = calcEstimate(cfg, { ...est, mode: 'buy', items: [{ ...est.items[0], gross: rv.net.add('0.001').toString() }] });
  assert.ok(over.payable.gt('50000'));
  assert.equal(rv.net.toFixed(3), '6.182'); // (50000 − 46.35) ÷ 8079.32 per g
});

test('fair price check flags high making', () => {
  const item = newItem(cfg, { rate: '1000', gross: '10', wastage: '20', makingType: 'pct', making: '30' });
  const flags = fairCheck(cfg, item, calcItem(cfg, item));
  assert.ok(flags.some(f => f.kind === 'makingPct' && f.level === 'veryHigh'));
  assert.ok(flags.some(f => f.kind === 'wastagePct' && f.level !== 'ok'));
});

test('voice parser: English, Hindi, Kannada', async () => {
  const { parseVoice } = await import('../public/swarnacalc/js/ai.js');
  const en = parseVoice('22 carat, 10 gram, making 12 percent');
  assert.deepEqual([en.purityKey, en.gross, en.makingType, en.making], ['22K', '10', 'pct', '12']);
  const hi = parseVoice('22 कैरेट 10 ग्राम मेकिंग 12 प्रतिशत');
  assert.deepEqual([hi.purityKey, hi.gross, hi.makingType, hi.making], ['22K', '10', 'pct', '12']);
  const kn = parseVoice('ಇಪ್ಪತ್ತೆರಡು ಕ್ಯಾರೆಟ್ ಹತ್ತು ಗ್ರಾಂ ಮೇಕಿಂಗ್ 12 ಪರ್ಸೆಂಟ್');
  assert.deepEqual([kn.purityKey, kn.gross, kn.making], ['22K', '10', '12']);
  const st = parseVoice('18 carat 5.5 gram stone 0.5 gram wastage 8 percent rate 6500');
  assert.deepEqual([st.gross, st.stoneWt, st.wastage, st.rate], ['5.5', '0.5', '8', '6500']);
});

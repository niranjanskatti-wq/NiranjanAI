// Default settings. Everything here is user-editable in Settings: lists can be
// added to, edited and deleted; values are stored on the device only.

export const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 8);

export const DEFAULT_METALS = [
  {
    id: 'gold', name: 'Gold', refPurity: '99.9',
    purities: [
      { key: '24K', label: '24K (99.9%)', pct: '99.9' },
      { key: '22K', label: '22K (91.6%)', pct: '91.6' },
      { key: '20K', label: '20K (83.3%)', pct: '83.3' },
      { key: '18K', label: '18K (75%)', pct: '75' },
      { key: '14K', label: '14K (58.5%)', pct: '58.5' },
      { key: '9K', label: '9K (37.5%)', pct: '37.5' },
    ],
  },
  {
    id: 'silver', name: 'Silver', refPurity: '99.9',
    purities: [
      { key: 'S999', label: 'Silver 999', pct: '99.9' },
      { key: 'S925', label: 'Silver 925 (Sterling)', pct: '92.5' },
      { key: 'S800', label: 'Silver 800', pct: '80' },
    ],
  },
  {
    id: 'platinum', name: 'Platinum', refPurity: '95',
    purities: [
      { key: 'Pt950', label: 'Platinum 950', pct: '95' },
      { key: 'Pt900', label: 'Platinum 900', pct: '90' },
    ],
  },
];

export const DEFAULT_CATEGORIES = ['Ring', 'Chain', 'Bangle', 'Necklace', 'Earrings', 'Coin', 'Bar', 'Pendant', 'Custom'];

export const FIELD_KEYS = [
  'photo', 'category', 'stoneWt', 'wastage', 'making', 'discountMaking', 'stones',
  'hallmark', 'others', 'discountTotal', 'customer', 'notes',
];

export const SHARE_FIELD_KEYS = [
  'shop', 'customer', 'item', 'weights', 'rate', 'wastage', 'metal', 'making', 'stones',
  'hallmark', 'others', 'discount', 'gst', 'total', 'oldGold', 'date', 'disclaimer',
];

export function defaultSettings() {
  return {
    version: 1,
    language: 'en',
    theme: 'dark', // dark | light | auto
    fontScale: 1,
    haptics: true,
    numberStyle: 'indian', // indian | intl
    currencySymbol: '₹',
    weightUnit: 'g',
    tolaGrams: '11.664',
    rounding: '1', // none | 1 | 10
    rateBasis: 'purity', // purity | pure
    metals: JSON.parse(JSON.stringify(DEFAULT_METALS)),
    categories: [...DEFAULT_CATEGORIES],
    rates: {}, // purityKey -> { rate, updatedAt }
    gst: { metal: '3', making: '3', hallmark: '3', stones: '0', other: '0' },
    defaults: {
      metal: 'gold', purityKey: '22K', category: 'Necklace',
      wastageType: 'pct', wastage: '8',
      makingType: 'perGram', making: '500', makingWeightBasis: 'net',
      hallmarkFee: '45',
    },
    presets: [
      { id: 'p1', name: 'Branded store · 12% making', makingType: 'pct', making: '12', wastageType: 'pct', wastage: '0', hallmarkFee: '45' },
      { id: 'p2', name: 'Local jeweller · 8% VA', makingType: 'perGram', making: '350', wastageType: 'pct', wastage: '8', hallmarkFee: '45' },
      { id: 'p3', name: 'Coin / Bar', makingType: 'pct', making: '3', wastageType: 'pct', wastage: '0', hallmarkFee: '0' },
    ],
    fair: { makingPctMax: '15', wastagePctMax: '12', makingPerGramMax: '900' },
    hiddenFields: [], // keys from FIELD_KEYS
    shareFields: [...SHARE_FIELD_KEYS],
    profile: { name: '', address: '', phone: '', gstin: '', logo: null, footer: '' },
    ai: { enabled: false, apiKey: '', model: 'claude-opus-5-5', voiceLang: 'en-IN' },
    liveRate: { url: '', path: '', perGrams: '1', purityKey: '24K' },
    disclaimer: 'Estimate only. Final price depends on the jeweller, BIS hallmarking and current GST rules.',
  };
}

// Deep-merge saved settings over defaults so new options appear after updates.
export function mergeSettings(saved) {
  const base = defaultSettings();
  if (!saved || typeof saved !== 'object') return base;
  const out = { ...base, ...saved };
  for (const k of ['gst', 'defaults', 'fair', 'profile', 'ai', 'liveRate']) {
    out[k] = { ...base[k], ...(saved[k] || {}) };
  }
  if (!Array.isArray(out.metals) || !out.metals.length) out.metals = base.metals;
  if (!Array.isArray(out.categories)) out.categories = base.categories;
  if (!Array.isArray(out.presets)) out.presets = base.presets;
  if (!Array.isArray(out.hiddenFields)) out.hiddenFields = [];
  if (!Array.isArray(out.shareFields)) out.shareFields = base.shareFields;
  return out;
}

export function newItem(settings, overrides = {}) {
  const d = settings.defaults;
  const rate = settings.rates[d.purityKey]?.rate ?? '';
  return {
    id: uid(),
    name: '',
    category: d.category,
    metal: d.metal,
    purityKey: d.purityKey,
    customPurity: '',
    rate,
    rateBasis: settings.rateBasis,
    unit: settings.weightUnit,
    gross: '',
    stoneWt: '',
    stoneUnit: settings.weightUnit,
    wastageType: d.wastageType,
    wastage: d.wastage,
    makingType: d.makingType,
    making: d.making,
    makingWeightBasis: d.makingWeightBasis,
    discountMakingType: 'pct',
    discountMaking: '',
    stones: [],
    hallmarkFee: d.hallmarkFee,
    pieces: '1',
    others: [],
    photo: null,
    ...overrides,
  };
}

export function newOldGold(settings) {
  return {
    id: uid(), label: 'Old gold', weight: '', unit: settings.weightUnit,
    purity: '91.6', deduction: '2', rate: settings.rates['24K']?.rate ?? '', rateBasis: 'fine',
  };
}

export function newEstimate(settings, mode = 'buy') {
  const est = {
    id: uid(),
    mode, // buy | sell | exchange | coin | reverse
    jeweller: settings.profile.name || '',
    customer: { name: '', phone: '' },
    items: [],
    oldGold: { enabled: mode === 'exchange' || mode === 'sell', entries: [] },
    discountTotal: { type: 'pct', value: '' },
    gst: { ...settings.gst },
    rounding: settings.rounding,
    budget: '',
    notes: '',
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };
  if (mode !== 'sell') {
    est.items.push(newItem(settings, mode === 'coin'
      ? { category: 'Coin', purityKey: '24K', rate: settings.rates['24K']?.rate ?? '', wastage: '0', makingType: 'pct', making: '3' }
      : {}));
  }
  if (est.oldGold.enabled) est.oldGold.entries.push(newOldGold(settings));
  return est;
}

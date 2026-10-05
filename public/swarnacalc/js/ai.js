// Optional online features. None of these are needed for the calculator to
// work; each one fails gracefully when offline.

const SDK_URL = 'https://cdn.jsdelivr.net/npm/@anthropic-ai/sdk/+esm';

// ---------------------------------------------------------------------------
// Voice input (Web Speech API) — English, Kannada, Hindi
// ---------------------------------------------------------------------------
export function voiceSupported() {
  return !!(window.SwarnaAndroid || window.SpeechRecognition || window.webkitSpeechRecognition);
}

let voiceSeq = 0;
export function listen(lang = 'en-IN') {
  // Android app: use the phone's own speech recogniser (works offline when
  // the language pack is downloaded on the phone).
  if (window.SwarnaAndroid) {
    return new Promise((resolve, reject) => {
      const id = `v${++voiceSeq}`;
      window.__swarnaVoice = (cbId, text, err) => {
        if (cbId !== id) return;
        if (text) resolve(text); else reject(new Error(err || 'no-match'));
      };
      window.SwarnaAndroid.startVoice(lang, id);
    });
  }
  return new Promise((resolve, reject) => {
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) { reject(new Error('voice-unsupported')); return; }
    const rec = new SR();
    rec.lang = lang;
    rec.interimResults = false;
    rec.maxAlternatives = 1;
    rec.onresult = e => resolve(e.results[0][0].transcript);
    rec.onerror = e => reject(new Error(e.error || 'voice-error'));
    rec.onnomatch = () => reject(new Error('no-match'));
    rec.start();
  });
}

// Normalise Devanagari / Kannada digits and common number words.
const NUM_WORDS = {
  // English
  zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10,
  eleven: 11, twelve: 12, thirteen: 13, fourteen: 14, fifteen: 15, sixteen: 16, eighteen: 18, twenty: 20,
  'twenty two': 22, 'twenty four': 24,
  // Hindi
  'एक': 1, 'दो': 2, 'तीन': 3, 'चार': 4, 'पांच': 5, 'पाँच': 5, 'छह': 6, 'सात': 7, 'आठ': 8, 'नौ': 9, 'दस': 10,
  'बारह': 12, 'चौदह': 14, 'अठारह': 18, 'बीस': 20, 'बाईस': 22, 'चौबीस': 24,
  // Kannada
  'ಒಂದು': 1, 'ಎರಡು': 2, 'ಮೂರು': 3, 'ನಾಲ್ಕು': 4, 'ಐದು': 5, 'ಆರು': 6, 'ಏಳು': 7, 'ಎಂಟು': 8, 'ಒಂಬತ್ತು': 9, 'ಹತ್ತು': 10,
  'ಹನ್ನೆರಡು': 12, 'ಹದಿನಾಲ್ಕು': 14, 'ಹದಿನೆಂಟು': 18, 'ಇಪ್ಪತ್ತು': 20, 'ಇಪ್ಪತ್ತೆರಡು': 22, 'ಇಪ್ಪತ್ನಾಲ್ಕು': 24,
};

export function normaliseSpeech(text) {
  let s = ` ${String(text).toLowerCase()} `
    .replace(/[०-९]/g, c => String(c.charCodeAt(0) - 0x0966))
    .replace(/[೦-೯]/g, c => String(c.charCodeAt(0) - 0x0CE6))
    .replace(/(\d),(\d)/g, '$1$2')
    .replace(/\b(point|dot)\b|पॉइंट|दशमलव|ಪಾಯಿಂಟ್/g, '.')
    .replace(/(\d)\s*\.\s*(\d)/g, '$1.$2');
  const words = Object.keys(NUM_WORDS).sort((a, b) => b.length - a.length);
  for (const w of words) s = s.split(` ${w} `).join(` ${NUM_WORDS[w]} `);
  return s;
}

// "22 carat, 10 gram, making 12 percent" → field updates (strings).
export function parseVoice(text) {
  const s = normaliseSpeech(text);
  const out = {};
  const N = '(\\d+(?:\\.\\d+)?)';
  const pct = '(?:%|percent|per cent|प्रतिशत|परसेंट|फीसदी|ಶೇಕಡ|ಶೇ|ಪರ್ಸೆಂಟ್)';
  const gram = '(?:g|gm|gms|gram|grams|ग्राम|ಗ್ರಾಂ|ಗ್ರಾಮ್)';
  const carat = '(?:k|kt|carat|karat|carats|कैरेट|कैरट|ಕ್ಯಾರೆಟ್|ಕ್ಯಾರಟ್)';
  const m = (re) => s.match(new RegExp(re, 'i'));
  let r;
  if ((r = m(`${N}\\s*${carat}`))) out.purityKey = `${r[1]}K`;
  if ((r = m(`(?:silver|चांदी|ಬೆಳ್ಳಿ)`))) out.metal = 'silver';
  if ((r = m(`(?:platinum|प्लैटिनम|ಪ್ಲಾಟಿನಂ)`))) out.metal = 'platinum';
  if ((r = m(`(?:stone|stones|स्टोन|पत्थर|ಕಲ್ಲು|ಸ್ಟೋನ್)\\D{0,15}?${N}\\s*${gram}`)) || (r = m(`${N}\\s*${gram}\\s*(?:stone|स्टोन|ಕಲ್ಲು|ಸ್ಟೋನ್)`))) out.stoneWt = r[1];
  if ((r = m(`${N}\\s*(?:tola|तोला|ತೊಲ)`))) { out.gross = r[1]; out.unit = 'tola'; }
  // gross = first "<n> gram" that is not the stone weight
  const grams = [...s.matchAll(new RegExp(`${N}\\s*${gram}`, 'gi'))].map(x => x[1]);
  const g = grams.find(x => x !== out.stoneWt);
  if (g && !out.gross) out.gross = g;
  if ((r = m(`(?:making|मेकिंग|मजदूरी|ಮೇಕಿಂಗ್|ಮಜೂರಿ)\\D{0,15}?${N}\\s*${pct}`))) { out.makingType = 'pct'; out.making = r[1]; }
  else if ((r = m(`(?:making|मेकिंग|मजदूरी|ಮೇಕಿಂಗ್|ಮಜೂರಿ)\\D{0,15}?${N}\\s*(?:per|प्रति|ಪ್ರತಿ)\\s*${gram}`))) { out.makingType = 'perGram'; out.making = r[1]; }
  else if ((r = m(`(?:making|मेकिंग|मजदूरी|ಮೇಕಿಂಗ್|ಮಜೂರಿ)\\D{0,15}?${N}`))) { out.makingType = 'flat'; out.making = r[1]; }
  if ((r = m(`(?:wastage|waste|va|value addition|वेस्टेज|घटाई|ವೇಸ್ಟೇಜ್|ತರುಗು)\\D{0,15}?${N}\\s*${pct}?`))) { out.wastageType = 'pct'; out.wastage = r[1]; }
  if ((r = m(`(?:rate|price|भाव|रेट|ದರ|ರೇಟ್)\\D{0,15}?${N}`))) out.rate = r[1];
  if ((r = m(`(?:hallmark|huid|हॉलमार्क|ಹಾಲ್‌?ಮಾರ್ಕ್)\\D{0,15}?${N}`))) out.hallmarkFee = r[1];
  return out;
}

// ---------------------------------------------------------------------------
// Claude (user's own API key, stored on device). Loaded lazily from CDN only
// when an AI feature is used, so offline use never depends on it.
// ---------------------------------------------------------------------------
let clientPromise = null;
let clientKey = null;

async function getClient(apiKey) {
  if (!navigator.onLine) throw new Error('offline');
  if (!apiKey) throw new Error('no-key');
  if (!clientPromise || clientKey !== apiKey) {
    clientKey = apiKey;
    clientPromise = import(/* @vite-ignore */ SDK_URL).then(mod => {
      const Anthropic = mod.default || mod.Anthropic;
      return new Anthropic({ apiKey, dangerouslyAllowBrowser: true });
    });
  }
  return clientPromise;
}

const ITEM_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  properties: {
    shopName: { type: 'string' },
    customerName: { type: 'string' },
    items: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          name: { type: 'string' },
          metal: { type: 'string', enum: ['gold', 'silver', 'platinum'] },
          purity: { type: 'string', description: 'e.g. 22K, 18K, 24K, 925' },
          grossWeightGrams: { type: 'number' },
          stoneWeightGrams: { type: 'number' },
          ratePerGram: { type: 'number' },
          wastagePercent: { type: 'number' },
          wastageGrams: { type: 'number' },
          makingPerGram: { type: 'number' },
          makingPercent: { type: 'number' },
          makingFlat: { type: 'number' },
          stoneCharges: { type: 'number' },
          hallmarkCharges: { type: 'number' },
        },
        required: ['name', 'metal', 'purity', 'grossWeightGrams', 'stoneWeightGrams', 'ratePerGram',
          'wastagePercent', 'wastageGrams', 'makingPerGram', 'makingPercent', 'makingFlat', 'stoneCharges', 'hallmarkCharges'],
      },
    },
    gstPercent: { type: 'number' },
    billTotal: { type: 'number' },
  },
  required: ['shopName', 'customerName', 'items', 'gstPercent', 'billTotal'],
};

function textOf(response) {
  if (response.stop_reason === 'refusal') throw new Error('refused');
  const block = response.content.find(b => b.type === 'text');
  if (!block) throw new Error('empty');
  return JSON.parse(block.text);
}

// Scan a jeweller's bill photo → structured fields.
export async function scanBill(settings, dataUrl) {
  const client = await getClient(settings.ai.apiKey);
  const [, mediaType, data] = /^data:(image\/[a-z+]+);base64,(.*)$/.exec(dataUrl) || [];
  if (!data) throw new Error('bad-image');
  const response = await client.beta.messages.create({
    model: settings.ai.model || 'claude-opus-5-5',
    // Server-side refusal fallback: a declined request is re-run on a fallback model.
    betas: ['server-side-fallback-2026-07-01'],
    fallbacks: 'default',
    max_tokens: 16000,
    output_config: { effort: 'low', format: { type: 'json_schema', schema: ITEM_SCHEMA } },
    messages: [{
      role: 'user',
      content: [
        { type: 'image', source: { type: 'base64', media_type: mediaType, data } },
        { type: 'text', text: 'This is a photo of an Indian jeweller\'s bill or estimate. Extract every jewellery line item. Weights in grams (convert mg or tola, 1 tola = 11.664 g). Use 0 for any value not printed on the bill. The bill may be in English, Kannada or Hindi.' },
      ],
    }],
  });
  return textOf(response);
}

// Free-text / voice transcript → fields, when the offline parser finds nothing.
export async function parseWithClaude(settings, transcript) {
  const client = await getClient(settings.ai.apiKey);
  const response = await client.beta.messages.create({
    model: settings.ai.model || 'claude-opus-5-5',
    // Server-side refusal fallback: a declined request is re-run on a fallback model.
    betas: ['server-side-fallback-2026-07-01'],
    fallbacks: 'default',
    max_tokens: 4000,
    output_config: { effort: 'low', format: { type: 'json_schema', schema: ITEM_SCHEMA } },
    messages: [{
      role: 'user',
      content: `A jewellery buyer said (in English, Kannada or Hindi): "${transcript}". Extract one jewellery item. Use 0 for anything not mentioned, empty strings for unknown names.`,
    }],
  });
  return textOf(response);
}

// Map Claude's structured item onto a SwarnaCalc item patch.
export function aiItemToPatch(ai) {
  const p = {};
  const set = (k, v) => { if (v !== undefined && v !== null && v !== 0 && v !== '') p[k] = String(v); };
  set('name', ai.name);
  if (ai.metal) p.metal = ai.metal;
  if (ai.purity) {
    const m = /(\d+)\s*k/i.exec(ai.purity);
    if (m) p.purityKey = `${m[1]}K`;
    else if (/999/.test(ai.purity)) p.purityKey = 'S999';
    else if (/925/.test(ai.purity)) p.purityKey = 'S925';
  }
  set('gross', ai.grossWeightGrams);
  set('stoneWt', ai.stoneWeightGrams);
  set('rate', ai.ratePerGram);
  if (ai.wastagePercent) { p.wastageType = 'pct'; set('wastage', ai.wastagePercent); }
  else if (ai.wastageGrams) { p.wastageType = 'g'; set('wastage', ai.wastageGrams); }
  if (ai.makingPerGram) { p.makingType = 'perGram'; set('making', ai.makingPerGram); }
  else if (ai.makingPercent) { p.makingType = 'pct'; set('making', ai.makingPercent); }
  else if (ai.makingFlat) { p.makingType = 'flat'; set('making', ai.makingFlat); }
  if (ai.stoneCharges) p.stones = [{ id: Math.random().toString(36).slice(2), label: 'Stones', amount: String(ai.stoneCharges) }];
  if (ai.hallmarkCharges) set('hallmarkFee', ai.hallmarkCharges);
  if (p.gross || p.rate) p.unit = 'g';
  return p;
}

// ---------------------------------------------------------------------------
// Live rate (user-configured JSON endpoint). Never required.
// ---------------------------------------------------------------------------
export async function fetchLiveRate(liveRate) {
  if (!navigator.onLine) throw new Error('offline');
  if (!liveRate.url) throw new Error('no-url');
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 8000);
  try {
    const res = await fetch(liveRate.url, { signal: ctrl.signal, cache: 'no-store' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    let v = json;
    for (const part of String(liveRate.path || '').split('.').filter(Boolean)) v = v?.[part];
    const num = Number(v);
    if (!Number.isFinite(num) || num <= 0) throw new Error('bad-value');
    return num / (Number(liveRate.perGrams) || 1);
  } finally {
    clearTimeout(timer);
  }
}

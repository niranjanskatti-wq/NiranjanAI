// On-device storage (IndexedDB). No account, no server.
// Stores: kv (settings, drafts), estimates, rateLog.

const DB_NAME = 'swarnacalc';
const DB_VERSION = 1;
let dbp = null;

function open() {
  if (dbp) return dbp;
  dbp = new Promise((resolve, reject) => {
    if (!('indexedDB' in self)) { reject(new Error('IndexedDB unavailable')); return; }
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains('kv')) db.createObjectStore('kv');
      if (!db.objectStoreNames.contains('estimates')) {
        const s = db.createObjectStore('estimates', { keyPath: 'id' });
        s.createIndex('updatedAt', 'updatedAt');
      }
      if (!db.objectStoreNames.contains('rateLog')) {
        const s = db.createObjectStore('rateLog', { keyPath: 'id' });
        s.createIndex('at', 'at');
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
  return dbp;
}

function tx(store, mode, fn) {
  return open().then(db => new Promise((resolve, reject) => {
    const t = db.transaction(store, mode);
    const s = t.objectStore(store);
    let result;
    Promise.resolve(fn(s)).then(r => { result = r; });
    t.oncomplete = () => resolve(result instanceof IDBRequest ? result.result : result);
    t.onerror = () => reject(t.error);
    t.onabort = () => reject(t.error);
  }));
}

const reqP = r => new Promise((res, rej) => { r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); });

// In-memory fallback (private mode / very old browsers) so the app still works.
const mem = { kv: new Map(), estimates: new Map(), rateLog: new Map() };
let useMem = false;
async function guard(fn, fallback) {
  if (useMem) return fallback();
  try { return await fn(); } catch (e) { console.warn('IndexedDB failed, using memory', e); useMem = true; return fallback(); }
}

export const kv = {
  get: key => guard(() => tx('kv', 'readonly', s => s.get(key)), () => mem.kv.get(key)),
  set: (key, val) => guard(() => tx('kv', 'readwrite', s => { s.put(val, key); }), () => { mem.kv.set(key, val); }),
  del: key => guard(() => tx('kv', 'readwrite', s => { s.delete(key); }), () => { mem.kv.delete(key); }),
};

function storeApi(name) {
  return {
    all: () => guard(() => open().then(db => reqP(db.transaction(name).objectStore(name).getAll())), () => [...mem[name].values()]),
    get: id => guard(() => tx(name, 'readonly', s => s.get(id)), () => mem[name].get(id)),
    put: obj => guard(() => tx(name, 'readwrite', s => { s.put(obj); }), () => { mem[name].set(obj.id, obj); }),
    del: id => guard(() => tx(name, 'readwrite', s => { s.delete(id); }), () => { mem[name].delete(id); }),
    clear: () => guard(() => tx(name, 'readwrite', s => { s.clear(); }), () => { mem[name].clear(); }),
  };
}

export const estimates = storeApi('estimates');
export const rateLog = storeApi('rateLog');

export async function exportAll() {
  return {
    app: 'SwarnaCalc',
    format: 1,
    exportedAt: new Date().toISOString(),
    settings: await kv.get('settings'),
    estimates: await estimates.all(),
    rateLog: await rateLog.all(),
  };
}

export async function importAll(data, { replace = true } = {}) {
  if (!data || data.app !== 'SwarnaCalc') throw new Error('Not a SwarnaCalc backup file');
  if (replace) { await estimates.clear(); await rateLog.clear(); }
  if (data.settings) await kv.set('settings', data.settings);
  for (const e of data.estimates || []) await estimates.put(e);
  for (const r of data.rateLog || []) await rateLog.put(r);
}

export async function requestPersistence() {
  try { if (navigator.storage?.persist) await navigator.storage.persist(); } catch { /* optional */ }
}

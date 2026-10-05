// SwarnaCalc service worker: precache the whole app so it runs 100% offline.
// Bump VERSION whenever any file below changes.
const VERSION = 'swarnacalc-v1';
const ASSETS = [
  './',
  './index.html',
  './manifest.webmanifest',
  './css/app.css',
  './js/app.js',
  './js/decimal.js',
  './js/config.js',
  './js/engine.js',
  './js/store.js',
  './js/i18n.js',
  './js/share.js',
  './js/ai.js',
  './icons/icon.svg',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/maskable-512.png',
];

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(VERSION);
    // './' may not resolve on every static host — cache what we can, require the rest.
    await cache.addAll(ASSETS.filter(a => a !== './'));
    try { await cache.add('./'); } catch { /* directory index not served */ }
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) if (key !== VERSION) await caches.delete(key);
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return; // AI / live-rate calls go straight to network

  if (req.mode === 'navigate') {
    // App shell: cache first so it opens instantly offline; refresh in background.
    event.respondWith((async () => {
      const cache = await caches.open(VERSION);
      const cached = await cache.match('./index.html');
      const network = fetch(req).then(res => {
        if (res.ok && url.pathname.endsWith('index.html')) cache.put('./index.html', res.clone());
        return res;
      }).catch(() => null);
      return cached || (await network) || new Response('Offline', { status: 503 });
    })());
    return;
  }

  // Static assets: cache first, then network (and cache the result).
  event.respondWith((async () => {
    const cache = await caches.open(VERSION);
    const cached = await cache.match(req, { ignoreSearch: true });
    if (cached) return cached;
    try {
      const res = await fetch(req);
      if (res.ok) cache.put(req, res.clone());
      return res;
    } catch {
      return new Response('', { status: 504 });
    }
  })());
});

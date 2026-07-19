// Service worker — installable + offline for the APP SHELL only.
// IMPORTANT: it must NEVER cache Supabase/API responses, or saved data won't
// show up. We only ever touch same-origin static files here.
const CACHE = 'spwh-v4';
const ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/apple-touch-icon.png'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  // Wipe ALL old caches (including any stale cached API responses from earlier versions).
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.map(k => caches.delete(k))))
      .then(() => caches.open(CACHE).then(c => c.addAll(ASSETS)))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // Only handle GET requests to OUR OWN origin (the app files).
  // Cross-origin requests (Supabase database/auth) go straight to the network,
  // never cached — so your data is always live.
  if (e.request.method !== 'GET' || url.origin !== self.location.origin) return;

  // Network-first for app files so updates always load; fall back to cache offline.
  e.respondWith(
    fetch(e.request).then(resp => {
      const copy = resp.clone();
      caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
      return resp;
    }).catch(() => caches.match(e.request).then(hit => hit || caches.match('./index.html')))
  );
});

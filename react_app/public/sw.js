self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", (event) => {
  const cacheMode =
    event.request.mode === "navigate" ? "no-store" : "default";

  event.respondWith(fetch(event.request, { cache: cacheMode }));
});

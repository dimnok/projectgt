/* eslint-disable no-undef */
/**
 * Service worker веб-приложения.
 *
 * Делает две вещи:
 *  1. Проксирует запросы без кэша — приложение всегда получает свежие данные.
 *  2. Принимает push-уведомления Firebase Cloud Messaging и открывает
 *     карточку заявки по нажатию.
 *
 * Важно: это единственный service worker сайта (scope `/`). Второй файл
 * `firebase-messaging-sw.js` не создаём — иначе он вытеснит этот.
 * Регистрацию передаём в `getToken` со стороны приложения
 * (`src/lib/notifications/push.ts`).
 *
 * Конфигурация Firebase ниже публичная и дублирует `src/config/firebase.ts`.
 */

const FIREBASE_CONFIG = {
  apiKey: "AIzaSyCopDZnRXf5E4WrIqBAWtQnYcj5Ky3ETpc",
  appId: "1:229844296884:web:758b5f5eaf1738ca8923e1",
  messagingSenderId: "229844296884",
  projectId: "pgtmess",
  authDomain: "pgtmess.firebaseapp.com",
  storageBucket: "pgtmess.firebasestorage.app",
};

try {
  importScripts("https://www.gstatic.com/firebasejs/12.18.0/firebase-app-compat.js");
  importScripts("https://www.gstatic.com/firebasejs/12.18.0/firebase-messaging-compat.js");

  firebase.initializeApp(FIREBASE_CONFIG);

  // Фон: если FCM уже передал notification, сами не показываем — иначе два баннера.
  firebase.messaging().onBackgroundMessage((payload) => {
    if (payload && payload.notification) {
      return;
    }

    const data = (payload && payload.data) || {};

    return self.registration.showNotification(data.title || "Заявка на закупку", {
      body: data.body || "",
      icon: "/icon-192.png",
      tag: data.request_id || "purchase_request",
      data: { url: data.link || "/" },
    });
  });
} catch (error) {
  // Без Firebase офлайн-часть сайта продолжает работать.
  console.error("sw: firebase init failed", error);
}

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

/** Нажатие по баннеру: переходим на карточку заявки. */
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  const targetPath = data.url || "/";
  const targetUrl = new URL(targetPath, self.location.origin).href;

  event.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ("focus" in client) {
            if ("navigate" in client) {
              return client.navigate(targetUrl).then(() => client.focus());
            }
            client.postMessage({ type: "notification_navigate", url: targetPath });
            return client.focus();
          }
        }
        if (self.clients.openWindow) {
          return self.clients.openWindow(targetUrl);
        }
      }),
  );
});

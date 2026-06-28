/* eslint-disable no-undef */
// Firebase Messaging Service Worker for Flutter Web / iOS PWA push notifications.
//
// Важно: для PWA FCM сам показывает push из webpush.notification.
// Нельзя вызывать showNotification() в onBackgroundMessage — иначе два баннера.

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCopDZnRXf5E4WrIqBAWtQnYcj5Ky3ETpc',
  appId: '1:229844296884:web:758b5f5eaf1738ca8923e1',
  messagingSenderId: '229844296884',
  projectId: 'pgtmess',
  authDomain: 'pgtmess.firebaseapp.com',
  storageBucket: 'pgtmess.firebasestorage.app',
  measurementId: 'G-HER9D5YNCF',
});

const messaging = firebase.messaging();

function buildWorkUrl(workId) {
  if (!workId) return '/';
  return '/works/' + workId;
}

// Data-only fallback: если придёт сообщение без notification, показываем сами.
messaging.onBackgroundMessage((payload) => {
  if (payload && payload.notification) {
    return;
  }

  const title = (payload && payload.data && payload.data.title) || 'Стройка PRO';
  const body = (payload && payload.data && payload.data.body) || '';
  const workId = payload && payload.data && payload.data.work_id;

  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    tag: workId || 'work_event',
    data: {
      workId: workId || '',
      url: buildWorkUrl(workId),
    },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  const targetPath = data.url || '/';
  const targetUrl = new URL(targetPath, self.location.origin).href;

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if ('focus' in client) {
            if ('navigate' in client) {
              return client.navigate(targetUrl).then(() => client.focus());
            }
            client.postMessage({ type: 'notification_navigate', url: targetPath });
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      }),
  );
});

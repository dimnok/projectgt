/* eslint-disable no-undef */
// Firebase Messaging Service Worker for Flutter Web PWA push notifications.

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

messaging.onBackgroundMessage((payload) => {
  const title =
    (payload && payload.notification && payload.notification.title) ||
    'Стройка PRO';
  const body =
    (payload && payload.notification && payload.notification.body) || '';
  const workId = payload && payload.data && payload.data.work_id;

  return self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    data: {
      workId: workId || '',
      url: buildWorkUrl(workId),
    },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const targetPath =
    (event.notification.data && event.notification.data.url) || '/';
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

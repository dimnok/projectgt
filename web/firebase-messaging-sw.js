/* eslint-disable no-undef */
// Firebase Messaging Service Worker for Flutter Web
// Uses compat SDK for broader compatibility with Flutter web builds

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

// Optional: handle background messages (shows basic notification)
messaging.onBackgroundMessage((payload) => {
  const title = (payload && payload.notification && payload.notification.title) || 'Notification';
  const body = (payload && payload.notification && payload.notification.body) || '';
  self.registration.showNotification(title, { body });
});



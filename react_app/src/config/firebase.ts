/**
 * Публичная конфигурация Firebase (проект `pgtmess`).
 *
 * Эти значения не секретны: они всё равно попадают в браузер.
 * Приватный ключ сервисного аккаунта хранится только на сервере
 * (секрет `SERVICE_ACCOUNT` у Edge Function).
 *
 * Дублируется в `public/sw.js` — менять нужно в обоих файлах.
 */
export const firebaseConfig = {
  apiKey: "AIzaSyCopDZnRXf5E4WrIqBAWtQnYcj5Ky3ETpc",
  appId: "1:229844296884:web:758b5f5eaf1738ca8923e1",
  messagingSenderId: "229844296884",
  projectId: "pgtmess",
  authDomain: "pgtmess.firebaseapp.com",
  storageBucket: "pgtmess.firebasestorage.app",
} as const;

/** Ключ VAPID для Web Push (публичный). */
export const firebaseVapidKey =
  "BGPPZr58sdNUlGT4RFTLiteNdyOxQWI9mJdxnP4ycqEA0qUrGh6sDRKdkvXN6O1jpdmeH1ETcwn8ePeTPocORW4";

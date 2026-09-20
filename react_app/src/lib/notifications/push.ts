"use client";

import type { FirebaseApp } from "firebase/app";
import type { SupabaseClient } from "@supabase/supabase-js";

import { firebaseConfig, firebaseVapidKey } from "@/config/firebase";
import { getClientAppVersion } from "@/lib/app-version";
import { createClient } from "@/lib/supabase/client";

/** Ключ в localStorage: одна установка браузера — один идентификатор. */
const INSTALLATION_STORAGE_KEY = "projectgt_push_installation_id";

/** Токен текущего устройства: нужен, чтобы погасить его при выходе. */
let currentToken: string | null = null;

/**
 * Возвращает Firebase-приложение, создавая его при первом обращении.
 *
 * Библиотека подгружается динамически: на сервере она не нужна, а в браузере
 * не попадает в основной пакет приложения.
 */
async function getFirebaseApp(): Promise<FirebaseApp> {
  const { getApp, getApps, initializeApp } = await import("firebase/app");
  return getApps().length ? getApp() : initializeApp(firebaseConfig);
}

/**
 * Идентификатор установки браузера.
 *
 * Используется как `installation_id` в `user_tokens`: по нему сервер понимает,
 * что это то же устройство, и не дублирует push.
 */
function resolveInstallationId(): string {
  try {
    const stored = window.localStorage.getItem(INSTALLATION_STORAGE_KEY);
    if (stored) {
      return stored;
    }
    const created = crypto.randomUUID();
    window.localStorage.setItem(INSTALLATION_STORAGE_KEY, created);
    return created;
  } catch {
    return "";
  }
}

/** Человекочитаемая подпись устройства для таблицы `user_tokens`. */
function deviceLabel(): string {
  const agent = navigator.userAgent;
  const standalone =
    window.matchMedia?.("(display-mode: standalone)").matches ?? false;
  const suffix = standalone ? " (приложение)" : "";

  if (/iPhone|iPad|iPod/.test(agent)) return `Safari${suffix} (iPhone)`;
  if (/Android/.test(agent)) return `Chrome${suffix} (Android)`;
  if (/Macintosh/.test(agent)) return `Браузер${suffix} (Mac)`;
  if (/Windows/.test(agent)) return `Браузер${suffix} (Windows)`;
  return `Браузер${suffix}`;
}

/** ФИО пользователя для `user_tokens.user_display_name`. */
async function resolveUserDisplayName(
  client: SupabaseClient,
  userId: string
): Promise<string | null> {
  const { data } = await client
    .from("profiles")
    .select("short_name, full_name")
    .eq("id", userId)
    .maybeSingle();

  const shortName = (data?.short_name as string | null)?.trim();
  if (shortName) return shortName;

  const fullName = (data?.full_name as string | null)?.trim();
  return fullName || null;
}

/** Сохраняет токен устройства в `user_tokens`. */
async function saveToken(
  client: SupabaseClient,
  userId: string,
  token: string
): Promise<void> {
  const installationId = resolveInstallationId();
  const { version } = getClientAppVersion();
  const displayName = await resolveUserDisplayName(client, userId);

  // Гасим старые токены этой же установки. Чужие устройства не трогаем:
  // на телефоне и компьютере это разные `installation_id`.
  if (installationId) {
    await client
      .from("user_tokens")
      .update({ is_active: false })
      .eq("user_id", userId)
      .eq("platform", "web")
      .eq("installation_id", installationId)
      .neq("token", token);
  }

  const payload = {
    user_id: userId,
    token,
    platform: "web",
    installation_id: installationId || null,
    device_model: deviceLabel(),
    os_version: navigator.userAgent,
    app_version: version,
    user_display_name: displayName,
    is_active: true,
    updated_at: new Date().toISOString(),
  };

  const upsert = await client
    .from("user_tokens")
    .upsert(payload, { onConflict: "installation_id,platform" });

  if (!upsert.error) {
    return;
  }

  // Запасной путь, если в базе нет уникальности по (installation_id, platform).
  const existing = await client
    .from("user_tokens")
    .select("id")
    .eq("token", token)
    .maybeSingle();

  if (existing.data?.id) {
    await client.from("user_tokens").update(payload).eq("id", existing.data.id);
  } else {
    await client.from("user_tokens").insert(payload);
  }
}

/**
 * Запрашивает разрешение на уведомления и сохраняет токен устройства.
 *
 * Вызывается после входа. Если браузер не поддерживает push или пользователь
 * запретил уведомления — тихо выходим, вход в приложение это не блокирует.
 */
export async function registerPushNotifications(userId: string): Promise<void> {
  const client = createClient();
  if (!client || typeof window === "undefined") return;
  if (!("serviceWorker" in navigator) || !("Notification" in window)) return;

  try {
    const { getMessaging, getToken, isSupported } = await import(
      "firebase/messaging"
    );

    if (!(await isSupported())) {
      return;
    }

    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      return;
    }

    const registration = await navigator.serviceWorker.ready;
    const app = await getFirebaseApp();
    const token = await getToken(getMessaging(app), {
      vapidKey: firebaseVapidKey,
      serviceWorkerRegistration: registration,
    });

    if (!token) {
      return;
    }

    await saveToken(client, userId, token);
    currentToken = token;
  } catch (error) {
    console.error("push: не удалось зарегистрировать устройство", error);
  }
}

/** Помечает токен текущего устройства неактивным при выходе из аккаунта. */
export async function deactivatePushToken(): Promise<void> {
  const client = createClient();
  if (!client || !currentToken) return;

  try {
    await client
      .from("user_tokens")
      .update({ is_active: false })
      .eq("token", currentToken);
  } catch (error) {
    console.error("push: не удалось отключить устройство", error);
  }

  currentToken = null;
}

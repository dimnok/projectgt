import { createBrowserClient } from "@supabase/ssr";

import { env, isSupabaseConfigured } from "@/config/env";

/**
 * Creates a browser Supabase client.
 * Returns `null` until public credentials are configured.
 */
export function createClient() {
  if (!isSupabaseConfigured()) {
    return null;
  }

  return createBrowserClient(env.supabaseUrl, env.supabasePublishableKey);
}

/**
 * Returns a browser Supabase client or throws if credentials are missing.
 */
export function getRequiredClient() {
  const client = createClient();
  if (!client) {
    throw new Error(
      "Не заданы ключи подключения. Добавьте их в файл react_app/.env.local"
    );
  }
  return client;
}

/**
 * Access-token текущей сессии — для запросов к Node-роутам приложения
 * (разбор Excel, шаблон). Запись в базу идёт напрямую в Supabase.
 */
export async function getAccessToken(): Promise<string> {
  const client = getRequiredClient();
  const { data, error } = await client.auth.getSession();
  const token = data.session?.access_token;
  if (error || !token) {
    throw new Error("Нужно войти в аккаунт");
  }
  return token;
}

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

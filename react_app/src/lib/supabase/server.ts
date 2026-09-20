import { createClient } from "@supabase/supabase-js";

import { env } from "@/config/env";

/**
 * Проверяет access-token пользователя из заголовка `Authorization`.
 *
 * Нужен только Node-роутам, которые работают с файлами (разбор Excel, шаблон):
 * запись в базу из роутов не идёт, поэтому достаточно убедиться, что запрос
 * от авторизованного пользователя.
 *
 * @returns id пользователя или `null`, если токена нет или он недействителен.
 */
export async function getUserIdFromRequest(
  request: Request
): Promise<string | null> {
  const header = request.headers.get("authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";

  if (!token || !env.supabaseUrl || !env.supabasePublishableKey) {
    return null;
  }

  const supabase = createClient(env.supabaseUrl, env.supabasePublishableKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    return null;
  }
  return data.user.id;
}

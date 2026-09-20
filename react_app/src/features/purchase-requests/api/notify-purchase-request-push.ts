import { createClient } from "@/lib/supabase/client";

/**
 * Запускает отправку push-уведомлений по заявке.
 *
 * Получателей определяет сервер: он берёт уведомления, которые база уже
 * записала (участники роли этапа и инициатор), и шлёт push только им.
 * Ошибка push не должна ломать действие по заявке, поэтому вызов «тихий».
 */
export async function notifyPurchaseRequestPush(requestId: string): Promise<void> {
  const client = createClient();
  if (!client) {
    return;
  }

  try {
    await client.functions.invoke("send_purchase_request_event", {
      body: {
        request_id: requestId,
        origin: typeof window === "undefined" ? undefined : window.location.origin,
      },
    });
  } catch {
    // Push не блокирует работу с заявкой.
  }
}

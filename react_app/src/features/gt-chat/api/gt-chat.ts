import { env } from "@/config/env";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  ChatMessage,
  ChatThread,
} from "@/features/gt-chat/types/gt-chat.types";
import { asRowList, mapMessage, mapThread } from "@/features/gt-chat/utils/mappers";

/** Сколько сообщений подгружаем в ленту. */
export const CHAT_MESSAGES_LIMIT = 200;

/** Сколько ждём ответ помощника, прежде чем показать ошибку. */
const ANSWER_TIMEOUT_MS = 90_000;

type ChatAnswerResponse = {
  message?: { id?: string; body?: string; created_at?: string };
  error?: string;
};

function throwIfError(error: { message: string } | null) {
  if (error) {
    throw new Error(error.message);
  }
}

/** Диалоги текущего пользователя в активной компании. */
export async function getChatThreads(): Promise<ChatThread[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("chat_thread_list", {
    p_company_id: companyId,
  });
  throwIfError(error);
  return asRowList(data).map(mapThread);
}

/** Новый диалог с помощником. Возвращает его идентификатор. */
export async function createChatThread(): Promise<string> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("chat_thread_create", {
    p_company_id: companyId,
  });
  throwIfError(error);
  return String(data);
}

export async function deleteChatThread(threadId: string): Promise<void> {
  const client = getRequiredClient();
  const { error } = await client.rpc("chat_thread_delete", {
    p_thread_id: threadId,
  });
  throwIfError(error);
}

export async function getChatMessages(threadId: string): Promise<ChatMessage[]> {
  const client = getRequiredClient();
  const { data, error } = await client.rpc("chat_thread_messages", {
    p_thread_id: threadId,
    p_limit: CHAT_MESSAGES_LIMIT,
  });
  throwIfError(error);
  return asRowList(data).map(mapMessage);
}

/** Сообщение человека. Сохраняется сразу — ответ помощника идёт следом. */
export async function addChatUserMessage(
  threadId: string,
  body: string
): Promise<ChatMessage | null> {
  const client = getRequiredClient();
  const { data, error } = await client.rpc("chat_message_add_user", {
    p_thread_id: threadId,
    p_body: body,
  });
  throwIfError(error);
  const [row] = asRowList(data);
  return row ? mapMessage(row) : null;
}

/**
 * Ответ помощника.
 *
 * Обращаемся к серверной функции напрямую: она читает переписку из базы,
 * спрашивает модель и дописывает ответ. Ключ модели живёт на сервере.
 */
export async function askGtChat(threadId: string): Promise<ChatMessage | null> {
  const client = getRequiredClient();
  const {
    data: { session },
  } = await client.auth.getSession();
  if (!session?.access_token) {
    throw new Error("Нужно войти в аккаунт");
  }

  const controller = new AbortController();
  const timer = window.setTimeout(() => controller.abort(), ANSWER_TIMEOUT_MS);

  try {
    const response = await fetch(`${env.supabaseUrl}/functions/v1/gt_chat`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: env.supabasePublishableKey,
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ thread_id: threadId }),
      signal: controller.signal,
    });

    const payload = (await response
      .json()
      .catch(() => null)) as ChatAnswerResponse | null;

    if (!response.ok) {
      throw new Error(payload?.error ?? `Помощник вернул ошибку (${response.status})`);
    }

    const message = payload?.message;
    if (!message?.body) {
      return null;
    }

    return {
      id: message.id ?? "",
      authorKind: "ai",
      authorUserId: null,
      authorName: null,
      body: message.body,
      createdAt: message.created_at ?? new Date().toISOString(),
    };
  } finally {
    window.clearTimeout(timer);
  }
}

"use client";

import { useCallback, useMemo, useState } from "react";
import { toast } from "sonner";

import {
  useChatMessages,
  useChatThreads,
  useCreateChatThread,
  useDeleteChatThread,
  useRetryChatAnswer,
  useSendChatMessage,
} from "@/features/gt-chat/hooks/use-gt-chat";
import type { ChatThread } from "@/features/gt-chat/types/gt-chat.types";

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Не удалось выполнить действие";
}

/**
 * Общая логика ГТ Чата для всех видов интерфейса: список диалогов, открытая
 * переписка, отправка и повторный запрос ответа. Интерфейс (компьютер,
 * телефон, плавающая панель) рисуется отдельно и берёт данные отсюда.
 *
 * `enabled` нужен плавающей панели: пока она закрыта, лишние запросы не идут.
 */
export function useGtChatConversation(options?: { enabled?: boolean }) {
  const enabled = options?.enabled ?? true;
  const threadsQuery = useChatThreads(enabled);
  const threads = useMemo(() => threadsQuery.data ?? [], [threadsQuery.data]);

  const [selectedId, setSelectedId] = useState<string | null>(null);
  // Открытый диалог: выбранный, иначе первый в списке.
  const activeThreadId = selectedId ?? threads[0]?.id ?? null;
  const activeThread =
    threads.find((thread) => thread.id === activeThreadId) ?? null;

  const messagesQuery = useChatMessages(activeThreadId);
  const messages = messagesQuery.data ?? [];
  const sendMessage = useSendChatMessage();
  const retryAnswer = useRetryChatAnswer();
  const createThread = useCreateChatThread();
  const deleteThread = useDeleteChatThread();

  const isAnswering = sendMessage.isPending || retryAnswer.isPending;
  const lastMessage = messages[messages.length - 1] ?? null;
  // Ответ можно запросить заново, если последнее слово осталось за человеком.
  const canRetry = lastMessage?.authorKind === "user";

  /** Пустой диалог переиспользуем: кнопка «Новый диалог» не плодит пустышки. */
  const handleCreateThread = useCallback(() => {
    const empty = threads.find((thread) => thread.messageCount === 0);
    if (empty) {
      setSelectedId(empty.id);
      return;
    }
    createThread.mutate(undefined, {
      onSuccess: (id) => setSelectedId(id),
      onError: (error) => toast.error(errorMessage(error)),
    });
  }, [createThread, threads]);

  const handleSend = useCallback(
    (body: string) => {
      sendMessage.mutate(
        { threadId: activeThreadId, body },
        {
          onSuccess: (id) => setSelectedId(id),
          onError: (error) => toast.error(errorMessage(error)),
        }
      );
    },
    [activeThreadId, sendMessage]
  );

  const handleRetry = useCallback(() => {
    if (!activeThreadId) {
      return;
    }
    retryAnswer.mutate(activeThreadId, {
      onError: (error) => toast.error(errorMessage(error)),
    });
  }, [activeThreadId, retryAnswer]);

  const handleDeleteThread = useCallback(
    (thread: ChatThread, options?: { onDeleted?: () => void }) => {
      deleteThread.mutate(thread.id, {
        onSuccess: () => {
          if (thread.id === activeThreadId) {
            setSelectedId(null);
          }
          options?.onDeleted?.();
        },
        onError: (error) => toast.error(errorMessage(error)),
      });
    },
    [activeThreadId, deleteThread]
  );

  return {
    threads,
    threadsQuery,
    activeThreadId,
    activeThread,
    selectThread: setSelectedId,
    messages,
    messagesQuery,
    isAnswering,
    canRetry,
    isCreatingThread: createThread.isPending,
    isDeletingThread: deleteThread.isPending,
    createThread: handleCreateThread,
    sendMessage: handleSend,
    retryAnswer: handleRetry,
    deleteThread: handleDeleteThread,
  };
}

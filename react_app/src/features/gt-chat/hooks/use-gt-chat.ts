"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  addChatUserMessage,
  askGtChat,
  createChatThread,
  deleteChatThread,
  getChatMessages,
  getChatThreads,
} from "@/features/gt-chat/api/gt-chat";

/** Корень кэша раздела: по нему обновляем и список диалогов, и ленту. */
export const gtChatQueryKey = ["gt-chat"] as const;

export function chatMessagesQueryKey(threadId: string) {
  return [...gtChatQueryKey, "messages", threadId] as const;
}

export function useChatThreads(enabled = true) {
  return useQuery({
    queryKey: [...gtChatQueryKey, "threads"],
    queryFn: getChatThreads,
    enabled,
  });
}

export function useChatMessages(threadId: string | null) {
  return useQuery({
    queryKey: chatMessagesQueryKey(threadId ?? ""),
    queryFn: () => getChatMessages(threadId!),
    enabled: Boolean(threadId),
  });
}

export function useCreateChatThread() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createChatThread,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: gtChatQueryKey });
    },
  });
}

export function useDeleteChatThread() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: deleteChatThread,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: gtChatQueryKey });
    },
  });
}

/**
 * Отправка сообщения: сначала сохраняем вопрос человека, затем получаем
 * ответ помощника. Если помощник не ответил, вопрос остаётся в диалоге —
 * ответ можно запросить повторно.
 */
export function useSendChatMessage() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: { threadId: string | null; body: string }) => {
      const threadId = input.threadId ?? (await createChatThread());
      await addChatUserMessage(threadId, input.body);
      await queryClient.invalidateQueries({ queryKey: gtChatQueryKey });
      await askGtChat(threadId);
      return threadId;
    },
    onSettled: () => {
      void queryClient.invalidateQueries({ queryKey: gtChatQueryKey });
    },
  });
}

/** Повторный запрос ответа на последнее сообщение человека. */
export function useRetryChatAnswer() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (threadId: string) => askGtChat(threadId),
    onSettled: () => {
      void queryClient.invalidateQueries({ queryKey: gtChatQueryKey });
    },
  });
}

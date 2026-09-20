"use client";

import { useState } from "react";

import { ErrorState } from "@/components/shared/error-state";
import { useGtChatConversation } from "@/features/gt-chat/hooks/use-gt-chat-conversation";
import type { ChatThread } from "@/features/gt-chat/types/gt-chat.types";
import { chatThreadTitle } from "@/features/gt-chat/utils/format";
import { ChatComposer } from "@/features/gt-chat/ui/shared/chat-composer";
import { ChatDeleteThreadDialog } from "@/features/gt-chat/ui/shared/chat-delete-thread-dialog";
import { ChatMessageList } from "@/features/gt-chat/ui/shared/chat-message-list";
import { ChatBadge, ChatEmptyHint } from "@/features/gt-chat/ui/shared/chat-parts";
import { ChatThreadList } from "@/features/gt-chat/ui/shared/chat-thread-list";
import { usePermissions } from "@/hooks/use-permissions";

/**
 * ГТ Чат на компьютере: слева список диалогов, справа переписка.
 *
 * Логика общая с телефоном и плавающей панелью — хуки и серверные функции
 * одни и те же, отличается только раскладка.
 */
export function GtChatDesktop() {
  const { can } = usePermissions();
  const canWrite = can("chat", "create");
  const canDelete = can("chat", "delete");
  const chat = useGtChatConversation();
  const [threadToDelete, setThreadToDelete] = useState<ChatThread | null>(null);

  if (chat.threadsQuery.isError) {
    return (
      <ErrorState
        title="Чат не открылся"
        message={
          chat.threadsQuery.error instanceof Error
            ? chat.threadsQuery.error.message
            : "Неизвестная ошибка"
        }
      />
    );
  }

  return (
    <div
      data-fill-viewport
      className="flex h-full min-h-0 min-w-0 w-full flex-1 flex-col"
    >
      <div className="flex min-h-0 min-w-0 flex-1 overflow-hidden rounded-3xl border border-border/80 bg-background/80 shadow-float ring-1 ring-foreground/5 backdrop-blur-xl">
        <aside className="flex w-72 shrink-0 flex-col border-r border-border/70 bg-muted/25">
          <div className="shrink-0 px-5 pt-5 pb-1">
            <h2 className="font-heading text-base font-medium">ГТ Чат</h2>
            <p className="text-xs text-muted-foreground">
              Помощник в программе
            </p>
          </div>
          <ChatThreadList
            className="min-h-0 flex-1"
            threads={chat.threads}
            activeId={chat.activeThreadId}
            onSelect={chat.selectThread}
            onCreate={canWrite ? chat.createThread : undefined}
            isCreating={chat.isCreatingThread}
            onDelete={
              canDelete
                ? (thread) => setThreadToDelete(thread)
                : undefined
            }
          />
        </aside>

        <section className="flex min-h-0 min-w-0 flex-1 flex-col bg-gradient-to-b from-muted/20 to-background">
          <header className="flex shrink-0 items-center gap-3 border-b border-border/70 px-5 py-3">
            <ChatBadge />
            <div className="min-w-0 flex-1">
              <p className="truncate font-heading text-sm font-medium">
                {chatThreadTitle(chat.activeThread?.title ?? null)}
              </p>
              <p className="text-[11px] text-muted-foreground">
                Отвечает ИИ и ищет в интернете. Данные компании он пока не видит
              </p>
            </div>
          </header>

          <ChatMessageList
            messages={chat.messages}
            isLoading={chat.messagesQuery.isLoading}
            isAnswering={chat.isAnswering}
            canRetry={chat.canRetry}
            onRetry={chat.retryAnswer}
            emptyHint={<ChatEmptyHint />}
          />

          <div className="shrink-0 border-t border-border/70 px-4 py-3">
            {canWrite ? (
              <ChatComposer
                onSend={chat.sendMessage}
                isSending={chat.isAnswering}
              />
            ) : (
              <p className="py-1.5 text-center text-xs text-muted-foreground">
                У вашей роли нет права писать в чат
              </p>
            )}
          </div>
        </section>
      </div>

      <ChatDeleteThreadDialog
        thread={threadToDelete}
        isDeleting={chat.isDeletingThread}
        onOpenChange={(open) => {
          if (!open) {
            setThreadToDelete(null);
          }
        }}
        onConfirm={(thread) => {
          chat.deleteThread(thread, {
            onDeleted: () => setThreadToDelete(null),
          });
        }}
      />
    </div>
  );
}

"use client";

import { useState } from "react";
import { ArrowLeftIcon, MessagesSquareIcon, PlusIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { ErrorState } from "@/components/shared/error-state";
import { useGtChatConversation } from "@/features/gt-chat/hooks/use-gt-chat-conversation";
import type { ChatThread } from "@/features/gt-chat/types/gt-chat.types";
import { chatThreadTitle } from "@/features/gt-chat/utils/format";
import { ChatComposer } from "@/features/gt-chat/ui/shared/chat-composer";
import { ChatDeleteThreadDialog } from "@/features/gt-chat/ui/shared/chat-delete-thread-dialog";
import { ChatMessageList } from "@/features/gt-chat/ui/shared/chat-message-list";
import { ChatEmptyHint } from "@/features/gt-chat/ui/shared/chat-parts";
import { ChatThreadList } from "@/features/gt-chat/ui/shared/chat-thread-list";
import { usePermissions } from "@/hooks/use-permissions";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

/**
 * ГТ Чат на телефоне: переписка на весь экран, список диалогов — отдельным
 * экраном по кнопке. Логика общая с компьютером.
 */
export function GtChatMobile() {
  const { can } = usePermissions();
  const canWrite = can("chat", "create");
  const canDelete = can("chat", "delete");
  const chat = useGtChatConversation();
  const [showThreads, setShowThreads] = useState(false);
  const [threadToDelete, setThreadToDelete] = useState<ChatThread | null>(null);

  const deleteDialog = (
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
  );

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

  if (showThreads) {
    return (
      <div
        data-fill-viewport
        className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
      >
        <header className="shrink-0 border-b bg-background">
          <MobileAppBar
            title="Диалоги"
            className="border-b-0"
            leading={
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                className="rounded-full"
                aria-label="К переписке"
                onClick={() => setShowThreads(false)}
              >
                <ArrowLeftIcon />
              </Button>
            }
            trailing={
              canWrite ? (
                <Button
                  type="button"
                  size="icon"
                  className="rounded-full"
                  aria-label="Новый диалог"
                  disabled={chat.isCreatingThread}
                  onClick={() => {
                    chat.createThread();
                    setShowThreads(false);
                  }}
                >
                  <PlusIcon />
                </Button>
              ) : undefined
            }
          />
        </header>

        <ChatThreadList
          className="min-h-0 flex-1 bg-background"
          threads={chat.threads}
          activeId={chat.activeThreadId}
          onSelect={(id) => {
            chat.selectThread(id);
            setShowThreads(false);
          }}
          onDelete={
            canDelete ? (thread) => setThreadToDelete(thread) : undefined
          }
        />

        {deleteDialog}
      </div>
    );
  }

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <header className="shrink-0 border-b bg-background">
        <MobileAppBar
          title={chatThreadTitle(chat.activeThread?.title ?? null)}
          className="border-b-0"
          trailing={
            <Button
              type="button"
              variant="ghost"
              size="icon-sm"
              className="rounded-full"
              aria-label="Диалоги"
              onClick={() => setShowThreads(true)}
            >
              <MessagesSquareIcon />
            </Button>
          }
        />
      </header>

      <ChatMessageList
        messages={chat.messages}
        isLoading={chat.messagesQuery.isLoading}
        isAnswering={chat.isAnswering}
        canRetry={chat.canRetry}
        onRetry={chat.retryAnswer}
        emptyHint={<ChatEmptyHint />}
      />

      <div className="shrink-0 border-t bg-background px-3 pt-2 pb-[max(0.5rem,env(safe-area-inset-bottom))]">
        {canWrite ? (
          <ChatComposer
            onSend={chat.sendMessage}
            isSending={chat.isAnswering}
            compact
          />
        ) : (
          <p className="py-1.5 text-center text-xs text-muted-foreground">
            У вашей роли нет права писать в чат
          </p>
        )}
      </div>

      {deleteDialog}
    </div>
  );
}

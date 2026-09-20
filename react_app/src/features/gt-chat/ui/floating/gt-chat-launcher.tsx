"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { ArrowUpRightIcon, MessageCircleIcon, XIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useGtChatConversation } from "@/features/gt-chat/hooks/use-gt-chat-conversation";
import { ChatComposer } from "@/features/gt-chat/ui/shared/chat-composer";
import { ChatMessageList } from "@/features/gt-chat/ui/shared/chat-message-list";
import { ChatBadge, ChatEmptyHint } from "@/features/gt-chat/ui/shared/chat-parts";
import { useIsMobile } from "@/hooks/use-mobile";
import { usePermissions } from "@/hooks/use-permissions";
import { cn } from "@/lib/utils";

/**
 * Плавающая кнопка ГТ Чата поверх разделов.
 *
 * Нужна, чтобы спросить помощника, не уходя с текущего экрана. Переписка та же,
 * что в разделе «ГТ Чат»: можно продолжить диалог в полном виде. На телефоне
 * кнопки нет — там чат открывается из меню.
 */
export function GtChatLauncher() {
  const pathname = usePathname();
  const isMobile = useIsMobile();
  const { can, isReady } = usePermissions();
  const [open, setOpen] = useState(false);
  const chat = useGtChatConversation({ enabled: open });
  const canWrite = can("chat", "create");
  const isChatPage = pathname === "/gt-chat" || pathname.startsWith("/gt-chat/");

  useEffect(() => {
    if (!open) {
      return;
    }
    function handleKey(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setOpen(false);
      }
    }
    window.addEventListener("keydown", handleKey);
    return () => window.removeEventListener("keydown", handleKey);
  }, [open]);

  if (isMobile || !isReady || !can("chat", "read") || isChatPage) {
    return null;
  }

  return (
    <div className="pointer-events-none fixed right-6 bottom-6 z-40 flex flex-col items-end gap-3">
      {open ? (
        <section
          aria-label="ГТ Чат"
          className="pointer-events-auto flex h-[min(34rem,calc(100vh-8rem))] w-[22rem] flex-col overflow-hidden rounded-3xl border border-border/80 bg-background/95 shadow-float ring-1 ring-foreground/5 backdrop-blur-xl"
        >
          <header className="flex shrink-0 items-center gap-2.5 border-b border-border/70 px-4 py-3">
            <ChatBadge className="flex size-7 shrink-0 items-center justify-center rounded-full bg-primary text-[10px] font-bold text-primary-foreground" />
            <div className="min-w-0 flex-1">
              <p className="font-heading text-sm font-medium">ГТ Чат</p>
              <p className="truncate text-[11px] text-muted-foreground">
                Отвечает ИИ, ищет в интернете
              </p>
            </div>
            <Button
              type="button"
              variant="ghost"
              size="icon-sm"
              className="rounded-full"
              aria-label="Открыть раздел ГТ Чат"
              render={<Link href="/gt-chat" />}
            >
              <ArrowUpRightIcon />
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="icon-sm"
              className="rounded-full"
              aria-label="Закрыть чат"
              onClick={() => setOpen(false)}
            >
              <XIcon />
            </Button>
          </header>

          {chat.threadsQuery.isError ? (
            <div className="flex min-h-0 flex-1 items-center justify-center px-6 text-center text-xs leading-relaxed text-muted-foreground">
              {chat.threadsQuery.error instanceof Error
                ? chat.threadsQuery.error.message
                : "Чат пока недоступен"}
            </div>
          ) : (
            <ChatMessageList
              className="px-3 py-3"
              messages={chat.messages}
              isLoading={chat.messagesQuery.isLoading}
              isAnswering={chat.isAnswering}
              canRetry={chat.canRetry}
              onRetry={chat.retryAnswer}
              emptyHint={<ChatEmptyHint />}
            />
          )}

          <div className="shrink-0 border-t border-border/70 p-3">
            {chat.threadsQuery.isError ? null : canWrite ? (
              <ChatComposer
                onSend={chat.sendMessage}
                isSending={chat.isAnswering}
                compact
                placeholder="Спросите помощника…"
              />
            ) : (
              <p className="text-center text-xs text-muted-foreground">
                Нет права писать в чат
              </p>
            )}
          </div>
        </section>
      ) : null}

      <Button
        type="button"
        size="icon-lg"
        className={cn(
          "pointer-events-auto rounded-full shadow-float",
          open && "bg-muted text-foreground"
        )}
        aria-label={open ? "Свернуть ГТ Чат" : "Открыть ГТ Чат"}
        onClick={() => setOpen((value) => !value)}
      >
        <MessageCircleIcon />
      </Button>
    </div>
  );
}

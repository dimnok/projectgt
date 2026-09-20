"use client";

import { useEffect, useRef, type ReactNode } from "react";
import { RotateCcwIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import type { ChatMessage } from "@/features/gt-chat/types/gt-chat.types";
import { formatChatTime } from "@/features/gt-chat/utils/format";
import { ChatMessageText } from "@/features/gt-chat/ui/shared/chat-message-text";
import { cn } from "@/lib/utils";

type ChatMessageListProps = {
  messages: ChatMessage[];
  isLoading?: boolean;
  /** Помощник думает: показываем «печатает». */
  isAnswering?: boolean;
  /** Последнее слово за человеком — ответ можно запросить повторно. */
  canRetry?: boolean;
  onRetry?: () => void;
  emptyHint?: ReactNode;
  className?: string;
};

/** Лента сообщений: пузыри человека справа, ответы помощника слева. */
export function ChatMessageList({
  messages,
  isLoading = false,
  isAnswering = false,
  canRetry = false,
  onRetry,
  emptyHint,
  className,
}: ChatMessageListProps) {
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ block: "end" });
  }, [messages.length, isAnswering]);

  if (isLoading) {
    return (
      <div className={cn("flex flex-1 items-center justify-center", className)}>
        <Spinner />
      </div>
    );
  }

  return (
    <div
      className={cn(
        "flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto px-4 py-4",
        className
      )}
    >
      {messages.length === 0 && !isAnswering ? (
        <div className="flex flex-1 flex-col items-center justify-center gap-3 px-6 text-center">
          {emptyHint}
        </div>
      ) : null}

      {messages.map((message) => (
        <ChatBubble key={message.id} message={message} />
      ))}

      {isAnswering ? (
        <div className="flex items-end gap-2">
          <ChatAvatar />
          <div className="flex items-center gap-2 rounded-2xl rounded-bl-sm bg-muted px-3 py-2 text-sm text-muted-foreground">
            <Spinner className="size-3.5" />
            Помощник отвечает…
          </div>
        </div>
      ) : null}

      {!isAnswering && canRetry && onRetry ? (
        <div className="flex justify-start">
          <Button
            type="button"
            variant="outline"
            size="sm"
            className="rounded-full"
            onClick={onRetry}
          >
            <RotateCcwIcon data-icon="inline-start" />
            Получить ответ
          </Button>
        </div>
      ) : null}

      <div ref={bottomRef} />
    </div>
  );
}

function ChatAvatar() {
  return (
    <div className="flex size-7 shrink-0 items-center justify-center rounded-full bg-primary text-[10px] font-bold text-primary-foreground">
      ГТ
    </div>
  );
}

function ChatBubble({ message }: { message: ChatMessage }) {
  const isAi = message.authorKind === "ai";

  if (isAi) {
    return (
      <div className="flex items-end gap-2">
        <ChatAvatar />
        <div className="flex max-w-[min(42rem,80%)] flex-col gap-1">
          <div className="rounded-2xl rounded-bl-sm bg-muted px-3.5 py-2.5 text-sm leading-relaxed whitespace-pre-wrap">
            <ChatMessageText text={message.body} />
          </div>
          <span className="px-1 text-[10px] text-muted-foreground">
            {formatChatTime(message.createdAt)}
          </span>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <div className="max-w-[min(42rem,80%)] rounded-2xl rounded-br-sm bg-primary px-3.5 py-2.5 text-sm leading-relaxed whitespace-pre-wrap text-primary-foreground">
        <ChatMessageText text={message.body} />
      </div>
      <span className="px-1 text-[10px] text-muted-foreground">
        {formatChatTime(message.createdAt)}
      </span>
    </div>
  );
}

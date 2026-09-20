"use client";

import { MessageSquarePlusIcon, Trash2Icon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import type { ChatThread } from "@/features/gt-chat/types/gt-chat.types";
import { chatThreadTitle, formatChatStamp } from "@/features/gt-chat/utils/format";
import { cn } from "@/lib/utils";

type ChatThreadListProps = {
  threads: ChatThread[];
  activeId: string | null;
  onSelect: (id: string) => void;
  onDelete?: (thread: ChatThread) => void;
  onCreate?: () => void;
  isCreating?: boolean;
  className?: string;
};

/** Короткая строка под названием: кто и что написал последним. */
function threadPreview(thread: ChatThread): string {
  if (!thread.lastMessageBody) {
    return "Пока пусто";
  }
  const prefix = thread.lastMessageAuthorKind === "ai" ? "Помощник" : "Вы";
  return `${prefix}: ${thread.lastMessageBody}`;
}

export function ChatThreadList({
  threads,
  activeId,
  onSelect,
  onDelete,
  onCreate,
  isCreating = false,
  className,
}: ChatThreadListProps) {
  return (
    <div className={cn("flex min-h-0 flex-col", className)}>
      {onCreate ? (
        <div className="flex shrink-0 items-center justify-between gap-2 px-3 py-2">
          <p className="text-[10px] font-medium tracking-[0.18em] text-muted-foreground uppercase">
            Диалоги
          </p>
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            className="rounded-full"
            aria-label="Новый диалог"
            disabled={isCreating}
            onClick={onCreate}
          >
            {isCreating ? <Spinner /> : <MessageSquarePlusIcon />}
          </Button>
        </div>
      ) : null}

      <div className="flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto px-2 pb-2">
        {threads.length === 0 ? (
          <p className="px-2 py-3 text-xs leading-relaxed text-muted-foreground">
            Диалогов пока нет. Задайте первый вопрос — диалог появится сам.
          </p>
        ) : null}

        {threads.map((thread) => (
          <div
            key={thread.id}
            className={cn(
              "group flex items-center gap-1 rounded-2xl pr-1 transition-colors",
              thread.id === activeId
                ? "bg-foreground text-background"
                : "hover:bg-muted"
            )}
          >
            <button
              type="button"
              onClick={() => onSelect(thread.id)}
              className="flex min-w-0 flex-1 flex-col gap-0.5 px-3 py-2 text-left"
            >
              <span className="flex items-center gap-2">
                <span className="min-w-0 flex-1 truncate text-sm font-medium">
                  {chatThreadTitle(thread.title)}
                </span>
                <span
                  className={cn(
                    "shrink-0 text-[10px]",
                    thread.id === activeId
                      ? "text-background/70"
                      : "text-muted-foreground"
                  )}
                >
                  {formatChatStamp(thread.lastMessageAt)}
                </span>
              </span>
              <span
                className={cn(
                  "truncate text-xs",
                  thread.id === activeId
                    ? "text-background/70"
                    : "text-muted-foreground"
                )}
              >
                {threadPreview(thread)}
              </span>
            </button>

            {onDelete ? (
              <Button
                type="button"
                variant="ghost"
                size="icon-xs"
                className={cn(
                  "shrink-0 rounded-full opacity-0 transition-opacity group-hover:opacity-100 focus-visible:opacity-100",
                  thread.id === activeId
                    ? "text-background hover:bg-background/20"
                    : "text-muted-foreground"
                )}
                aria-label={`Удалить диалог «${chatThreadTitle(thread.title)}»`}
                onClick={() => onDelete(thread)}
              >
                <Trash2Icon />
              </Button>
            ) : null}
          </div>
        ))}
      </div>
    </div>
  );
}

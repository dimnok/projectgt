"use client";

import { useState, type KeyboardEvent } from "react";
import { SendHorizontalIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { cn } from "@/lib/utils";

/** Столько же символов принимает серверная функция. */
const MAX_LENGTH = 4000;

type ChatComposerProps = {
  onSend: (body: string) => void;
  isSending?: boolean;
  disabled?: boolean;
  placeholder?: string;
  /** Узкий вариант — для плавающей панели. */
  compact?: boolean;
  className?: string;
};

/** Поле ввода: Enter отправляет, Shift+Enter переносит строку. */
export function ChatComposer({
  onSend,
  isSending = false,
  disabled = false,
  placeholder = "Спросите помощника…",
  compact = false,
  className,
}: ChatComposerProps) {
  const [value, setValue] = useState("");
  const trimmed = value.trim();
  const canSend = Boolean(trimmed) && !isSending && !disabled;

  function submit() {
    if (!canSend) {
      return;
    }
    onSend(trimmed.slice(0, MAX_LENGTH));
    setValue("");
  }

  function handleKeyDown(event: KeyboardEvent<HTMLTextAreaElement>) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      submit();
    }
  }

  return (
    <div className={cn("flex items-end gap-2", className)}>
      <Textarea
        value={value}
        onChange={(event) => setValue(event.target.value.slice(0, MAX_LENGTH))}
        onKeyDown={handleKeyDown}
        placeholder={placeholder}
        disabled={disabled}
        rows={1}
        aria-label="Сообщение"
        className={cn(
          "max-h-32 min-h-9 resize-none rounded-2xl py-2",
          compact ? "min-h-9 text-sm" : "min-h-10"
        )}
      />
      <Button
        type="button"
        size="icon"
        className="shrink-0 rounded-full"
        aria-label="Отправить"
        disabled={!canSend}
        onClick={submit}
      >
        <SendHorizontalIcon />
      </Button>
    </div>
  );
}

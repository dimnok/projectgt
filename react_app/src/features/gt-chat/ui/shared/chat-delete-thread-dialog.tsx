"use client";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import type { ChatThread } from "@/features/gt-chat/types/gt-chat.types";
import { chatThreadTitle } from "@/features/gt-chat/utils/format";

type ChatDeleteThreadDialogProps = {
  thread: ChatThread | null;
  isDeleting?: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: (thread: ChatThread) => void;
};

/** Подтверждение удаления диалога: переписка пропадёт без возврата. */
export function ChatDeleteThreadDialog({
  thread,
  isDeleting = false,
  onOpenChange,
  onConfirm,
}: ChatDeleteThreadDialogProps) {
  return (
    <Dialog open={Boolean(thread)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить диалог?</DialogTitle>
          <DialogDescription>
            «{chatThreadTitle(thread?.title ?? null)}» и все сообщения в нём будут
            удалены. Вернуть их не получится.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={isDeleting}
            onClick={() => onOpenChange(false)}
          >
            Отмена
          </Button>
          <Button
            type="button"
            variant="destructive"
            disabled={isDeleting}
            onClick={() => thread && onConfirm(thread)}
          >
            {isDeleting ? <Spinner data-icon="inline-start" /> : null}
            Удалить
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

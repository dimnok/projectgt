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
import { formatRuDate } from "@/features/works/utils/work.utils";

type WorkDeleteDialogProps = {
  workDate: string | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function WorkDeleteDialog({
  workDate,
  isDeleting,
  onOpenChange,
  onConfirm,
}: WorkDeleteDialogProps) {
  return (
    <Dialog open={Boolean(workDate)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить смену?</DialogTitle>
          <DialogDescription>
            {workDate
              ? `Смена от ${formatRuDate(workDate)} будет удалена вместе с работами, часами и фото. Это нельзя отменить.`
              : ""}
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
            onClick={onConfirm}
          >
            {isDeleting ? <Spinner data-icon="inline-start" /> : null}
            Удалить
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

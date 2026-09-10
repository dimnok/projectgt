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
import type { WorkHour } from "@/features/works/types/work.types";

type WorkHourDeleteDialogProps = {
  hour: WorkHour | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function WorkHourDeleteDialog({
  hour,
  isDeleting,
  onOpenChange,
  onConfirm,
}: WorkHourDeleteDialogProps) {
  return (
    <Dialog open={Boolean(hour)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить сотрудника из смены?</DialogTitle>
          <DialogDescription>
            {hour
              ? `${hour.employeeName} будет убран из этой смены. Это действие нельзя отменить.`
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

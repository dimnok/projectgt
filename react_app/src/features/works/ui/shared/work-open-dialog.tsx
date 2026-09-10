"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { WorkOpenForm } from "@/features/works/ui/shared/work-open-form";
import type { Work } from "@/features/works/types/work.types";
import { formatRuDate, toDateKey } from "@/features/works/utils/work.utils";

type WorkOpenDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onOpened: (work: Work) => void;
};

export function WorkOpenDialog({
  open,
  onOpenChange,
  onOpened,
}: WorkOpenDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="flex! max-h-[min(90vh,52rem)] min-h-0 flex-col overflow-hidden sm:max-w-lg">
        <DialogHeader className="shrink-0">
          <DialogTitle>Открытие смены {formatRuDate(toDateKey(new Date()))}</DialogTitle>
          <DialogDescription>
            Выберите объект, сотрудников и утреннее фото.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <WorkOpenForm
            layout="dialog"
            onCancel={() => onOpenChange(false)}
            onOpened={(work) => {
              onOpenChange(false);
              onOpened(work);
            }}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

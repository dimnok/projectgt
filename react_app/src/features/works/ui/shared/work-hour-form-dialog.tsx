"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { WorkHour } from "@/features/works/types/work.types";
import { WorkHourForm } from "@/features/works/ui/shared/work-hour-form";

type WorkHourFormDialogProps = {
  open: boolean;
  workId: string;
  objectId: string;
  existingHours: WorkHour[];
  hour?: WorkHour | null;
  onOpenChange: (open: boolean) => void;
};

export function WorkHourFormDialog({
  open,
  workId,
  objectId,
  existingHours,
  hour = null,
  onOpenChange,
}: WorkHourFormDialogProps) {
  const isEdit = Boolean(hour);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Изменить часы" : "Добавить сотрудника"}
          </DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Можно изменить часы и комментарий."
              : "Выберите сотрудника. Часы можно указать позже."}
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <WorkHourForm
            key={hour?.id ?? "new"}
            layout="dialog"
            workId={workId}
            objectId={objectId}
            existingHours={existingHours}
            initial={hour}
            onCancel={() => onOpenChange(false)}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

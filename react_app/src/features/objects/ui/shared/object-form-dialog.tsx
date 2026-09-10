"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { ObjectForm } from "@/features/objects/ui/shared/object-form";
import type { ObjectDraft, SiteObject } from "@/features/objects/types/object.types";

type ObjectFormDialogProps = {
  open: boolean;
  object?: SiteObject | null;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: ObjectDraft) => void;
};

export function ObjectFormDialog({
  open,
  object,
  isSaving,
  onOpenChange,
  onSubmit,
}: ObjectFormDialogProps) {
  const isNew = !object;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{isNew ? "Новый объект" : "Редактирование объекта"}</DialogTitle>
          <DialogDescription>
            Наименование и адрес обязательны.
          </DialogDescription>
        </DialogHeader>
        <ObjectForm
          key={object?.id ?? "new"}
          object={object}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      </DialogContent>
    </Dialog>
  );
}

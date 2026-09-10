"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { EmployeeCreateForm } from "@/features/employees/ui/shared/employee-create-form";
import type {
  EmployeeCreateDraft,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";

type EmployeeCreateDialogProps = {
  open: boolean;
  objects: EmployeeObjectOption[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: EmployeeCreateDraft) => void;
};

export function EmployeeCreateDialog({
  open,
  objects,
  isSaving,
  onOpenChange,
  onSubmit,
}: EmployeeCreateDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Новый сотрудник</DialogTitle>
          <DialogDescription>
            Фамилия и имя обязательны. Остальное можно заполнить в карточке.
          </DialogDescription>
        </DialogHeader>
        {open ? (
          <EmployeeCreateForm
            objects={objects}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

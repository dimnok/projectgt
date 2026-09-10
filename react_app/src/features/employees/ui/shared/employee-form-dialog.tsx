"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { EmployeeForm } from "@/features/employees/ui/shared/employee-form";
import type {
  Employee,
  EmployeeDraft,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import { employeeFullName } from "@/features/employees/utils/employee.utils";

type EmployeeFormDialogProps = {
  employee: Employee | null;
  objects: EmployeeObjectOption[];
  positions: string[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: EmployeeDraft) => void;
};

export function EmployeeFormDialog({
  employee,
  objects,
  positions,
  isSaving,
  onOpenChange,
  onSubmit,
}: EmployeeFormDialogProps) {
  return (
    <Dialog open={Boolean(employee)} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,52rem)] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Редактирование сотрудника</DialogTitle>
          <DialogDescription>
            {employee
              ? `Карточка: ${employeeFullName(employee)}`
              : "Изменение данных сотрудника"}
          </DialogDescription>
        </DialogHeader>
        {employee ? (
          <EmployeeForm
            key={employee.id}
            employee={employee}
            objects={objects}
            positions={positions}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { EmployeeForm } from "@/features/employees/ui/shared/employee-form";
import type {
  Employee,
  EmployeeDraft,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";

type EmployeeFormSheetProps = {
  employee: Employee | null;
  objects: EmployeeObjectOption[];
  positions: string[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: EmployeeDraft) => void;
};

export function EmployeeFormSheet({
  employee,
  objects,
  positions,
  isSaving,
  onOpenChange,
  onSubmit,
}: EmployeeFormSheetProps) {
  return (
    <MobileSheet
      open={Boolean(employee)}
      onOpenChange={onOpenChange}
    >
      {employee ? (
        <EmployeeForm
          key={employee.id}
          layout="sheet"
          employee={employee}
          objects={objects}
          positions={positions}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}

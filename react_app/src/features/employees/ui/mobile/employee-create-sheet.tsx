"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { EmployeeCreateForm } from "@/features/employees/ui/shared/employee-create-form";
import type {
  EmployeeCreateDraft,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";

type EmployeeCreateSheetProps = {
  open: boolean;
  objects: EmployeeObjectOption[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: EmployeeCreateDraft) => void;
};

export function EmployeeCreateSheet({
  open,
  objects,
  isSaving,
  onOpenChange,
  onSubmit,
}: EmployeeCreateSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <EmployeeCreateForm
          layout="sheet"
          objects={objects}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}

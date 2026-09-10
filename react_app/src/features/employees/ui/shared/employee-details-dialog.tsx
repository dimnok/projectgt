"use client";

import { PencilIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { EmployeeAvatarManager } from "@/features/employees/ui/shared/employee-avatar-manager";
import { EmployeeDetailsTabs } from "@/features/employees/ui/shared/employee-details-tabs";
import { EmployeePhoneLink } from "@/features/employees/ui/shared/employee-details";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import type {
  Employee,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import { employeeEmploymentLabel } from "@/features/employees/utils/employee-employment";
import { employeeFullName } from "@/features/employees/utils/employee.utils";

type EmployeeDetailsDialogProps = {
  employee: Employee | null;
  objects: EmployeeObjectOption[];
  objectNamesById: Map<string, string>;
  canUpdate: boolean;
  onOpenChange: (open: boolean) => void;
  onEdit: () => void;
  onEmployeeUpdated?: (employee: Employee) => void;
};

export function EmployeeDetailsDialog({
  employee,
  objects,
  objectNamesById,
  canUpdate,
  onOpenChange,
  onEdit,
  onEmployeeUpdated,
}: EmployeeDetailsDialogProps) {
  const fullName = employee ? employeeFullName(employee) : "";
  const position = employee?.position.trim() || "Должность не указана";
  const phone = employee?.phone.trim() ?? "";

  return (
    <Dialog open={Boolean(employee)} onOpenChange={onOpenChange}>
      <DialogContent className="flex h-[90vh] w-[min(94vw,62rem)] flex-col gap-0 overflow-hidden rounded-2xl border border-border/80 p-0 shadow-2xl sm:max-w-5xl">
        <DialogHeader className="shrink-0 bg-muted/25 px-6 pt-5 pb-3 pr-12">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:gap-6">
            {employee ? (
              <EmployeeAvatarManager
                employee={employee}
                canUpdate={canUpdate}
                onPhotoChanged={(newUrl) => {
                  if (employee) {
                    onEmployeeUpdated?.({ ...employee, photoUrl: newUrl });
                  }
                }}
              />
            ) : null}

            <div className="flex min-w-0 flex-1 flex-col gap-2 pt-1 sm:pt-1.5">
              <div className="flex items-start justify-between gap-3">
                <div className="flex min-w-0 flex-col gap-0.5">
                  <DialogTitle className="truncate text-xl font-bold tracking-tight text-foreground sm:text-2xl">
                    {fullName || "Сотрудник"}
                  </DialogTitle>
                  <DialogDescription className="truncate text-sm font-medium text-muted-foreground">
                    {position}
                  </DialogDescription>
                </div>

                {employee && canUpdate ? (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={onEdit}
                    className="shrink-0 gap-1.5"
                  >
                    <PencilIcon className="size-4" />
                    Изменить
                  </Button>
                ) : null}
              </div>

              {employee ? (
                <div className="flex flex-wrap items-center gap-2 pt-0.5">
                  <EmployeeStatusBadge status={employee.status} />
                  <Badge variant="secondary" className="font-normal text-xs">
                    {employeeEmploymentLabel(employee.employmentType)}
                  </Badge>
                  {employee.includeInTimesheet ? (
                    <Badge
                      variant="outline"
                      className="border-emerald-500/30 text-emerald-600 dark:text-emerald-400 font-normal text-xs"
                    >
                      В табеле
                    </Badge>
                  ) : (
                    <Badge
                      variant="outline"
                      className="text-muted-foreground font-normal text-xs"
                    >
                      Без табеля
                    </Badge>
                  )}
                </div>
              ) : null}

              {phone ? (
                <div className="pt-0.5">
                  <EmployeePhoneLink phone={phone} />
                </div>
              ) : null}
            </div>
          </div>
        </DialogHeader>

        {employee ? (
          <EmployeeDetailsTabs
            employee={employee}
            objects={objects}
            objectNamesById={objectNamesById}
            canUpdate={canUpdate}
          />
        ) : null}

        <div className="flex shrink-0 items-center justify-end border-t border-border/60 bg-muted/20 px-6 py-3.5">
          <DialogClose render={<Button type="button" variant="outline" size="sm" />}>
            Закрыть
          </DialogClose>
        </div>
      </DialogContent>
    </Dialog>
  );
}

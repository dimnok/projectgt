"use client";

import { ChevronLeftIcon, PencilIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { EmployeeAvatarManager } from "@/features/employees/ui/shared/employee-avatar-manager";
import { EmployeeDetailsTabs } from "@/features/employees/ui/shared/employee-details-tabs";
import { EmployeePhoneActions } from "@/features/employees/ui/shared/employee-phone-actions";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import type {
  Employee,
  EmployeeObjectOption,
} from "@/features/employees/types/employee.types";
import { employeeEmploymentLabel } from "@/features/employees/utils/employee-employment";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

type EmployeeDetailsMobileProps = {
  employee: Employee;
  objects: EmployeeObjectOption[];
  objectNamesById: Map<string, string>;
  canUpdate: boolean;
  onBack: () => void;
  onEdit: () => void;
  onEmployeeUpdated: (employee: Employee) => void;
};

export function EmployeeDetailsMobile({
  employee,
  objects,
  objectNamesById,
  canUpdate,
  onBack,
  onEdit,
  onEmployeeUpdated,
}: EmployeeDetailsMobileProps) {
  const fullName = employeeFullName(employee);
  const position = employee.position.trim() || "Должность не указана";
  const phone = employee.phone.trim();

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <header className="shrink-0 border-b bg-background">
        <MobileAppBar
          title={fullName}
          className="border-b-0"
          leading={
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="rounded-full"
              aria-label="Назад к списку сотрудников"
              onClick={onBack}
            >
              <ChevronLeftIcon />
            </Button>
          }
          trailing={
            canUpdate ? (
              <Button
                type="button"
                variant="ghost"
                size="icon"
                className="rounded-full"
                aria-label="Изменить сотрудника"
                onClick={onEdit}
              >
                <PencilIcon />
              </Button>
            ) : undefined
          }
        />
        <div className="flex min-w-0 items-start gap-3 px-4 pb-3">
          <EmployeeAvatarManager
            employee={employee}
            canUpdate={canUpdate}
            actions="sheet"
            className="items-start"
            onPhotoChanged={(newUrl) => {
              onEmployeeUpdated({ ...employee, photoUrl: newUrl });
            }}
          />
          <div className="flex min-w-0 flex-1 flex-col gap-2 pt-0.5">
            <p className="text-base font-medium leading-snug">{position}</p>
            <div className="flex min-w-0 flex-wrap items-center gap-1">
              <EmployeeStatusBadge status={employee.status} compact />
              <Badge variant="secondary" className="font-normal">
                {employeeEmploymentLabel(employee.employmentType)}
              </Badge>
              <Badge
                variant="outline"
                className={
                  employee.includeInTimesheet
                    ? "border-emerald-500/30 font-normal text-emerald-600 dark:text-emerald-400"
                    : "font-normal text-muted-foreground"
                }
              >
                {employee.includeInTimesheet ? "В табеле" : "Без табеля"}
              </Badge>
            </div>
            {phone ? <EmployeePhoneActions phone={phone} /> : null}
          </div>
        </div>
      </header>
      <EmployeeDetailsTabs
        employee={employee}
        objects={objects}
        objectNamesById={objectNamesById}
        canUpdate={canUpdate}
        layout="page"
      />
    </div>
  );
}

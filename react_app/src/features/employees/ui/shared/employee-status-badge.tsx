"use client";

import { Badge } from "@/components/ui/badge";
import {
  employeeStatusLabel,
  type EmployeeStatus,
} from "@/features/employees/utils/employee-status";

const statusVariant: Record<
  EmployeeStatus,
  "success" | "default" | "warning" | "secondary" | "destructive"
> = {
  working: "success",
  vacation: "default",
  sickLeave: "warning",
  unpaidLeave: "secondary",
  fired: "destructive",
};

type EmployeeStatusBadgeProps = {
  status: EmployeeStatus;
};

export function EmployeeStatusBadge({ status }: EmployeeStatusBadgeProps) {
  return (
    <Badge variant={statusVariant[status]}>{employeeStatusLabel(status)}</Badge>
  );
}

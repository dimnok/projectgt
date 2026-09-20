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
  className?: string;
  compact?: boolean;
};

export function EmployeeStatusBadge({
  status,
  className,
  compact = false,
}: EmployeeStatusBadgeProps) {
  return (
    <Badge variant={statusVariant[status]} className={className}>
      {employeeStatusLabel(status, compact ? "short" : "full")}
    </Badge>
  );
}

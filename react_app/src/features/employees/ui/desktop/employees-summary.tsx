"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import type { Employee } from "@/features/employees/types/employee.types";
import { EMPLOYEE_STATUSES } from "@/features/employees/utils/employee-status";
import {
  countEmployeesByStatus,
  formatEmployeeCount,
} from "@/features/employees/utils/employee.utils";

type EmployeesSummaryProps = {
  employees: Employee[];
};

export function EmployeesSummary({ employees }: EmployeesSummaryProps) {
  const { total, byStatus } = countEmployeesByStatus(employees);

  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Сводка</CardTitle>
        <CardDescription>Все сотрудники компании</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col gap-6 max-lg:flex-row max-lg:flex-wrap max-lg:items-center max-lg:justify-between max-lg:gap-x-4 max-lg:gap-y-2">
        <div className="flex flex-col gap-1 max-lg:flex-row max-lg:items-baseline max-lg:gap-2">
          <p className="text-sm text-muted-foreground">Всего</p>
          <p className="font-heading text-2xl font-medium tabular-nums max-lg:text-base">
            {formatEmployeeCount(total)}
          </p>
        </div>
        <ul className="flex flex-col max-lg:flex-row max-lg:flex-wrap max-lg:items-center max-lg:gap-x-4 max-lg:gap-y-1">
          {EMPLOYEE_STATUSES.map((item) => (
            <li
              key={item}
              className="flex items-center gap-2 border-b py-3 last:border-b-0 max-lg:border-0 max-lg:py-0 lg:justify-between lg:gap-3"
            >
              <EmployeeStatusBadge status={item} />
              <span className="tabular-nums text-sm font-medium">
                {byStatus[item]}
              </span>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}

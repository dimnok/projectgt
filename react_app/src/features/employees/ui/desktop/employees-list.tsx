"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import type { Employee } from "@/features/employees/types/employee.types";
import { employeeEmploymentLabel } from "@/features/employees/utils/employee-employment";
import {
  employeeFullName,
  employeeInitials,
  objectNamesLabel,
} from "@/features/employees/utils/employee.utils";
import { formatPhone } from "@/lib/utils/phone";

type EmployeesListProps = {
  employees: Employee[];
  selectedId: string | null;
  objectNamesById: Map<string, string>;
  onSelect: (employee: Employee) => void;
};

function EmptyCell() {
  return <span className="text-muted-foreground">—</span>;
}

export function EmployeesList({
  employees,
  selectedId,
  objectNamesById,
  onSelect,
}: EmployeesListProps) {
  return (
    <Card size="sm" className="gap-0 overflow-hidden py-0 shadow-float">
      <Table>
        <TableCaption className="sr-only">Список сотрудников</TableCaption>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Сотрудник</TableHead>
            <TableHead>Должность</TableHead>
            <TableHead>Объект</TableHead>
            <TableHead>Вид</TableHead>
            <TableHead className="hidden md:table-cell">Телефон</TableHead>
            <TableHead>Статус</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {employees.map((employee) => {
            const isSelected = selectedId === employee.id;
            const fullName = employeeFullName(employee);
            const position = employee.position.trim();
            const objects = objectNamesLabel(
              employee.objectIds,
              objectNamesById
            );
            const phone = formatPhone(employee.phone);

            return (
              <TableRow
                key={employee.id}
                data-state={isSelected ? "selected" : undefined}
                className="cursor-pointer focus-visible:bg-muted/50 focus-visible:outline-none"
                onClick={() => onSelect(employee)}
                onKeyDown={(event) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    onSelect(employee);
                  }
                }}
                tabIndex={0}
              >
                <TableCell>
                  <div className="flex min-w-0 items-center gap-2">
                    <Avatar size="sm">
                      {employee.photoUrl ? (
                        <AvatarImage src={employee.photoUrl} alt={fullName} />
                      ) : null}
                      <AvatarFallback>
                        {employeeInitials(employee)}
                      </AvatarFallback>
                    </Avatar>
                    <span className="min-w-0 truncate font-medium">
                      {fullName}
                    </span>
                  </div>
                </TableCell>
                <TableCell className="max-w-48">
                  {position ? (
                    <span className="block truncate">{position}</span>
                  ) : (
                    <EmptyCell />
                  )}
                </TableCell>
                <TableCell className="max-w-56">
                  {objects ? (
                    <span className="block truncate" title={objects}>
                      {objects}
                    </span>
                  ) : (
                    <EmptyCell />
                  )}
                </TableCell>
                <TableCell>
                  {employeeEmploymentLabel(employee.employmentType)}
                </TableCell>
                <TableCell className="hidden md:table-cell">
                  {phone ? phone : <EmptyCell />}
                </TableCell>
                <TableCell>
                  <EmployeeStatusBadge status={employee.status} />
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </Card>
  );
}

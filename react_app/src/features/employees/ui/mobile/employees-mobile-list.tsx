"use client";

import { PhoneIcon } from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import type { Employee } from "@/features/employees/types/employee.types";
import {
  employeeFullName,
  employeeInitials,
} from "@/features/employees/utils/employee.utils";
import { formatPhone, normalizeRuPhoneE164 } from "@/lib/utils/phone";

type EmployeesMobileListProps = {
  employees: Employee[];
  onSelect: (employee: Employee) => void;
};

function letterOf(employee: Employee) {
  const letter = employee.lastName.trim().charAt(0).toLocaleUpperCase("ru");
  return letter || "#";
}

function groupEmployees(employees: Employee[]) {
  const groups: { letter: string; items: Employee[] }[] = [];

  for (const employee of employees) {
    const letter = letterOf(employee);
    const current = groups[groups.length - 1];
    if (current && current.letter === letter) {
      current.items.push(employee);
    } else {
      groups.push({ letter, items: [employee] });
    }
  }

  return groups;
}

function telHrefOf(employee: Employee) {
  if (!employee.phone.trim()) {
    return null;
  }
  const normalized = normalizeRuPhoneE164(employee.phone);
  if (normalized) {
    return `tel:${normalized}`;
  }
  const digits = employee.phone.replace(/\D/g, "");
  return digits ? `tel:${digits}` : null;
}

export function EmployeesMobileList({
  employees,
  onSelect,
}: EmployeesMobileListProps) {
  const groups = groupEmployees(employees);

  return (
    <div className="min-w-0">
      {groups.map((group) => (
        <section key={group.letter} className="min-w-0">
          <h2 className="sticky top-0 z-10 bg-background/95 px-4 py-1.5 text-xs font-semibold tracking-wide text-muted-foreground backdrop-blur-sm">
            {group.letter}
          </h2>
          <ul className="min-w-0">
            {group.items.map((employee, index) => {
              const fullName = employeeFullName(employee);
              const position =
                employee.position.trim() || "Должность не указана";
              const phone = formatPhone(employee.phone);
              const telHref = telHrefOf(employee);
              const isLast = index === group.items.length - 1;

              return (
                <li key={employee.id} className="min-w-0">
                  <div className="flex min-w-0 items-center gap-3 px-4 py-2">
                    <button
                      type="button"
                      className="flex min-w-0 flex-1 items-center gap-3 text-left"
                      onClick={() => onSelect(employee)}
                    >
                      <Avatar className="size-14 shrink-0 after:rounded-full">
                        {employee.photoUrl ? (
                          <AvatarImage src={employee.photoUrl} alt={fullName} />
                        ) : null}
                        <AvatarFallback className="text-base font-semibold">
                          {employeeInitials(employee)}
                        </AvatarFallback>
                      </Avatar>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-[17px] font-medium leading-tight">
                          {fullName}
                        </span>
                        <span className="mt-1 block truncate text-sm leading-tight text-muted-foreground">
                          {position}
                        </span>
                      </span>
                    </button>
                    {telHref && phone ? (
                      <a
                        href={telHref}
                        aria-label={`Позвонить ${fullName}`}
                        className="flex size-8 shrink-0 items-center justify-center text-muted-foreground"
                      >
                        <PhoneIcon className="size-4" />
                      </a>
                    ) : (
                      <span className="size-8 shrink-0" />
                    )}
                  </div>
                  {isLast ? null : (
                    <div className="flex min-w-0">
                      <div className="w-[5.25rem] shrink-0" aria-hidden />
                      <div className="min-w-0 flex-1 border-b border-border" />
                    </div>
                  )}
                </li>
              );
            })}
          </ul>
        </section>
      ))}
    </div>
  );
}

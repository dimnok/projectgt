"use client";

import { EmployeesDesktop } from "@/features/employees/ui/desktop/employees-desktop";
import { EmployeesMobile } from "@/features/employees/ui/mobile/employees-mobile";
import { useIsMobile } from "@/hooks/use-mobile";

export function EmployeesScreen() {
  const isMobile = useIsMobile();

  if (isMobile) {
    return <EmployeesMobile />;
  }

  return <EmployeesDesktop />;
}

"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useMemo } from "react";

import { useEmployees } from "@/features/employees/hooks/use-employees";
import type { Employee } from "@/features/employees/types/employee.types";
import { getPayrollFifo } from "@/features/payrolls/api/get-payroll-fifo";
import { getPayrollMonth } from "@/features/payrolls/api/get-payroll-month";
import type { PayrollEmployeeStatusFilter } from "@/features/payrolls/types/payroll.types";
import {
  buildPayrollGridRows,
  calculatePayrollTotals,
  filterEmployeesBySearch,
  filterEmployeesByStatus,
  filterRowsByEmployeeName,
  filterRowsByEmployeeStatus,
  mergeZeroActivityRows,
} from "@/features/payrolls/utils/payroll-rows";
import { usePermissions } from "@/hooks/use-permissions";

type UsePayrollsParams = {
  year: number;
  month: number;
  selectedObjectIds: string[];
  search: string;
  status: PayrollEmployeeStatusFilter;
};

/** Вкладка ФОТ: расчёт месяца и FIFO-распределение выплат. */
export function usePayrolls({
  year,
  month,
  selectedObjectIds,
  search,
  status,
}: UsePayrollsParams) {
  const { isReady: permissionsReady } = usePermissions();

  const employeesQuery = useEmployees();

  const monthQuery = useQuery({
    queryKey: ["payroll-month", year, month, selectedObjectIds],
    queryFn: () => getPayrollMonth({ year, month, selectedObjectIds }),
    enabled: permissionsReady,
    placeholderData: keepPreviousData,
  });

  const fifoQuery = useQuery({
    queryKey: ["payroll-fifo", year],
    queryFn: () => getPayrollFifo(year),
    enabled: permissionsReady,
    placeholderData: keepPreviousData,
  });

  const employees = useMemo(
    () => employeesQuery.data ?? [],
    [employeesQuery.data]
  );

  const employeesById = useMemo(() => {
    const map = new Map<string, Employee>();
    for (const employee of employees) {
      map.set(employee.id, employee);
    }
    return map;
  }, [employees]);

  const employeesBySearch = useMemo(
    () => filterEmployeesBySearch(employees, search),
    [employees, search]
  );

  const employeesByStatus = useMemo(
    () => filterEmployeesByStatus(employeesBySearch, status),
    [employeesBySearch, status]
  );

  const fifo = useMemo(() => fifoQuery.data ?? new Map(), [fifoQuery.data]);

  const hasObjectFilter = selectedObjectIds.length > 0;

  const gridRows = useMemo(() => {
    const monthRows = monthQuery.data ?? [];
    const byName = filterRowsByEmployeeName(monthRows, employeesById, search);
    const byStatus = filterRowsByEmployeeStatus(
      byName,
      employeesByStatus,
      status
    );
    const merged = mergeZeroActivityRows(
      byStatus,
      employeesByStatus,
      fifo,
      year,
      month,
      hasObjectFilter
    );
    return buildPayrollGridRows(merged, employeesById, fifo, month);
  }, [
    monthQuery.data,
    employeesById,
    employeesByStatus,
    search,
    status,
    year,
    month,
    fifo,
    hasObjectFilter,
  ]);

  const totals = useMemo(
    () => calculatePayrollTotals(gridRows, employeesByStatus, fifo, month),
    [gridRows, employeesByStatus, fifo, month]
  );

  return {
    gridRows,
    totals,
    isLoading:
      !permissionsReady ||
      employeesQuery.isLoading ||
      monthQuery.isLoading ||
      fifoQuery.isLoading,
    isFetching: monthQuery.isFetching || fifoQuery.isFetching,
    isError: employeesQuery.isError || monthQuery.isError || fifoQuery.isError,
    error: employeesQuery.error ?? monthQuery.error ?? fifoQuery.error,
    refetch: () => {
      void monthQuery.refetch();
      void fifoQuery.refetch();
    },
  };
}

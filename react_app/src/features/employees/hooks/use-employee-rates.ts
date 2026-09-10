"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { getEmployeeRates } from "@/features/employees/api/get-employee-rates";
import { setEmployeeRate } from "@/features/employees/api/set-employee-rate";
import type { EmployeeRateDraft } from "@/features/employees/types/employee.types";
import { employeesQueryKey } from "@/features/employees/hooks/use-employees";

export function employeeRatesQueryKey(employeeId: string) {
  return ["employee-rates", employeeId] as const;
}

export function useEmployeeRates(employeeId: string, enabled: boolean) {
  return useQuery({
    queryKey: employeeRatesQueryKey(employeeId),
    queryFn: () => getEmployeeRates(employeeId),
    enabled: enabled && Boolean(employeeId),
  });
}

export function useSetEmployeeRate(employeeId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: EmployeeRateDraft) =>
      setEmployeeRate(employeeId, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: employeeRatesQueryKey(employeeId),
      });
      void queryClient.invalidateQueries({ queryKey: employeesQueryKey });
    },
  });
}

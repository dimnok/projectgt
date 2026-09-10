"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createEmployeeTripRate,
  getEmployeeTripRates,
  updateEmployeeTripRate,
} from "@/features/employees/api/save-employee-trip-rate";
import type { EmployeeTripRateDraft } from "@/features/employees/types/employee.types";

export function employeeTripRatesQueryKey(employeeId: string) {
  return ["employee-trip-rates", employeeId] as const;
}

export function useEmployeeTripRates(employeeId: string, enabled: boolean) {
  return useQuery({
    queryKey: employeeTripRatesQueryKey(employeeId),
    queryFn: () => getEmployeeTripRates(employeeId),
    enabled: enabled && Boolean(employeeId),
  });
}

export function useSaveEmployeeTripRate(employeeId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      rateId,
      draft,
    }: {
      rateId?: string;
      draft: EmployeeTripRateDraft;
    }) =>
      rateId
        ? updateEmployeeTripRate(employeeId, rateId, draft)
        : createEmployeeTripRate(employeeId, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: employeeTripRatesQueryKey(employeeId),
      });
    },
  });
}

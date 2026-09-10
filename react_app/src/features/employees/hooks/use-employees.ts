"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { createEmployee } from "@/features/employees/api/create-employee";
import { getEmployeePositions } from "@/features/employees/api/get-employee-positions";
import { getEmployees } from "@/features/employees/api/get-employees";
import { updateEmployee } from "@/features/employees/api/update-employee";
import type {
  Employee,
  EmployeeCreateDraft,
  EmployeeDraft,
} from "@/features/employees/types/employee.types";

export const employeesQueryKey = ["employees"] as const;
const employeePositionsQueryKey = ["employee-positions"] as const;

export function useEmployees() {
  return useQuery({
    queryKey: employeesQueryKey,
    queryFn: getEmployees,
  });
}

export function useEmployeePositions() {
  return useQuery({
    queryKey: employeePositionsQueryKey,
    queryFn: async () => {
      try {
        return await getEmployeePositions();
      } catch {
        return [];
      }
    },
  });
}

export function useCreateEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: EmployeeCreateDraft) => createEmployee(draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: employeesQueryKey });
      void queryClient.invalidateQueries({
        queryKey: employeePositionsQueryKey,
      });
    },
  });
}

export function useUpdateEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      employee,
      draft,
    }: {
      employee: Employee;
      draft: EmployeeDraft;
    }) => updateEmployee(employee, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: employeesQueryKey });
      void queryClient.invalidateQueries({
        queryKey: employeePositionsQueryKey,
      });
    },
  });
}


"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  deleteEmployeePhoto,
  uploadEmployeePhoto,
} from "@/features/employees/api/manage-employee-photo";
import { employeesQueryKey } from "@/features/employees/hooks/use-employees";
import type { Employee } from "@/features/employees/types/employee.types";

export function useUploadEmployeePhoto() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      employee,
      file,
    }: {
      employee: Employee;
      file: File;
    }) => uploadEmployeePhoto(employee, file),
    onSuccess: (newPhotoUrl, variables) => {
      // 1. Invalidate employees query to refresh data
      void queryClient.invalidateQueries({ queryKey: employeesQueryKey });

      // 2. Optimistically update existing employees array in cache
      queryClient.setQueryData<Employee[]>(employeesQueryKey, (old) => {
        if (!old) return old;
        return old.map((emp) =>
          emp.id === variables.employee.id
            ? { ...emp, photoUrl: newPhotoUrl }
            : emp
        );
      });
    },
  });
}

export function useDeleteEmployeePhoto() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (employee: Employee) => deleteEmployeePhoto(employee),
    onSuccess: (_, employee) => {
      // 1. Invalidate employees query
      void queryClient.invalidateQueries({ queryKey: employeesQueryKey });

      // 2. Optimistically update existing employees array in cache
      queryClient.setQueryData<Employee[]>(employeesQueryKey, (old) => {
        if (!old) return old;
        return old.map((emp) =>
          emp.id === employee.id ? { ...emp, photoUrl: null } : emp
        );
      });
    },
  });
}

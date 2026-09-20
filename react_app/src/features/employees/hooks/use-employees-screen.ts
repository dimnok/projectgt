"use client";

import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import { useEmployeeFilters } from "@/features/employees/hooks/use-employee-filters";
import {
  useCreateEmployee,
  useEmployeePositions,
  useEmployees,
  useUpdateEmployee,
} from "@/features/employees/hooks/use-employees";
import type {
  Employee,
  EmployeeCreateDraft,
  EmployeeDraft,
} from "@/features/employees/types/employee.types";
import {
  filterEmployees,
  sortEmployeesByName,
  uniquePositions,
} from "@/features/employees/utils/employee.utils";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch } from "@/layouts/desktop/app-search";

export function useEmployeesScreen() {
  const { data, isLoading, isError, error } = useEmployees();
  const { data: objectsData } = useObjects();
  const { data: rpcPositions } = useEmployeePositions();
  const { status, setStatus, objectId, setObjectId } = useEmployeeFilters();
  const { query } = useAppSearch();
  const { can } = usePermissions();
  const createEmployee = useCreateEmployee();
  const updateEmployee = useUpdateEmployee();

  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [selectedDraft, setSelectedDraft] = useState<Employee | null>(null);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [editorEmployee, setEditorEmployee] = useState<Employee | null>(null);

  const selectedEmployee = useMemo(() => {
    if (!selectedId) {
      return null;
    }
    return (
      (data ?? []).find((item) => item.id === selectedId) ??
      (selectedDraft?.id === selectedId ? selectedDraft : null)
    );
  }, [data, selectedDraft, selectedId]);

  function selectEmployee(employee: Employee | null) {
    setSelectedId(employee?.id ?? null);
    setSelectedDraft(employee);
  }

  const objects = useMemo(
    () =>
      sortObjectsByName(objectsData ?? []).map((object) => ({
        id: object.id,
        name: object.name,
      })),
    [objectsData]
  );
  const objectNamesById = useMemo(
    () => new Map(objects.map((object) => [object.id, object.name])),
    [objects]
  );

  useEffect(() => {
    if (objectId === "all") {
      return;
    }
    if (!objects.some((object) => object.id === objectId)) {
      setObjectId("all");
    }
  }, [objectId, objects, setObjectId]);

  const employees = useMemo(
    () =>
      sortEmployeesByName(
        filterEmployees(data ?? [], { search: query, status, objectId })
      ),
    [data, objectId, query, status]
  );
  const positions = useMemo(() => {
    const fromList = uniquePositions(data ?? []);
    const names = new Set([...(rpcPositions ?? []), ...fromList]);
    return [...names].sort((a, b) =>
      a.localeCompare(b, "ru", { sensitivity: "base" })
    );
  }, [data, rpcPositions]);

  function handleCreate(draft: EmployeeCreateDraft) {
    createEmployee.mutate(draft, {
      onSuccess: (created) => {
        setIsCreateOpen(false);
        selectEmployee(created);
        toast.success("Сотрудник добавлен");
      },
      onError: (reason) =>
        toast.error(
          reason instanceof Error
            ? reason.message
            : "Не удалось добавить сотрудника"
        ),
    });
  }

  function handleUpdate(draft: EmployeeDraft) {
    if (!editorEmployee) {
      return;
    }
    updateEmployee.mutate(
      { employee: editorEmployee, draft },
      {
        onSuccess: (updated) => {
          setEditorEmployee(null);
          selectEmployee(updated);
          toast.success("Изменения сохранены");
        },
        onError: (reason) =>
          toast.error(
            reason instanceof Error
              ? reason.message
              : "Не удалось сохранить сотрудника"
          ),
      }
    );
  }

  function openEditor() {
    if (selectedEmployee) {
      setEditorEmployee(selectedEmployee);
    }
  }

  return {
    allEmployees: data ?? [],
    employees,
    objects,
    objectNamesById,
    positions,
    status,
    setStatus,
    objectId,
    setObjectId,
    selectedEmployee,
    selectEmployee,
    setSelectedDraft,
    isCreateOpen,
    setIsCreateOpen,
    editorEmployee,
    setEditorEmployee,
    openEditor,
    handleCreate,
    handleUpdate,
    canCreate: can("employees", "create"),
    canUpdate: can("employees", "update"),
    canExport: can("employees", "export"),
    isCreating: createEmployee.isPending,
    isUpdating: updateEmployee.isPending,
    isLoading,
    isError,
    error,
  };
}

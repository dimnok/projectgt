"use client";

import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { EmployeesFilters } from "@/features/employees/ui/desktop/employees-filters";
import { EmployeesList } from "@/features/employees/ui/desktop/employees-list";
import { EmployeesSummary } from "@/features/employees/ui/desktop/employees-summary";
import { EmployeeCreateDialog } from "@/features/employees/ui/shared/employee-create-dialog";
import { EmployeeDetailsDialog } from "@/features/employees/ui/shared/employee-details-dialog";
import { EmployeeFormDialog } from "@/features/employees/ui/shared/employee-form-dialog";
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
import { useAppSearch, AppSearchField } from "@/layouts/desktop/app-search";

export function EmployeesDesktop() {
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

  if (isLoading) {
    return <Loading />;
  }

  if (isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  return (
    <>
      <div className="grid min-h-fit min-w-0 w-full flex-1 grid-cols-1 content-start items-start gap-3 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6">
        <div className="min-w-0 w-full lg:order-1">
          {employees.length === 0 ? (
            <EmptyState
              title="Сотрудников нет"
              description="Добавьте сотрудника или измените фильтры."
            />
          ) : (
            <EmployeesList
              employees={employees}
              selectedId={selectedEmployee?.id ?? null}
              objectNamesById={objectNamesById}
              onSelect={selectEmployee}
            />
          )}
        </div>
        <aside className="order-first flex min-w-0 w-full flex-col gap-3 lg:sticky lg:top-0 lg:order-2 lg:gap-6 lg:self-start">
          <EmployeesFilters
            status={status}
            objectId={objectId}
            objects={objects}
            onStatusChange={setStatus}
            onObjectChange={setObjectId}
            canCreate={can("employees", "create")}
            onCreate={() => setIsCreateOpen(true)}
          />
          <EmployeesSummary employees={data ?? []} />
          <AppSearchField className="lg:hidden" />
        </aside>
      </div>
      <EmployeeCreateDialog
        open={isCreateOpen}
        objects={objects}
        isSaving={createEmployee.isPending}
        onOpenChange={setIsCreateOpen}
        onSubmit={handleCreate}
      />
      <EmployeeDetailsDialog
        employee={selectedEmployee}
        objects={objects}
        objectNamesById={objectNamesById}
        canUpdate={can("employees", "update")}
        onEmployeeUpdated={setSelectedDraft}
        onOpenChange={(open) => {
          if (!open) {
            selectEmployee(null);
          }
        }}
        onEdit={() => {
          if (selectedEmployee) {
            setEditorEmployee(selectedEmployee);
          }
        }}
      />
      <EmployeeFormDialog
        employee={editorEmployee}
        objects={objects}
        positions={positions}
        isSaving={updateEmployee.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setEditorEmployee(null);
          }
        }}
        onSubmit={handleUpdate}
      />
    </>
  );
}

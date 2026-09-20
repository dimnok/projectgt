"use client";

import { useState } from "react";
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
import { useEmployeesScreen } from "@/features/employees/hooks/use-employees-screen";
import { exportEmployeesToExcel } from "@/features/employees/utils/export-employees-excel";
import { AppSearchField } from "@/layouts/desktop/app-search";

export function EmployeesDesktop() {
  const screen = useEmployeesScreen();
  const [isExporting, setIsExporting] = useState(false);

  async function handleExport() {
    if (screen.employees.length === 0) {
      toast.warning("Нет сотрудников для выгрузки");
      return;
    }

    try {
      setIsExporting(true);
      await exportEmployeesToExcel({
        employees: screen.employees,
        objectNamesById: screen.objectNamesById,
      });
      toast.success("Excel-файл сформирован");
    } catch (reason) {
      toast.error(
        reason instanceof Error
          ? reason.message
          : "Не удалось сформировать Excel"
      );
    } finally {
      setIsExporting(false);
    }
  }

  if (screen.isLoading) {
    return <Loading />;
  }

  if (screen.isError) {
    return (
      <ErrorState
        message={
          screen.error instanceof Error
            ? screen.error.message
            : "Неизвестная ошибка"
        }
      />
    );
  }

  return (
    <>
      <div
        data-fill-viewport
        className="grid h-full min-h-0 min-w-0 w-full flex-1 grid-cols-1 gap-3 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6"
      >
        <div className="flex h-full min-h-0 min-w-0 w-full flex-col lg:order-1">
          {screen.employees.length === 0 ? (
            <div className="flex h-full min-h-0 min-w-0 w-full flex-1 items-center justify-center rounded-xl bg-card p-6 ring-1 ring-foreground/10 shadow-float">
              <EmptyState
                title="Сотрудников нет"
                description="Добавьте сотрудника или измените фильтры."
              />
            </div>
          ) : (
            <EmployeesList
              employees={screen.employees}
              selectedId={screen.selectedEmployee?.id ?? null}
              objectNamesById={screen.objectNamesById}
              onSelect={screen.selectEmployee}
            />
          )}
        </div>
        <aside className="order-first flex min-h-0 min-w-0 w-full flex-col gap-3 lg:order-2 lg:gap-6">
          <div className="flex shrink-0 min-w-0 flex-col gap-2">
            <AppSearchField
              variant="aside"
              placeholder="Поиск по ФИО, должности, телефону..."
              aria-label="Поиск по сотрудникам"
            />
            <EmployeesFilters
              status={screen.status}
              objectId={screen.objectId}
              objects={screen.objects}
              onStatusChange={screen.setStatus}
              onObjectChange={screen.setObjectId}
              canCreate={screen.canCreate}
              onCreate={() => screen.setIsCreateOpen(true)}
              canExport={screen.canExport}
              isExporting={isExporting}
              onExport={() => {
                void handleExport();
              }}
            />
          </div>
          <EmployeesSummary employees={screen.allEmployees} />
        </aside>
      </div>
      <EmployeeCreateDialog
        open={screen.isCreateOpen}
        objects={screen.objects}
        isSaving={screen.isCreating}
        onOpenChange={screen.setIsCreateOpen}
        onSubmit={screen.handleCreate}
      />
      <EmployeeDetailsDialog
        employee={screen.selectedEmployee}
        objects={screen.objects}
        objectNamesById={screen.objectNamesById}
        canUpdate={screen.canUpdate}
        onEmployeeUpdated={screen.setSelectedDraft}
        onOpenChange={(open) => {
          if (!open) {
            screen.selectEmployee(null);
          }
        }}
        onEdit={screen.openEditor}
      />
      <EmployeeFormDialog
        employee={screen.editorEmployee}
        objects={screen.objects}
        positions={screen.positions}
        isSaving={screen.isUpdating}
        onOpenChange={(open) => {
          if (!open) {
            screen.setEditorEmployee(null);
          }
        }}
        onSubmit={screen.handleUpdate}
      />
    </>
  );
}

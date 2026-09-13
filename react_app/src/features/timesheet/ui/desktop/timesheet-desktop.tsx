"use client";

import { Loader2Icon } from "lucide-react";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Button } from "@/components/ui/button";
import type { Employee } from "@/features/employees/types/employee.types";
import { EmployeeDetailsDialog } from "@/features/employees/ui/shared/employee-details-dialog";
import { useTimesheet } from "@/features/timesheet/hooks/use-timesheet";
import { TimesheetGrid } from "@/features/timesheet/ui/desktop/timesheet-grid";
import { TimesheetToolbar } from "@/features/timesheet/ui/desktop/timesheet-toolbar";
import { TimesheetAttendanceDialog } from "@/features/timesheet/ui/shared/timesheet-attendance-dialog";
import { exportTimesheetToExcel } from "@/features/timesheet/utils/export-timesheet-excel";
import { usePermissions } from "@/hooks/use-permissions";

export function TimesheetDesktop() {
  const { can } = usePermissions();
  const canEditAttendance = can("timesheet", "update") || can("timesheet", "create");
  const canExport = can("timesheet", "export");

  const {
    filters,
    selectedEmployeeIds,
    toggleEmployeeSelection,
    selectAllEmployees,
    clearEmployeeSelection,
    goToPreviousMonth,
    goToNextMonth,
    setSelectedObjectIds,
    setSelectedPositionKeys,
    setListScope,
    setOpenShiftScope,
    setSearchQuery,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
    data,
    daysHeader,
    positionOptions,
    gridRows,
    dayTotals,
    grandTotalHours,
  } = useTimesheet();

  const [attendanceEmployee, setAttendanceEmployee] = useState<Employee | null>(
    null
  );
  const [detailsEmployee, setDetailsEmployee] = useState<Employee | null>(null);
  const [isExporting, setIsExporting] = useState(false);

  // Objects mapped for EmployeeDetailsDialog
  const employeeObjectOptions = useMemo(() => {
    if (!data?.objects) return [];
    return data.objects.map((o) => ({ id: o.id, name: o.name }));
  }, [data?.objects]);

  const objectNamesById = useMemo(() => {
    const map = new Map<string, string>();
    if (!data?.objects) return map;
    for (const o of data.objects) {
      map.set(o.id, o.name);
    }
    return map;
  }, [data?.objects]);

  const handleExportExcel = async () => {
    if (!data || gridRows.length === 0) {
      toast.warning("Нет строк для выгрузки");
      return;
    }

    try {
      setIsExporting(true);
      await exportTimesheetToExcel({
        year: filters.year,
        month: filters.month,
        employees: data.employees,
        entries: data.entries,
        objectOptions: data.objectOptions,
        hasObjectFilter: filters.selectedObjectIds.length > 0,
        selectedPositionKeys: filters.selectedPositionKeys,
        onlyEmployeeIds:
          selectedEmployeeIds.size > 0 ? selectedEmployeeIds : undefined,
      });
      toast.success("Excel-файл табеля успешно сформирован");
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Не удалось сформировать Excel"
      );
    } finally {
      setIsExporting(false);
    }
  };

  if (isError && !data) {
    return (
      <div className="flex flex-col gap-3">
        <ErrorState
          title="Ошибка загрузки табеля"
          message={error?.message ?? "Не удалось загрузить данные табеля"}
        />
        <div className="flex justify-end">
          <Button type="button" variant="outline" size="sm" onClick={() => refetch()}>
            Повторить попытку
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div
      data-fill-viewport
      className="flex flex-col gap-3 min-w-0 w-full flex-1 h-full min-h-0 overflow-hidden"
    >
      {/* Header toolbar */}
      <TimesheetToolbar
        year={filters.year}
        month={filters.month}
        searchQuery={filters.searchQuery}
        onSearchChange={setSearchQuery}
        onPrevMonth={goToPreviousMonth}
        onNextMonth={goToNextMonth}
        objectOptions={data?.objectOptions ?? []}
        selectedObjectIds={filters.selectedObjectIds}
        onSelectedObjectIdsChange={setSelectedObjectIds}
        positionOptions={positionOptions}
        selectedPositionKeys={filters.selectedPositionKeys}
        onSelectedPositionKeysChange={setSelectedPositionKeys}
        listScope={filters.listScope}
        openShiftScope={filters.openShiftScope}
        periodContainsToday={data?.periodContainsToday ?? false}
        onListScopeChange={setListScope}
        onOpenShiftScopeChange={setOpenShiftScope}
        selectedCount={selectedEmployeeIds.size}
        onExportExcel={handleExportExcel}
        canExport={canExport}
        isExporting={isExporting}
        isLoading={isLoading}
      />

      {/* Main Grid */}
      {isLoading && !data ? (
        <Loading />
      ) : (
        <div className="relative flex-1 min-h-0 min-w-0">
          {isFetching ? (
            <div className="absolute top-2 right-4 z-50 flex items-center gap-1.5 rounded-full bg-background/85 px-3 py-1 text-[11px] text-muted-foreground shadow-xs border border-border/80 backdrop-blur-md">
              <Loader2Icon className="h-3 w-3 animate-spin text-primary" />
              <span>Обновление данных...</span>
            </div>
          ) : null}

          <TimesheetGrid
            rows={gridRows}
            daysHeader={daysHeader}
            dayTotals={dayTotals}
            grandTotalHours={grandTotalHours}
            objectOptions={data?.objectOptions ?? []}
            selectedEmployeeIds={selectedEmployeeIds}
            onToggleSelectEmployee={toggleEmployeeSelection}
            onSelectAll={selectAllEmployees}
            onClearSelection={clearEmployeeSelection}
            onOpenAttendance={
              canEditAttendance
                ? (emp) => setAttendanceEmployee(emp)
                : undefined
            }
            onOpenEmployeeDetails={(emp) => setDetailsEmployee(emp)}
            isLoading={isLoading}
          />
        </div>
      )}

      {/* Attendance Dialog */}
      <TimesheetAttendanceDialog
        open={Boolean(attendanceEmployee)}
        onOpenChange={(open) => {
          if (!open) setAttendanceEmployee(null);
        }}
        employee={attendanceEmployee}
        year={filters.year}
        month={filters.month}
        objects={data?.objects ?? []}
        onSuccess={() => refetch()}
      />

      {/* Employee Details Dialog */}
      <EmployeeDetailsDialog
        employee={detailsEmployee}
        objects={employeeObjectOptions}
        objectNamesById={objectNamesById}
        canUpdate={false}
        onOpenChange={(open) => {
          if (!open) setDetailsEmployee(null);
        }}
        onEdit={() => {}}
      />
    </div>
  );
}

"use client";

import { useMemo, useState } from "react";

import { Tabs, TabsContent } from "@/components/ui/tabs";
import { useEmployees } from "@/features/employees/hooks/use-employees";
import { EmployeeDetailsDialog } from "@/features/employees/ui/shared/employee-details-dialog";
import { useObjects } from "@/features/objects/hooks/use-objects";
import type { PayrollPeriod } from "@/features/payrolls/types/payroll.types";
import { PayrollsFotTab } from "@/features/payrolls/ui/desktop/payrolls-fot-tab";
import { PayrollsPayoutsTab } from "@/features/payrolls/ui/desktop/payrolls-payouts-tab";
import {
  PayrollsTabList,
  type PayrollTabValue,
} from "@/features/payrolls/ui/desktop/payrolls-tabs";
import { PayrollsTransactionsTab } from "@/features/payrolls/ui/desktop/payrolls-transactions-tab";
import { getPeriodLabel } from "@/features/payrolls/utils/payroll.utils";
import {
  getNextMonth,
  getPreviousMonth,
  isCurrentMonth,
} from "@/features/timesheet/utils/timesheet-date";
import { useDebouncedValue } from "@/hooks/use-debounced-value";
import { usePermissions } from "@/hooks/use-permissions";

/**
 * Экран ФОТ: вкладки ФОТ / Премии / Удержания / Выплаты.
 * Фильтры периода, поиска и объектов общие для всех вкладок.
 */
export function PayrollsDesktop() {
  const { can } = usePermissions();
  const canViewEmployees = can("employees", "read");
  const canExport = can("payroll", "export");

  const now = new Date();
  const [activeTab, setActiveTab] = useState<PayrollTabValue>("fot");
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [allTime, setAllTime] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedObjectIds, setSelectedObjectIds] = useState<string[]>([]);
  const [detailsEmployeeId, setDetailsEmployeeId] = useState<string | null>(
    null
  );

  const search = useDebouncedValue(searchQuery, 150);

  const employeesQuery = useEmployees();
  const objectsQuery = useObjects();

  const period: PayrollPeriod = allTime
    ? { mode: "all" }
    : { mode: "month", year, month };
  const monthLabel = getPeriodLabel({ mode: "month", year, month });
  const isCurrent = isCurrentMonth(year, month);

  const goToPreviousMonth = () => {
    const previous = getPreviousMonth(year, month);
    setYear(previous.year);
    setMonth(previous.month);
  };

  const goToNextMonth = () => {
    if (isCurrent) {
      return;
    }
    const next = getNextMonth(year, month);
    setYear(next.year);
    setMonth(next.month);
  };

  const objectOptions = useMemo(
    () =>
      (objectsQuery.data ?? []).map((object) => ({
        key: object.id,
        label: object.name,
      })),
    [objectsQuery.data]
  );

  const listFilters = {
    period,
    monthLabel,
    isCurrentMonth: isCurrent,
    allTime,
    setAllTime,
    goToPreviousMonth,
    goToNextMonth,
    search,
    setSearch: setSearchQuery,
    canExport,
  };

  const openEmployeeDetails = canViewEmployees
    ? setDetailsEmployeeId
    : undefined;

  const detailsEmployee = useMemo(() => {
    if (!detailsEmployeeId) {
      return null;
    }
    return (
      (employeesQuery.data ?? []).find(
        (employee) => employee.id === detailsEmployeeId
      ) ?? null
    );
  }, [detailsEmployeeId, employeesQuery.data]);

  const employeeObjectOptions = useMemo(
    () => objectOptions.map((option) => ({ id: option.key, name: option.label })),
    [objectOptions]
  );

  const objectNamesById = useMemo(() => {
    const map = new Map<string, string>();
    for (const option of objectOptions) {
      map.set(option.key, option.label);
    }
    return map;
  }, [objectOptions]);

  return (
    <>
      <Tabs
        value={activeTab}
        onValueChange={(value) => setActiveTab(value as PayrollTabValue)}
        data-fill-viewport
        className="flex h-full min-h-0 w-full min-w-0 flex-1 flex-col gap-0 overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10 shadow-float"
      >
        <PayrollsTabList />

        <TabsContent value="fot" className="flex min-h-0 flex-1 flex-col">
          <PayrollsFotTab
            year={year}
            month={month}
            isCurrentMonth={isCurrent}
            onPrevMonth={goToPreviousMonth}
            onNextMonth={goToNextMonth}
            search={search}
            onSearchChange={setSearchQuery}
            objectOptions={objectOptions}
            selectedObjectIds={selectedObjectIds}
            onSelectedObjectIdsChange={setSelectedObjectIds}
            canExport={canExport}
            onOpenEmployeeDetails={openEmployeeDetails}
          />
        </TabsContent>

        <TabsContent value="bonuses" className="flex min-h-0 flex-1 flex-col">
          <PayrollsTransactionsTab
            kind="bonus"
            {...listFilters}
            objectOptions={objectOptions}
            selectedObjectIds={selectedObjectIds}
            setSelectedObjectIds={setSelectedObjectIds}
            onOpenEmployeeDetails={openEmployeeDetails}
          />
        </TabsContent>

        <TabsContent value="penalties" className="flex min-h-0 flex-1 flex-col">
          <PayrollsTransactionsTab
            kind="penalty"
            {...listFilters}
            objectOptions={objectOptions}
            selectedObjectIds={selectedObjectIds}
            setSelectedObjectIds={setSelectedObjectIds}
            onOpenEmployeeDetails={openEmployeeDetails}
          />
        </TabsContent>

        <TabsContent value="payouts" className="flex min-h-0 flex-1 flex-col">
          <PayrollsPayoutsTab
            {...listFilters}
            onOpenEmployeeDetails={openEmployeeDetails}
          />
        </TabsContent>
      </Tabs>

      <EmployeeDetailsDialog
        employee={detailsEmployee}
        objects={employeeObjectOptions}
        objectNamesById={objectNamesById}
        canUpdate={false}
        onOpenChange={(open) => {
          if (!open) {
            setDetailsEmployeeId(null);
          }
        }}
        onEdit={() => {}}
      />
    </>
  );
}

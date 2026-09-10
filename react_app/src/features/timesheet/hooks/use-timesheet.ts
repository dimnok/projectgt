"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import type { Employee } from "@/features/employees/types/employee.types";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import {
  getTimesheetData,
  type TimesheetDataResult,
} from "@/features/timesheet/api/get-timesheet-data";
import {
  saveEmployeeAttendanceBatch,
  type AttendanceBatchRow,
} from "@/features/timesheet/api/save-employee-attendance";
import type {
  DayCellData,
  TimesheetEmployeeListScope,
  TimesheetEntry,
  TimesheetFilters,
  TimesheetGridRow,
  TimesheetOpenShiftFilterScope,
} from "@/features/timesheet/types/timesheet.types";
import {
  getMonthDaysHeader,
  getNextMonth,
  getPreviousMonth,
  getTodayDateString,
  isCurrentMonth,
} from "@/features/timesheet/utils/timesheet-date";
import {
  buildPositionFilterOptions,
  employeesInTodayOpenShift,
  filterEmployeesByNameSearch,
  filterEmployeesByOpenShiftScope,
  filterEmployeesByPositionKeys,
  filterEmployeesByTimesheetListScope,
  isTimesheetGridEmployeeVisible,
  mergeTodayOpenShiftEmployees,
  TimesheetHoursIndex,
} from "@/features/timesheet/utils/timesheet-visibility";

export function useTimesheet() {
  const queryClient = useQueryClient();

  const now = new Date();
  const [filters, setFilters] = useState<TimesheetFilters>({
    year: now.getFullYear(),
    month: now.getMonth() + 1,
    selectedObjectIds: [],
    selectedPositionKeys: [],
    listScope: "all",
    openShiftScope: "all",
    searchQuery: "",
  });

  const [selectedEmployeeIds, setSelectedEmployeeIds] = useState<Set<string>>(
    () => new Set()
  );

  const query = useQuery({
    queryKey: [
      "timesheet",
      filters.year,
      filters.month,
      filters.selectedObjectIds,
    ],
    queryFn: () =>
      getTimesheetData({
        year: filters.year,
        month: filters.month,
        selectedObjectIds: filters.selectedObjectIds,
      }),
  });

  // Navigation functions
  const goToPreviousMonth = () => {
    const prev = getPreviousMonth(filters.year, filters.month);
    setFilters((current) => ({
      ...current,
      year: prev.year,
      month: prev.month,
      openShiftScope: "all",
    }));
    setSelectedEmployeeIds(new Set());
  };

  const goToNextMonth = () => {
    if (isCurrentMonth(filters.year, filters.month)) return;
    const next = getNextMonth(filters.year, filters.month);
    setFilters((current) => ({
      ...current,
      year: next.year,
      month: next.month,
      openShiftScope: "all",
    }));
    setSelectedEmployeeIds(new Set());
  };

  const setYearAndMonth = (year: number, month: number) => {
    setFilters((current) => ({
      ...current,
      year,
      month,
      openShiftScope: "all",
    }));
    setSelectedEmployeeIds(new Set());
  };

  const setSelectedObjectIds = (ids: string[]) => {
    setFilters((current) => ({ ...current, selectedObjectIds: ids }));
    setSelectedEmployeeIds(new Set());
  };

  const setSelectedPositionKeys = (keys: string[]) => {
    setFilters((current) => ({ ...current, selectedPositionKeys: keys }));
  };

  const setListScope = (scope: TimesheetEmployeeListScope) => {
    setFilters((current) => ({ ...current, listScope: scope }));
  };

  const setOpenShiftScope = (scope: TimesheetOpenShiftFilterScope) => {
    setFilters((current) => ({ ...current, openShiftScope: scope }));
  };

  const setSearchQuery = (queryText: string) => {
    setFilters((current) => ({ ...current, searchQuery: queryText }));
  };

  // Selection toggle
  const toggleEmployeeSelection = (employeeId: string) => {
    setSelectedEmployeeIds((current) => {
      const next = new Set(current);
      if (next.has(employeeId)) {
        next.delete(employeeId);
      } else {
        next.add(employeeId);
      }
      return next;
    });
  };

  const selectAllEmployees = (ids: string[]) => {
    setSelectedEmployeeIds(new Set(ids));
  };

  const clearEmployeeSelection = () => {
    setSelectedEmployeeIds(new Set());
  };

  // Computed data
  const data = query.data;

  const daysHeader = useMemo(() => {
    return getMonthDaysHeader(filters.year, filters.month);
  }, [filters.year, filters.month]);

  const positionOptions = useMemo(() => {
    if (!data?.employees) return [];
    return buildPositionFilterOptions(data.employees);
  }, [data?.employees]);

  const hoursIndex = useMemo(() => {
    return new TimesheetHoursIndex(data?.entries ?? []);
  }, [data?.entries]);

  // Object color mapping
  const objectColorMap = useMemo(() => {
    const map = new Map<string, string>();
    if (!data?.objectOptions) return map;
    for (const opt of data.objectOptions) {
      map.set(opt.id, opt.colorClass);
    }
    return map;
  }, [data?.objectOptions]);

  // Filter and build visible grid rows
  const { visibleEmployees, gridRows, dayTotals, grandTotalHours } = useMemo(() => {
    if (!data) {
      return {
        visibleEmployees: [] as Employee[],
        gridRows: [] as TimesheetGridRow[],
        dayTotals: [] as number[],
        grandTotalHours: 0,
      };
    }

    const {
      employees,
      entries,
      todayOpenShift,
      periodContainsToday,
      daysCount,
    } = data;

    const hasObjectFilter = filters.selectedObjectIds.length > 0;

    let baseFiltered: Employee[];

    if (
      periodContainsToday &&
      filters.openShiftScope === "inOpenShift"
    ) {
      let pool = employeesInTodayOpenShift({
        allEmployees: employees,
        todayOpenShift,
        positionKeys: filters.selectedPositionKeys,
        selectedObjectIds: filters.selectedObjectIds,
      });
      pool = filterEmployeesByTimesheetListScope(
        pool,
        hoursIndex,
        filters.listScope
      );
      pool.sort((a, b) =>
        employeeFullName(a).localeCompare(employeeFullName(b), "ru")
      );
      baseFiltered = pool;
    } else {
      const scopeFiltered = employees.filter((e) =>
        isTimesheetGridEmployeeVisible({
          isFired: e.status === "fired",
          includeInTimesheet: e.includeInTimesheet,
          employeeId: e.id,
          hoursIndex,
          hasObjectFilter,
        })
      );

      const scopedByHours = filterEmployeesByTimesheetListScope(
        scopeFiltered,
        hoursIndex,
        filters.listScope
      );

      const positionFiltered = filterEmployeesByPositionKeys(
        scopedByHours,
        filters.selectedPositionKeys
      );

      if (
        periodContainsToday &&
        filters.openShiftScope === "notInOpenShift"
      ) {
        baseFiltered = filterEmployeesByOpenShiftScope(
          positionFiltered,
          todayOpenShift,
          "notInOpenShift",
          true
        );
      } else {
        baseFiltered = mergeTodayOpenShiftEmployees({
          currentList: positionFiltered,
          allEmployees: employees,
          todayOpenShift,
          positionKeys: filters.selectedPositionKeys,
          selectedObjectIds: filters.selectedObjectIds,
          hoursIndex,
          listScope: filters.listScope,
          periodContainsToday,
        });
      }
    }

    const matchingSearch = filterEmployeesByNameSearch(
      baseFiltered,
      filters.searchQuery
    );

    matchingSearch.sort((a, b) =>
      employeeFullName(a).localeCompare(employeeFullName(b), "ru")
    );

    // Fast entry index by employeeId and date
    // employeeId -> date -> TimesheetEntry[]
    const entriesMap = new Map<string, Map<string, TimesheetEntry[]>>();
    for (const entry of entries) {
      let empMap = entriesMap.get(entry.employeeId);
      if (!empMap) {
        empMap = new Map<string, TimesheetEntry[]>();
        entriesMap.set(entry.employeeId, empMap);
      }
      let dayEntries = empMap.get(entry.date);
      if (!dayEntries) {
        dayEntries = [];
        empMap.set(entry.date, dayEntries);
      }
      dayEntries.push(entry);
    }

    const todayStr = getTodayDateString();

    const rows: TimesheetGridRow[] = [];
    const totalsPerDay = new Array<number>(daysCount).fill(0);
    let totalAllHours = 0;

    for (const employee of matchingSearch) {
      const empMap = entriesMap.get(employee.id);
      const days: DayCellData[] = [];
      let empTotalHours = 0;
      let empTotalDays = 0;

      for (let day = 1; day <= daysCount; day += 1) {
        const dateStr = `${filters.year}-${String(filters.month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
        const dayEntries = empMap?.get(dateStr) ?? [];
        let dayHours = 0;
        for (const e of dayEntries) {
          dayHours += e.hours;
        }

        const isToday = dateStr === todayStr;
        const isInTodayOpenShift =
          isToday && todayOpenShift.employeeIds.has(employee.id);
        const todayHint = isInTodayOpenShift
          ? todayOpenShift.hintByEmployeeId.get(employee.id)
          : undefined;

        days.push({
          date: dateStr,
          dayNumber: day,
          dayOfWeek: new Date(filters.year, filters.month - 1, day).getDay(),
          isToday,
          isWeekend: daysHeader[day - 1]?.isWeekend ?? false,
          totalHours: dayHours,
          entries: dayEntries,
          isInTodayOpenShift,
          todayOpenShiftHint: todayHint,
        });

        if (dayHours > 0) {
          empTotalHours += dayHours;
          empTotalDays += 1;
          totalsPerDay[day - 1] += dayHours;
        }
      }

      totalAllHours += empTotalHours;

      rows.push({
        employee,
        fullName: employeeFullName(employee),
        position: employee.position.trim(),
        days,
        totalHours: empTotalHours,
        totalDays: empTotalDays,
      });
    }

    return {
      visibleEmployees: matchingSearch,
      gridRows: rows,
      dayTotals: totalsPerDay,
      grandTotalHours: totalAllHours,
    };
  }, [data, filters, hoursIndex, daysHeader]);

  // Attendance Save Mutation
  const saveAttendanceMutation = useMutation({
    mutationFn: async ({
      employeeId,
      objectId,
      rows,
    }: {
      employeeId: string;
      objectId: string;
      rows: AttendanceBatchRow[];
    }) => {
      await saveEmployeeAttendanceBatch({ employeeId, objectId, rows });
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["timesheet"] });
      await queryClient.invalidateQueries({
        queryKey: ["employee-timesheet"],
      });
      toast.success("Данные посещаемости сохранены");
    },
    onError: (err) => {
      toast.error(
        err instanceof Error ? err.message : "Не удалось сохранить посещаемость"
      );
    },
  });

  return {
    filters,
    setFilters,
    selectedEmployeeIds,
    toggleEmployeeSelection,
    selectAllEmployees,
    clearEmployeeSelection,
    goToPreviousMonth,
    goToNextMonth,
    setYearAndMonth,
    setSelectedObjectIds,
    setSelectedPositionKeys,
    setListScope,
    setOpenShiftScope,
    setSearchQuery,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    error: query.error,
    refetch: query.refetch,
    data,
    daysHeader,
    positionOptions,
    visibleEmployees,
    gridRows,
    dayTotals,
    grandTotalHours,
    objectColorMap,
    saveAttendance: saveAttendanceMutation.mutateAsync,
    isSavingAttendance: saveAttendanceMutation.isPending,
  };
}

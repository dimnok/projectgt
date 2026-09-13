"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useEffect, useMemo, useState } from "react";

import type { Employee } from "@/features/employees/types/employee.types";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import { getTimesheetData } from "@/features/timesheet/api/get-timesheet-data";
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
  buildEmployeeHoursMap,
  buildPositionFilterOptions,
  filterTimesheetEmployees,
} from "@/features/timesheet/utils/timesheet-visibility";
import { usePermissions } from "@/hooks/use-permissions";

export function useTimesheet() {
  const { can, isOwner, isReady: permissionsReady } = usePermissions();
  const { data: profile, isFetched: profileFetched } = useCurrentProfile();

  const hasAllObjectsAccess =
    isOwner || can("objects", "read") || can("employees", "read");

  const allowedObjectIds = useMemo(() => {
    if (hasAllObjectsAccess) return undefined;
    return profile?.objectIds ?? [];
  }, [hasAllObjectsAccess, profile?.objectIds]);

  const isAccessReady = permissionsReady && profileFetched;

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

  // Debounced search query to eliminate input latency on large datasets
  const [debouncedSearch, setDebouncedSearch] = useState(filters.searchQuery);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(filters.searchQuery);
    }, 150);
    return () => clearTimeout(timer);
  }, [filters.searchQuery]);

  const [selectedEmployeeIds, setSelectedEmployeeIds] = useState<Set<string>>(
    () => new Set()
  );

  const query = useQuery({
    queryKey: [
      "timesheet",
      filters.year,
      filters.month,
      filters.selectedObjectIds,
      allowedObjectIds,
    ],
    queryFn: () =>
      getTimesheetData({
        year: filters.year,
        month: filters.month,
        selectedObjectIds: filters.selectedObjectIds,
        allowedObjectIds,
      }),
    enabled: isAccessReady,
    placeholderData: keepPreviousData,
  });

  // Month navigation
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

  const setSelectedObjectIds = (ids: string[]) => {
    const validIds = allowedObjectIds
      ? ids.filter((id) => allowedObjectIds.includes(id))
      : ids;
    setFilters((current) => ({ ...current, selectedObjectIds: validIds }));
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

  const data = query.data;

  const daysHeader = useMemo(() => {
    return getMonthDaysHeader(filters.year, filters.month);
  }, [filters.year, filters.month]);

  const positionOptions = useMemo(() => {
    if (!data?.employees) return [];
    return buildPositionFilterOptions(data.employees);
  }, [data?.employees]);

  // Compute visible rows and totals in a single optimized pass
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

    // 1. Build fast employee hours map
    const hoursMap = buildEmployeeHoursMap(entries);

    // 2. Filter employees in single pass
    const filtered = filterTimesheetEmployees({
      employees,
      hoursMap,
      todayOpenShift,
      periodContainsToday,
      selectedObjectIds: filters.selectedObjectIds,
      selectedPositionKeys: filters.selectedPositionKeys,
      listScope: filters.listScope,
      openShiftScope: filters.openShiftScope,
      searchQuery: debouncedSearch,
    });

    // 3. Fast entry indexing: employeeId -> date -> TimesheetEntry[]
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

    for (const employee of filtered) {
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
      visibleEmployees: filtered,
      gridRows: rows,
      dayTotals: totalsPerDay,
      grandTotalHours: totalAllHours,
    };
  }, [data, filters.year, filters.month, filters.selectedObjectIds, filters.selectedPositionKeys, filters.listScope, filters.openShiftScope, debouncedSearch, daysHeader]);

  return {
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
    isLoading: !isAccessReady || query.isLoading,
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
  };
}

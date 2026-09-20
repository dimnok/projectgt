"use client";

import { useQuery } from "@tanstack/react-query";

import { getMonthHeaders } from "@/features/works/api/get-month-headers";
import { getWorkAccessScope } from "@/features/works/api/get-work-membership";
import { getMonthWorks, getWork } from "@/features/works/api/get-month-works";
import { getWorkHours, getWorkHoursTotalsByWorkIds } from "@/features/works/api/get-work-hours";
import { getWorkItems } from "@/features/works/api/get-work-items";
import {
  getMonthEmployeesSummary,
  getMonthHoursSummary,
  getMonthObjectsSummary,
  getMonthSystemsSummary,
} from "@/features/works/api/get-month-summary";

export const worksMonthsQueryKey = (openedBy?: string) =>
  ["works", "months", openedBy ?? "all"] as const;

export const monthWorksQueryKey = (month: string, openedBy?: string) =>
  ["works", "month-works", month, openedBy ?? "all"] as const;

export const monthWorkHoursQueryKey = (month: string) =>
  ["works", "hour-totals", month] as const;

export const workQueryKey = (workId: string) =>
  ["works", "work", workId] as const;

export const workItemsQueryKey = (workId: string) =>
  ["works", "items", workId] as const;

export const workHoursQueryKey = (workId: string) =>
  ["works", "hours", workId] as const;

export const workAccessScopeQueryKey = ["works", "access-scope"] as const;

/**
 * Same object access as month shifts: owner / super-admin see all objects,
 * other users only `profiles.object_ids`.
 */
export function useWorkAccessScope() {
  return useQuery({
    queryKey: workAccessScopeQueryKey,
    queryFn: getWorkAccessScope,
  });
}

export function useMonthHeaders(openedBy?: string) {
  return useQuery({
    queryKey: worksMonthsQueryKey(openedBy),
    queryFn: () => getMonthHeaders(openedBy),
  });
}

export function useMonthWorks(
  month: string,
  openedBy: string | undefined,
  enabled: boolean
) {
  return useQuery({
    queryKey: monthWorksQueryKey(month, openedBy),
    queryFn: () => getMonthWorks(month, openedBy),
    enabled,
  });
}

export function useMonthWorkHourTotals(
  month: string,
  workIds: string[],
  enabled: boolean
) {
  const idsKey = workIds.slice().sort().join(",");

  return useQuery({
    queryKey: [...monthWorkHoursQueryKey(month), idsKey],
    queryFn: () => getWorkHoursTotalsByWorkIds(workIds),
    enabled: enabled && workIds.length > 0,
  });
}

export function useWork(workId: string | null) {
  return useQuery({
    queryKey: workQueryKey(workId ?? ""),
    queryFn: () => getWork(workId!),
    enabled: Boolean(workId),
  });
}

export function useWorkItems(workId: string | null) {
  return useQuery({
    queryKey: workItemsQueryKey(workId ?? ""),
    queryFn: () => getWorkItems(workId!),
    enabled: Boolean(workId),
  });
}

export function useWorkHours(workId: string | null) {
  return useQuery({
    queryKey: workHoursQueryKey(workId ?? ""),
    queryFn: () => getWorkHours(workId!),
    enabled: Boolean(workId),
  });
}

export function useMonthObjectsSummary(month: string | null) {
  return useQuery({
    queryKey: ["works", "objects-summary", month],
    queryFn: () => getMonthObjectsSummary(month!),
    enabled: Boolean(month),
  });
}

export function useMonthSystemsSummary(month: string | null, objectId?: string) {
  return useQuery({
    queryKey: ["works", "systems-summary", month, objectId ?? "all"],
    queryFn: () => getMonthSystemsSummary(month!, objectId),
    enabled: Boolean(month),
  });
}

export function useMonthHoursSummary(month: string | null, objectId?: string) {
  return useQuery({
    queryKey: ["works", "hours-summary", month, objectId ?? "all"],
    queryFn: () => getMonthHoursSummary(month!, objectId),
    enabled: Boolean(month),
  });
}

export function useMonthEmployeesSummary(
  month: string | null,
  objectId?: string
) {
  return useQuery({
    queryKey: ["works", "employees-summary", month, objectId ?? "all"],
    queryFn: () => getMonthEmployeesSummary(month!, objectId),
    enabled: Boolean(month),
  });
}

import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  MonthObjectSummary,
  MonthSystemSummary,
} from "@/features/works/types/work.types";
import { toNumber } from "@/features/works/utils/work.utils";

function monthDate(month: string): string {
  return `${month}-01`;
}

function firstRow(data: unknown): Record<string, unknown> {
  if (Array.isArray(data)) {
    return (data[0] as Record<string, unknown> | undefined) ?? {};
  }
  if (data && typeof data === "object") {
    return data as Record<string, unknown>;
  }
  return {};
}

type ObjectSummaryRow = {
  object_id: string | null;
  object_name: string | null;
  works_count: number | string | null;
  total_amount: number | string | null;
  own_total_amount: number | string | null;
};

type SystemSummaryRow = {
  system: string | null;
  works_count: number | string | null;
  items_count: number | string | null;
  total_amount: number | string | null;
};

/**
 * Objects KPI for a month. Same RPC as Flutter `get_month_objects_summary`.
 */
export async function getMonthObjectsSummary(
  month: string
): Promise<MonthObjectSummary[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_month_objects_summary", {
    p_month: monthDate(month),
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as ObjectSummaryRow[]).map((row) => ({
    objectId: row.object_id ?? "",
    objectName: row.object_name?.trim() || "Неизвестный объект",
    worksCount: toNumber(row.works_count),
    totalAmount: toNumber(row.total_amount),
    ownTotalAmount: toNumber(row.own_total_amount),
  }));
}

/**
 * Systems KPI for a month. Same RPC as Flutter `get_month_systems_summary`.
 */
export async function getMonthSystemsSummary(
  month: string,
  objectId?: string
): Promise<MonthSystemSummary[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_month_systems_summary", {
    p_month: monthDate(month),
    p_company_id: companyId,
    p_object_id: objectId ?? null,
  });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as SystemSummaryRow[]).map((row) => ({
    system: row.system?.trim() || "Неизвестная система",
    worksCount: toNumber(row.works_count),
    itemsCount: toNumber(row.items_count),
    totalAmount: toNumber(row.total_amount),
  }));
}

/**
 * Hours KPI for a month. Same RPC as Flutter `get_month_hours_summary`.
 */
export async function getMonthHoursSummary(
  month: string,
  objectId?: string
): Promise<number> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_month_hours_summary", {
    p_month: monthDate(month),
    p_company_id: companyId,
    p_object_id: objectId ?? null,
  });

  if (error) {
    throw new Error(error.message);
  }

  return toNumber(firstRow(data).total_hours);
}

/**
 * Specialists KPI for a month. Same RPC as Flutter `get_month_employees_summary`.
 */
export async function getMonthEmployeesSummary(
  month: string,
  objectId?: string
): Promise<number> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_month_employees_summary", {
    p_month: monthDate(month),
    p_company_id: companyId,
    p_object_id: objectId ?? null,
  });

  if (error) {
    throw new Error(error.message);
  }

  return toNumber(firstRow(data).total_employees);
}

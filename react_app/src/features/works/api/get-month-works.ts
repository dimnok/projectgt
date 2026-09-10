import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { Work, WorksRow } from "@/features/works/types/work.types";
import {
  isWorkStatus,
  monthRange,
  resolveProfileName,
  toNumber,
  unwrapRelation,
} from "@/features/works/utils/work.utils";

const WORK_SELECT = [
  "id",
  "company_id",
  "date",
  "object_id",
  "opened_by",
  "status",
  "photo_url",
  "evening_photo_url",
  "total_amount",
  "own_total_amount",
  "items_count",
  "employees_count",
  "objects!object_id(name)",
  "profiles!opened_by(short_name, full_name)",
].join(", ");

export function mapWorkRow(row: WorksRow): Work {
  const object = unwrapRelation(row.objects);
  const profile = unwrapRelation(row.profiles);
  const status = isWorkStatus(row.status) ? row.status : "open";

  return {
    id: row.id,
    companyId: row.company_id,
    date: String(row.date).split("T")[0],
    objectId: row.object_id,
    objectName: object?.name?.trim() || "Объект не указан",
    openedBy: row.opened_by,
    openedByName: resolveProfileName(profile),
    status,
    photoUrl: row.photo_url,
    eveningPhotoUrl: row.evening_photo_url,
    totalAmount: toNumber(row.total_amount),
    ownTotalAmount: toNumber(row.own_total_amount),
    itemsCount: toNumber(row.items_count),
    employeesCount: toNumber(row.employees_count),
  };
}

/**
 * Loads shifts of one month. Same filters as Flutter `getMonthWorks`.
 */
export async function getMonthWorks(
  month: string,
  openedBy?: string
): Promise<Work[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { start, end } = monthRange(month);

  let query = client
    .from("works")
    .select(WORK_SELECT)
    .eq("company_id", companyId)
    .gte("date", start)
    .lt("date", end);

  if (openedBy) {
    query = query.eq("opened_by", openedBy);
  }

  const { data, error } = await query.order("date", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as WorksRow[]).map(mapWorkRow);
}

/**
 * Loads one shift by id. Same row mapping as `getMonthWorks`.
 */
export async function getWork(workId: string): Promise<Work> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("works")
    .select(WORK_SELECT)
    .eq("company_id", companyId)
    .eq("id", workId)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }
  if (!data) {
    throw new Error("Смена не найдена");
  }

  return mapWorkRow(data as unknown as WorksRow);
}

import { getRequiredClient } from "@/lib/supabase/client";
import { emptyToNull } from "@/features/work-journal/utils/work-journal.utils";
import {
  WORK_JOURNAL_PAGE_SIZE,
  type WorkJournalPage,
  type WorkJournalRow,
  type WorkJournalSearchParams,
} from "@/features/work-journal/types/work-journal.types";

type SearchRpcPayload = {
  total_count?: number;
  total_quantity?: number;
  total_sum?: number;
  items?: unknown;
};

type SearchRpcRow = {
  work_item_id?: string | null;
  work_id?: string | null;
  work_date?: string | null;
  object_id?: string | null;
  object_name?: string | null;
  work_status?: string | null;
  system?: string | null;
  subsystem?: string | null;
  section?: string | null;
  floor?: string | null;
  work_name?: string | null;
  unit?: string | null;
  quantity?: number | string | null;
  estimate_id?: string | null;
  price?: number | string | null;
  position_number?: string | null;
  contract_number?: string | null;
  m15_name?: string | null;
};

/**
 * Paginated work-item search with totals. Same RPC as Flutter.
 */
export async function searchWorkItems(
  params: WorkJournalSearchParams
): Promise<WorkJournalPage> {
  const pageSize = params.pageSize ?? WORK_JOURNAL_PAGE_SIZE;
  const page = Math.max(params.page, 1);
  const from = (page - 1) * pageSize;
  const to = from + pageSize - 1;

  const client = getRequiredClient();
  const { data, error } = await client.rpc("search_work_items_with_aggregates", {
    p_object_id: params.objectId,
    p_start_date: params.startDate ?? null,
    p_end_date: params.endDate ?? null,
    p_system_filters: emptyToNull(params.systemFilters),
    p_section_filters: emptyToNull(params.sectionFilters),
    p_floor_filters: emptyToNull(params.floorFilters),
    p_search_query: params.searchQuery?.trim() || null,
    p_from: from,
    p_to: to,
  });

  if (error) {
    throw new Error(error.message);
  }

  const payload = parsePayload(data);
  const items = mapRows(payload.items);
  const totalCount = Number(payload.total_count ?? 0);
  const totalPages = totalCount === 0 ? 0 : Math.ceil(totalCount / pageSize);

  return {
    items,
    totalCount,
    totalQuantity: Number(payload.total_quantity ?? 0),
    totalSum: Number(payload.total_sum ?? 0),
    currentPage: page,
    pageSize,
    totalPages,
  };
}

const EXPORT_PAGE_SIZE = 1000;
const EXPORT_MAX_ROWS = 100_000;

/**
 * Loads every matching work-journal row for Excel (not only the current page).
 */
export async function searchAllWorkItems(
  params: Omit<WorkJournalSearchParams, "page" | "pageSize">
): Promise<WorkJournalRow[]> {
  const first = await searchWorkItems({
    ...params,
    page: 1,
    pageSize: EXPORT_PAGE_SIZE,
  });
  const items = [...first.items];
  const total = Math.min(first.totalCount, EXPORT_MAX_ROWS);
  const pages = Math.ceil(total / EXPORT_PAGE_SIZE);

  for (let page = 2; page <= pages; page += 1) {
    const next = await searchWorkItems({
      ...params,
      page,
      pageSize: EXPORT_PAGE_SIZE,
    });
    items.push(...next.items);
    if (next.items.length === 0) {
      break;
    }
  }

  return items.slice(0, EXPORT_MAX_ROWS);
}

function parsePayload(response: unknown): SearchRpcPayload {
  if (typeof response === "string") {
    return JSON.parse(response) as SearchRpcPayload;
  }
  if (response && typeof response === "object") {
    return response as SearchRpcPayload;
  }
  throw new Error("Неизвестный формат ответа поиска работ");
}

function mapRows(raw: unknown): WorkJournalRow[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  return raw.flatMap((item) => {
    if (!item || typeof item !== "object") {
      return [];
    }
    const row = item as SearchRpcRow;
    const workItemId = row.work_item_id;
    const workDate = row.work_date;
    if (!workItemId || !workDate) {
      return [];
    }

    const quantity = Number(row.quantity ?? 0);
    const price =
      row.price === null || row.price === undefined ? null : Number(row.price);
    const workName = row.work_name ?? "";

    return [
      {
        workItemId,
        workId: row.work_id ?? null,
        workDate,
        objectId: row.object_id ?? null,
        objectName: row.object_name ?? "Неизвестный объект",
        workStatus: row.work_status ?? null,
        system: row.system ?? "",
        subsystem: row.subsystem ?? "",
        section: row.section ?? "",
        floor: row.floor ?? "",
        workName,
        unit: row.unit ?? "",
        quantity,
        estimateId: row.estimate_id ?? null,
        price,
        total: price === null ? null : price * quantity,
        positionNumber: row.position_number ?? null,
        contractNumber: row.contract_number ?? null,
        m15Name: row.m15_name ?? null,
      },
    ];
  });
}

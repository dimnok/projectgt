import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  mapSettlementListRow,
  toNumber,
} from "@/features/settlements/utils/settlement.utils";
import type {
  Settlement,
  SettlementFilters,
  SettlementPaymentStatus,
} from "@/features/settlements/types/settlement.types";
import type {
  SettlementListPageRow,
  SettlementSummaryRow,
} from "@/types/database.types";

/** Ключ сортировки колонки таблицы. */
export type SettlementSortKey =
  | "date"
  | "type"
  | "invoice"
  | "act"
  | "contract"
  | "contractor"
  | "object"
  | "totalToPay"
  | "status"
  | "paid";

/** Текущая сортировка реестра. `null` — исходный порядок (по дате счёта). */
export type SettlementSort = {
  key: SettlementSortKey;
  direction: "asc" | "desc";
} | null;

/**
 * Условия выборки реестра: те же фильтры, что у формы фильтров, плюс
 * сортировка и страница. Все поля необязательные — в SQL пустое значение
 * значит «без фильтра».
 */
export type SettlementListQuery = Partial<SettlementFilters> & {
  sort?: SettlementSort;
  page?: number;
  pageSize?: number;
};

/** Страница реестра: строки и общее число счетов под фильтром. */
export type SettlementListResult = {
  items: Settlement[];
  total: number;
};

/** Размер страницы реестра. */
export const SETTLEMENT_PAGE_SIZE = 50;

/** Итоги реестра для полосы показателей. */
export type SettlementSummary = {
  /** Всего счетов под фильтром. */
  count: number;
  /** Сумма «к оплате» по всем счетам. */
  totalAmount: number;
  /** Поступившие оплаты. */
  totalPaid: number;
  /** Положительный остаток (долг) — переплаты не уменьшают его. */
  totalDebt: number;
  /** Число счетов по каждому статусу оплаты. */
  byStatus: Partial<Record<SettlementPaymentStatus, number>>;
};

/**
 * Фильтры для функций реестра.
 *
 * «Все» и пустые значения уходят как `null`: в SQL это значит «без фильтра».
 */
function listRpcParams(query: SettlementListQuery, companyId: string) {
  return {
    p_company_id: companyId,
    p_search: query.search?.trim() || null,
    p_operation_type:
      query.operationType && query.operationType !== "all"
        ? query.operationType
        : null,
    p_payment_status:
      query.paymentStatus && query.paymentStatus !== "all"
        ? query.paymentStatus
        : null,
    p_contractor_id: query.contractorId || null,
    p_object_id: query.objectId || null,
    p_contract_id: query.contractId || null,
  };
}

/**
 * Страница реестра счетов.
 *
 * Поиск (номер счёта, акт, примечание, договор, контрагент, объект), фильтры,
 * сортировка и общее число строк считаются в базе одним запросом. Порядок
 * строгий: при равных значениях строки не повторяются и не пропадают между
 * страницами.
 */
export async function getSettlementsPage(
  query: SettlementListQuery
): Promise<SettlementListResult> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const page = Math.max(0, query.page ?? 0);
  const pageSize = Math.max(1, query.pageSize ?? SETTLEMENT_PAGE_SIZE);

  const { data, error } = await client.rpc("get_settlements_page", {
    ...listRpcParams(query, companyId),
    p_sort_key: query.sort?.key ?? "date",
    p_sort_dir: query.sort?.direction ?? "desc",
    p_limit: pageSize,
    p_offset: page * pageSize,
  });

  if (error) {
    throw new Error(error.message);
  }

  const page_ = ((data ?? []) as unknown as SettlementListPageRow[])[0];

  return {
    items: (page_?.items ?? []).map(mapSettlementListRow),
    total: toNumber(page_?.total_count ?? 0),
  };
}

/**
 * Итоги по счетам для полосы показателей.
 *
 * Количество, суммы, долг и разбивка по статусам считаются в базе одним
 * запросом — строки в браузер не вычитываются.
 */
export async function getSettlementsSummary(
  query: SettlementListQuery
): Promise<SettlementSummary> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc(
    "get_settlements_summary",
    listRpcParams(query, companyId)
  );

  if (error) {
    throw new Error(error.message);
  }

  const row = ((data ?? []) as unknown as SettlementSummaryRow[])[0];
  if (!row) {
    return { count: 0, totalAmount: 0, totalPaid: 0, totalDebt: 0, byStatus: {} };
  }

  return {
    count: toNumber(row.total_count),
    totalAmount: toNumber(row.total_amount),
    totalPaid: toNumber(row.total_paid),
    totalDebt: toNumber(row.total_debt),
    byStatus: row.by_status ?? {},
  };
}

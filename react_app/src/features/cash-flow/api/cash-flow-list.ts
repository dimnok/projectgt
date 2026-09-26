import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { TableSort } from "@/lib/table-sort";
import { mapCashFlowMonthRow } from "@/features/cash-flow/utils/analytics";
import {
  mapCashFlowRow,
  toNumber,
} from "@/features/cash-flow/utils/cash-flow.utils";
import { yearPeriod } from "@/features/cash-flow/utils/filters";
import type {
  CashFlowFilters,
  CashFlowMonthAnalytics,
  CashFlowSummary,
  CashFlowTransaction,
} from "@/features/cash-flow/types/cash-flow.types";
import type {
  CashFlowListPageRow,
  CashFlowMonthAnalyticsRow,
  CashFlowSummaryRow,
} from "@/types/database.types";

/** Ключ сортировки колонки таблицы. */
export type CashFlowSortKey =
  | "date"
  | "type"
  | "category"
  | "object"
  | "contractor"
  | "contract"
  | "amount";

/** Текущая сортировка реестра. `null` — исходный порядок (по дате платежа). */
export type CashFlowSort = TableSort<CashFlowSortKey>;

/**
 * Условия выборки реестра: те же фильтры, что у формы фильтров, плюс
 * сортировка и страница. Год задаёт период выборки, поэтому он обязателен.
 */
export type CashFlowListQuery = Partial<CashFlowFilters> & {
  year: number;
  sort?: CashFlowSort;
  page?: number;
  pageSize?: number;
};

/** Страница реестра: операции и общее число под фильтром. */
export type CashFlowListResult = {
  items: CashFlowTransaction[];
  total: number;
};

/** Размер страницы реестра. */
export const CASH_FLOW_PAGE_SIZE = 50;

/**
 * Фильтры для функций реестра.
 *
 * «Все» и пустые значения уходят как `null`: в SQL это значит «без фильтра».
 */
function listRpcParams(query: CashFlowListQuery, companyId: string) {
  const period = yearPeriod(query.year);
  return {
    p_company_id: companyId,
    p_search: query.search?.trim() || null,
    p_object_id: query.objectId || null,
    p_contractor_id: query.contractorId || null,
    p_contract_ids: query.contractIds?.length ? query.contractIds : null,
    p_types: query.types?.length ? query.types : null,
    p_start_date: period.startDate,
    p_end_date: period.endDate,
  };
}

/**
 * Страница реестра операций.
 *
 * Поиск (комментарий, контрагент, объект, договор, статья), фильтры,
 * сортировка и общее число строк считаются в базе одним запросом. Порядок
 * строгий: при равных значениях строки не повторяются и не пропадают между
 * страницами.
 */
export async function getCashFlowPage(
  query: CashFlowListQuery
): Promise<CashFlowListResult> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const page = Math.max(0, query.page ?? 0);
  const pageSize = Math.max(1, query.pageSize ?? CASH_FLOW_PAGE_SIZE);

  const { data, error } = await client.rpc("get_cash_flow_page", {
    ...listRpcParams(query, companyId),
    p_sort_key: query.sort?.key ?? "date",
    p_sort_dir: query.sort?.direction ?? "desc",
    p_limit: pageSize,
    p_offset: page * pageSize,
  });

  if (error) {
    throw new Error(error.message);
  }

  const page_ = ((data ?? []) as unknown as CashFlowListPageRow[])[0];

  return {
    items: (page_?.items ?? []).map(mapCashFlowRow),
    total: toNumber(page_?.total_count ?? 0),
  };
}

/**
 * Итоги за период для полосы показателей.
 *
 * Количество, приход, расход и сальдо считаются в базе одним запросом —
 * операции в браузер не вычитываются.
 */
export async function getCashFlowSummary(
  query: CashFlowListQuery
): Promise<CashFlowSummary> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc(
    "get_cash_flow_summary",
    listRpcParams(query, companyId)
  );

  if (error) {
    throw new Error(error.message);
  }

  const row = ((data ?? []) as unknown as CashFlowSummaryRow[])[0];
  if (!row) {
    return { count: 0, income: 0, expense: 0, balance: 0 };
  }

  return {
    count: toNumber(row.total_count),
    income: toNumber(row.total_income),
    expense: toNumber(row.total_expense),
    balance: toNumber(row.total_balance),
  };
}

/**
 * Аналитика по месяцам за период.
 *
 * Месяцы приходят датой первого числа и уже в нужном порядке; подписи
 * («янв. 2026») ставит браузер.
 */
export async function getCashFlowMonthlyAnalytics(
  query: CashFlowListQuery
): Promise<CashFlowMonthAnalytics[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc(
    "get_cash_flow_monthly_analytics",
    listRpcParams(query, companyId)
  );

  if (error) {
    throw new Error(error.message);
  }

  const rows = (data ?? []) as unknown as CashFlowMonthAnalyticsRow[];
  return rows.map(mapCashFlowMonthRow);
}

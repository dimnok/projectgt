import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  PurchaseRequestCounts,
  PurchaseRequestListFilter,
  PurchaseRequestListItem,
} from "@/features/purchase-requests/types/purchase-request.types";
import { ALL_FILTER_VALUE, LIST_LIMIT } from "@/features/purchase-requests/utils/status";
import {
  asRowList,
  mapListItem,
  mapStatusCounts,
} from "@/features/purchase-requests/utils/mappers";
import { throwIfError } from "@/features/purchase-requests/api/errors";

/**
 * Реестр заявок. Фильтр — «Все» или конкретный статус: серверная функция
 * принимает статус отдельным параметром, поэтому групповые фильтры не нужны.
 */
export async function getPurchaseRequests(options: {
  filter: PurchaseRequestListFilter;
  search: string;
}): Promise<PurchaseRequestListItem[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("purchase_request_list", {
    p_company_id: companyId,
    p_filter: ALL_FILTER_VALUE,
    p_status: options.filter === ALL_FILTER_VALUE ? null : options.filter,
    p_search: options.search.trim() || null,
    p_limit: LIST_LIMIT,
  });
  throwIfError(error);
  return asRowList(data).map(mapListItem);
}

export async function getPurchaseRequestCounts(
  search: string
): Promise<PurchaseRequestCounts> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("purchase_request_status_counts", {
    p_company_id: companyId,
    p_search: search.trim() || null,
  });
  throwIfError(error);
  return mapStatusCounts(asRowList(data));
}

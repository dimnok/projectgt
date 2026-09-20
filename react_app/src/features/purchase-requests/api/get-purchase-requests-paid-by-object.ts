import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { PurchaseRequestPaidByObject } from "@/features/purchase-requests/types/purchase-request.types";
import { asRowList, mapPaidByObject } from "@/features/purchase-requests/utils/mappers";
import { throwIfError } from "@/features/purchase-requests/api/errors";

/**
 * KPI «Оплачено по объектам»: суммы счетов заявок в статусе «Оплачено».
 *
 * Сервер сам ограничивает строки теми заявками, которые пользователь
 * вправе видеть (право «Все заявки», автор или участник этапа).
 */
export async function getPurchaseRequestsPaidByObject(): Promise<
  PurchaseRequestPaidByObject[]
> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("purchase_request_paid_by_object", {
    p_company_id: companyId,
  });
  throwIfError(error);
  return asRowList(data).map(mapPaidByObject);
}

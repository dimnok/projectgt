import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  PurchaseRequestItem,
  PurchaseRequestItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import { asRowList, mapItem } from "@/features/purchase-requests/utils/mappers";
import { throwIfError } from "@/features/purchase-requests/api/errors";

/**
 * Сохраняет позиции заявки одной серверной операцией: новые строки
 * добавляются, существующие обновляются, отсутствующие удаляются.
 * Так правка остаётся атомарной и не зависит от числа позиций.
 */
export async function replacePurchaseRequestItems(
  requestId: string,
  items: PurchaseRequestItemDraft[]
): Promise<PurchaseRequestItem[]> {
  const client = getRequiredClient();
  const { data, error } = await client.rpc("purchase_request_replace_items", {
    p_request_id: requestId,
    p_items: items,
  });
  throwIfError(error);
  return asRowList(data).map(mapItem);
}

export async function createPurchaseRequestDraft(input: {
  objectId: string;
  comment: string | null;
  items: PurchaseRequestItemDraft[];
}) {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("purchase_request_create_draft", {
    p_company_id: companyId,
    p_object_id: input.objectId,
    p_comment: input.comment,
  });
  throwIfError(error);

  const requestId = String(data);
  await replacePurchaseRequestItems(requestId, input.items);
  return requestId;
}

export async function updatePurchaseRequestDraft(input: {
  requestId: string;
  objectId: string;
  comment: string | null;
  items: PurchaseRequestItemDraft[];
}) {
  const client = getRequiredClient();
  const { error } = await client.rpc("purchase_request_update_header", {
    p_request_id: input.requestId,
    p_object_id: input.objectId,
    p_comment: input.comment,
  });
  throwIfError(error);

  await replacePurchaseRequestItems(input.requestId, input.items);
  return input.requestId;
}

export async function deletePurchaseRequestDraft(requestId: string) {
  const client = getRequiredClient();
  const { error } = await client.rpc("purchase_request_delete_draft", {
    p_request_id: requestId,
  });
  throwIfError(error);
}

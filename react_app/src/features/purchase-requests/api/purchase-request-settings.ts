import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  PurchaseRequestCompanyUser,
  PurchaseRequestSettings,
} from "@/features/purchase-requests/types/purchase-request.types";
import { asRowList, mapCompanyUser, mapSettings } from "@/features/purchase-requests/utils/mappers";
import { pickUserDisplayName } from "@/features/purchase-requests/utils/names";
import { throwIfError } from "@/features/purchase-requests/api/errors";

export function companyUserLabel(user: PurchaseRequestCompanyUser) {
  return (
    pickUserDisplayName({
      shortName: user.shortName,
      fullName: user.fullName,
      email: user.email,
    }) ?? user.email
  );
}

export async function getPurchaseRequestSettings(): Promise<PurchaseRequestSettings | null> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client
    .from("purchase_request_settings")
    .select()
    .eq("company_id", companyId)
    .maybeSingle();
  throwIfError(error);
  if (!data) {
    return null;
  }

  const members = await client
    .from("purchase_request_route_members")
    .select()
    .eq("company_id", companyId)
    .order("sort_order")
    .order("user_id");
  throwIfError(members.error);

  return mapSettings(
    data as Record<string, unknown>,
    asRowList(members.data)
  );
}

export async function getPurchaseRequestCompanyUsers(): Promise<
  PurchaseRequestCompanyUser[]
> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("purchase_request_company_users", {
    p_company_id: companyId,
  });
  throwIfError(error);
  return asRowList(data).map(mapCompanyUser);
}

export async function upsertPurchaseRequestSettings(
  settings: PurchaseRequestSettings
): Promise<PurchaseRequestSettings> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  if (settings.companyId !== companyId) {
    throw new Error("Компания настроек не совпадает с активной");
  }

  const { error } = await client.rpc("purchase_request_upsert_settings", {
    p_company_id: companyId,
    p_first_approver_ids: settings.firstApproverIds,
    p_invoice_preparer_ids: settings.invoicePreparerIds,
    p_invoice_approver_ids: settings.invoiceApproverIds,
    p_accountant_ids: settings.accountantIds,
    p_receiver_mode: settings.receiverMode,
    p_fixed_receiver_ids: settings.fixedReceiverIds,
  });
  throwIfError(error);

  const saved = await getPurchaseRequestSettings();
  if (!saved) {
    throw new Error("Настройки маршрута не найдены после сохранения");
  }
  return saved;
}

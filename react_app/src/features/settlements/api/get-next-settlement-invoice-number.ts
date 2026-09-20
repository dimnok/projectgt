import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Подсказка следующего номера счёта по договору.
 *
 * Логику считает база (`get_next_settlement_invoice_number`): max завершающей
 * цифровой группы + 1 с сохранением префикса.
 */
export async function getNextSettlementInvoiceNumber(
  contractId: string
): Promise<string> {
  if (!contractId) {
    return "1";
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc(
    "get_next_settlement_invoice_number",
    {
      p_company_id: companyId,
      p_contract_id: contractId,
    }
  );

  if (error) {
    throw new Error(error.message);
  }

  const next = typeof data === "string" ? data : "";
  return next || "1";
}

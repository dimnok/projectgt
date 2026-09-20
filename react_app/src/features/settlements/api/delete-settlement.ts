import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { deleteAllSettlementFilesForOperation } from "@/features/settlements/api/settlement-files";
import { settlementWriteError } from "@/features/settlements/utils/settlement.utils";

/**
 * Удаляет счёт вместе с файлами.
 *
 * Сначала удаляем объекты Storage и записи файлов, затем сам счёт —
 * чтобы не оставить «осиротевшие» файлы.
 */
export async function deleteSettlement(id: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  await deleteAllSettlementFilesForOperation(id);

  const { error } = await client
    .from("settlement_operations")
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw settlementWriteError(error);
  }
}

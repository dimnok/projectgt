import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

export type EstimateImportItemInput = {
  system: string;
  subsystem: string;
  number: string;
  name: string;
  article: string;
  manufacturer: string;
  unit: string;
  quantity: number;
  price: number;
  total: number;
};

export type ImportEstimateInput = {
  objectId: string | null;
  contractId: string;
  estimateTitle: string;
  items: EstimateImportItemInput[];
};

const BATCH_SIZE = 250;

/**
 * Imports estimate items into the `estimates` table in batches.
 */
export async function importEstimate(input: ImportEstimateInput): Promise<{ count: number }> {
  const { objectId, contractId, estimateTitle, items } = input;

  if (!contractId) {
    throw new Error("Не указан договор для импорта сметы");
  }
  const cleanTitle = estimateTitle.trim();
  if (!cleanTitle) {
    throw new Error("Не указано название сметы");
  }
  if (!items || items.length === 0) {
    throw new Error("Файл не содержит корректных строк сметы");
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data: userData } = await client.auth.getUser();
  const userId = userData.user?.id ?? null;

  // Формируем записи для таблицы `estimates`
  const rows = items.map((item) => ({
    company_id: companyId,
    object_id: objectId || null,
    contract_id: contractId,
    estimate_title: cleanTitle,
    system: item.system || "",
    subsystem: item.subsystem || "",
    number: item.number || "",
    name: item.name || "",
    article: item.article || "",
    manufacturer: item.manufacturer || "",
    unit: item.unit || "",
    quantity: item.quantity,
    price: item.price,
    total: item.total,
    visible_in_estimates_module: true,
    created_by: userId,
  }));

  // Вставка пачками
  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const chunk = rows.slice(i, i + BATCH_SIZE);
    const { error } = await client.from("estimates").insert(chunk);
    if (error) {
      throw new Error(`Ошибка сохранения строк ${i + 1}–${i + chunk.length}: ${error.message}`);
    }
  }

  return { count: rows.length };
}

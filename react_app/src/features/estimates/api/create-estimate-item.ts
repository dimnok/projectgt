import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

export type CreateEstimateItemInput = {
  objectId?: string | null;
  contractId?: string | null;
  estimateTitle: string;
  system?: string;
  subsystem?: string;
  number?: string;
  name: string;
  article?: string;
  manufacturer?: string;
  unit?: string;
  quantity: number;
  price: number;
};

/**
 * Creates a new position in the `estimates` table.
 */
export async function createEstimateItem(
  input: CreateEstimateItemInput
): Promise<string> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const name = input.name.trim();
  if (!name) {
    throw new Error("Наименование позиции обязательно для заполнения");
  }

  const estimateTitle = input.estimateTitle.trim();
  if (!estimateTitle) {
    throw new Error("Не указано название сметы");
  }

  const { data: userData } = await client.auth.getUser();
  const userId = userData.user?.id ?? null;

  const quantity = Math.max(0, input.quantity);
  const price = Math.max(0, input.price);
  const total = Math.round(quantity * price * 100) / 100;

  const { data, error } = await client
    .from("estimates")
    .insert({
      company_id: companyId,
      object_id: input.objectId || null,
      contract_id: input.contractId || null,
      estimate_title: estimateTitle,
      system: (input.system ?? "").trim(),
      subsystem: (input.subsystem ?? "").trim(),
      number: (input.number ?? "").trim(),
      name,
      article: (input.article ?? "").trim(),
      manufacturer: (input.manufacturer ?? "").trim(),
      unit: (input.unit ?? "шт").trim() || "шт",
      quantity,
      price,
      total,
      visible_in_estimates_module: true,
      created_by: userId,
    })
    .select("id")
    .single();

  if (error) {
    throw new Error(error.message || "Не удалось создать позицию сметы");
  }

  return data.id;
}

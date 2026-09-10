import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { toNumber } from "@/features/estimates/utils/estimate.utils";

export type UpdateEstimateItemInput = {
  id: string;
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

type PreviousRow = {
  system: string | null;
  subsystem: string | null;
  number: string | number | null;
  name: string | null;
  article: string | null;
  manufacturer: string | null;
  unit: string | null;
  quantity: number | string | null;
  price: number | string | null;
};

function text(v: unknown): string {
  return String(v ?? "").trim();
}

/**
 * Updates an existing estimate position and records field changes
 * into `estimate_item_history` (mirroring Flutter business logic).
 */
export async function updateEstimateItem(
  input: UpdateEstimateItemInput
): Promise<void> {
  const { id } = input;
  if (!id) {
    throw new Error("Не указан идентификатор позиции сметы");
  }

  const name = input.name.trim();
  if (!name) {
    throw new Error("Наименование позиции обязательно для заполнения");
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  // 1. Считываем текущие значения из базы для вычисления дельты
  const { data: previousData, error: fetchError } = await client
    .from("estimates")
    .select(
      "system, subsystem, number, name, article, manufacturer, unit, quantity, price"
    )
    .eq("id", id)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }

  const previous = (previousData ?? null) as PreviousRow | null;

  const quantity = Math.max(0, input.quantity);
  const price = Math.max(0, input.price);
  const total = Math.round(quantity * price * 100) / 100;

  const nextSystem = (input.system ?? "").trim();
  const nextSubsystem = (input.subsystem ?? "").trim();
  const nextNumber = (input.number ?? "").trim();
  const nextArticle = (input.article ?? "").trim();
  const nextManufacturer = (input.manufacturer ?? "").trim();
  const nextUnit = (input.unit ?? "шт").trim() || "шт";

  // 2. Обновляем строку сметы
  const { error: updateError } = await client
    .from("estimates")
    .update({
      system: nextSystem,
      subsystem: nextSubsystem,
      number: nextNumber,
      name,
      article: nextArticle,
      manufacturer: nextManufacturer,
      unit: nextUnit,
      quantity,
      price,
      total,
    })
    .eq("id", id)
    .eq("company_id", companyId);

  if (updateError) {
    throw new Error(updateError.message || "Не удалось обновить позицию сметы");
  }

  // 3. Вычисляем изменения и логируем в estimate_item_history
  const { data: userData } = await client.auth.getUser();
  const userId = userData.user?.id ?? null;

  if (previous && userId) {
    const changes: Record<string, { from: unknown; to: unknown }> = {};

    const checkText = (key: string, prevVal: unknown, nextVal: string) => {
      const oldStr = text(prevVal);
      if (oldStr !== nextVal) {
        changes[key] = { from: oldStr, to: nextVal };
      }
    };

    const checkNumber = (key: string, prevVal: unknown, nextNum: number) => {
      const oldNum = toNumber(prevVal);
      if (Math.abs(oldNum - nextNum) > 0.0000001) {
        changes[key] = { from: oldNum, to: nextNum };
      }
    };

    checkText("system", previous.system, nextSystem);
    checkText("subsystem", previous.subsystem, nextSubsystem);
    checkText("number", previous.number, nextNumber);
    checkText("name", previous.name, name);
    checkText("article", previous.article, nextArticle);
    checkText("manufacturer", previous.manufacturer, nextManufacturer);
    checkText("unit", previous.unit, nextUnit);
    checkNumber("quantity", previous.quantity, quantity);
    checkNumber("price", previous.price, price);

    if (Object.keys(changes).length > 0) {
      await client.from("estimate_item_history").insert({
        company_id: companyId,
        estimate_id: id,
        user_id: userId,
        action: "updated",
        changes,
      });
    }
  }
}

import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { toNumber } from "@/features/works/utils/work.utils";

export type WorkEstimateOption = {
  id: string;
  system: string;
  subsystem: string;
  number: string | null;
  name: string;
  unit: string;
  price: number;
};

const ESTIMATE_PAGE_SIZE = 1000;

function uniqueSorted(values: string[]): string[] {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))].sort(
    (a, b) => a.localeCompare(b, "ru")
  );
}

/**
 * Distinct sections already used on this object.
 * Same RPC as Flutter: `get_object_sections`.
 */
export async function getObjectSections(objectId: string): Promise<string[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("get_object_sections", {
    target_object_id: objectId,
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  return uniqueSorted(
    ((data ?? []) as { section: string | null }[]).map(
      (row) => row.section ?? ""
    )
  );
}

/**
 * Distinct floors already used on this object.
 * Same RPC as Flutter: `get_object_floors`.
 */
export async function getObjectFloors(objectId: string): Promise<string[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("get_object_floors", {
    target_object_id: objectId,
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  return uniqueSorted(
    ((data ?? []) as { floor: string | null }[]).map((row) => row.floor ?? "")
  );
}

/**
 * Estimate lines of an object that can be added to a shift.
 * Same filter as Flutter: `object_id` + `visible_in_estimates_module`.
 */
export async function getObjectEstimatesForWorks(
  objectId: string
): Promise<WorkEstimateOption[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const all: WorkEstimateOption[] = [];
  let offset = 0;

  while (true) {
    const { data, error } = await client
      .from("estimates")
      .select("id, system, subsystem, number, name, unit, price")
      .eq("company_id", companyId)
      .eq("object_id", objectId)
      .eq("visible_in_estimates_module", true)
      .order("system")
      .order("subsystem")
      .order("number")
      .order("id")
      .range(offset, offset + ESTIMATE_PAGE_SIZE - 1);

    if (error) {
      throw new Error(error.message);
    }

    const chunk = (data ?? []) as {
      id: string;
      system: string | null;
      subsystem: string | null;
      number: string | number | null;
      name: string | null;
      unit: string | null;
      price: number | string | null;
    }[];

    for (const row of chunk) {
      all.push({
        id: row.id,
        system: row.system?.trim() ?? "",
        subsystem: row.subsystem?.trim() ?? "",
        number: row.number == null ? null : String(row.number),
        name: row.name?.trim() || "Без названия",
        unit: row.unit?.trim() || "",
        price: toNumber(row.price),
      });
    }

    if (chunk.length < ESTIMATE_PAGE_SIZE) {
      break;
    }
    offset += ESTIMATE_PAGE_SIZE;
  }

  return all;
}

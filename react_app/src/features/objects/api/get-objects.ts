import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { mapObjectRow, OBJECT_SELECT } from "@/features/objects/utils/object.utils";
import type { SiteObject } from "@/features/objects/types/object.types";
import type { ObjectsRow } from "@/types/database.types";

/**
 * Loads construction objects for the active company from Supabase.
 */
export async function getObjects(): Promise<SiteObject[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("objects")
    .select(OBJECT_SELECT)
    .eq("company_id", companyId)
    .order("name");

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as ObjectsRow[]).map(mapObjectRow);
}

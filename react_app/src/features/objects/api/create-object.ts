import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { mapObjectRow, OBJECT_SELECT } from "@/features/objects/utils/object.utils";
import type { ObjectDraft, SiteObject } from "@/features/objects/types/object.types";
import type { ObjectsRow } from "@/types/database.types";
import { createId } from "@/lib/utils";

/**
 * Creates a construction object in the active company.
 */
export async function createObject(draft: ObjectDraft): Promise<SiteObject> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("objects")
    .insert({
      id: createId(),
      company_id: companyId,
      name: draft.name.trim(),
      address: draft.address.trim(),
      description: draft.description.trim() || null,
      status: draft.status,
    })
    .select(OBJECT_SELECT)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error("Ошибка создания объекта");
  }

  return mapObjectRow(data as ObjectsRow);
}

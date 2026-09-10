import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { mapObjectRow, OBJECT_SELECT } from "@/features/objects/utils/object.utils";
import type { ObjectDraft, SiteObject } from "@/features/objects/types/object.types";
import type { ObjectsRow } from "@/types/database.types";

/**
 * Updates a construction object in the active company.
 */
export async function updateObject(
  object: SiteObject,
  draft: ObjectDraft
): Promise<SiteObject> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("objects")
    .update({
      name: draft.name.trim(),
      address: draft.address.trim(),
      description: draft.description.trim() || null,
      status: draft.status,
    })
    .eq("id", object.id)
    .eq("company_id", companyId)
    .select(OBJECT_SELECT)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error("Объект не найден для обновления");
  }

  return mapObjectRow(data as ObjectsRow);
}

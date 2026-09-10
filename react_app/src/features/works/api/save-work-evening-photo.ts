import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";
import { mapWorkRow } from "@/features/works/api/get-month-works";
import { uploadWorkShiftPhoto } from "@/features/works/api/upload-work-morning-photo";
import type { Work, WorksRow } from "@/features/works/types/work.types";

const WORK_SELECT = [
  "id",
  "company_id",
  "date",
  "object_id",
  "opened_by",
  "status",
  "photo_url",
  "evening_photo_url",
  "total_amount",
  "own_total_amount",
  "items_count",
  "employees_count",
  "objects!object_id(name)",
  "profiles!opened_by(short_name, full_name)",
].join(", ");

/**
 * Saves evening photo URL. Same as Flutter evening upload then `updateWork`.
 */
export async function saveWorkEveningPhoto(
  work: Work,
  file: File
): Promise<Work> {
  await assertCanWriteWorkItems(work.id);
  const photoUrl = await uploadWorkShiftPhoto(
    work.objectId,
    file,
    "evening",
    work.date
  );

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client
    .from("works")
    .update({
      evening_photo_url: photoUrl,
      updated_at: new Date().toISOString(),
    })
    .eq("id", work.id)
    .eq("company_id", companyId)
    .select(WORK_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return mapWorkRow(data as unknown as WorksRow);
}

import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertIsSuperAdmin } from "@/features/works/api/get-work-membership";
import { workPhotoStoragePath } from "@/features/works/utils/work.utils";

/**
 * Deletes a shift of any status. Super-admin only.
 * Photos are removed from storage when possible; items and hours cascade in DB.
 */
export async function deleteWork(workId: string): Promise<void> {
  await assertIsSuperAdmin();

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data: row, error: fetchError } = await client
    .from("works")
    .select("photo_url, photo_urls, evening_photo_url, evening_photo_urls")
    .eq("id", workId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!row) {
    throw new Error("Смена не найдена");
  }

  const paths = Array.from(
    new Set(
      [
        ...(row.photo_urls ?? []),
        ...(row.evening_photo_urls ?? []),
        row.photo_url,
        row.evening_photo_url,
      ]
        .map((url) => workPhotoStoragePath(url))
        .filter((path): path is string => Boolean(path))
    )
  );

  if (paths.length > 0) {
    try {
      await client.storage.from("works").remove(paths);
    } catch {
      // Same as Flutter: photo cleanup must not block delete.
    }
  }

  const { error } = await client
    .from("works")
    .delete()
    .eq("id", workId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}

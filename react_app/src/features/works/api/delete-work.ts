import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertIsSuperAdmin } from "@/features/works/api/get-work-membership";

function storagePathFromPublicUrl(url: string | null | undefined): string | null {
  if (!url?.trim()) {
    return null;
  }
  try {
    const pathSegments = new URL(url).pathname.split("/").filter(Boolean);
    const publicIndex = pathSegments.indexOf("public");
    if (publicIndex === -1 || publicIndex + 2 >= pathSegments.length) {
      return null;
    }
    if (pathSegments[publicIndex + 1] !== "works") {
      return null;
    }
    return decodeURIComponent(pathSegments.slice(publicIndex + 2).join("/"));
  } catch {
    return null;
  }
}

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
    .select("photo_url, evening_photo_url")
    .eq("id", workId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!row) {
    throw new Error("Смена не найдена");
  }

  const paths = [
    storagePathFromPublicUrl(row.photo_url),
    storagePathFromPublicUrl(row.evening_photo_url),
  ].filter((path): path is string => Boolean(path));

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

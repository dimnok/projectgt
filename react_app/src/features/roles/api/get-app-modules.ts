import type { AppModule } from "@/features/roles/types/role.types";
import { getRequiredClient } from "@/lib/supabase/client";

export const appModulesQueryKey = ["app-modules"] as const;

type ModuleRow = {
  id: string;
  code: string;
  name: string;
  sort_order: number | null;
};

export async function getAppModules(): Promise<AppModule[]> {
  const client = getRequiredClient();
  const { data, error } = await client
    .from("app_modules")
    .select("id, code, name, sort_order")
    .eq("is_active", true)
    .order("sort_order", { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as ModuleRow[]).map((row) => ({
    id: row.id,
    code: row.code,
    name: row.name,
    sortOrder: row.sort_order ?? 0,
  }));
}

import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { EmployeePositionRow } from "@/types/database.types";

/**
 * Unique job titles for the company. Same RPC as the app: `get_employee_positions`.
 */
export async function getEmployeePositions(): Promise<string[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_employee_positions", {
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  const names = new Set<string>();
  for (const row of (data ?? []) as unknown as EmployeePositionRow[]) {
    const name = row.position_name?.trim();
    if (name) {
      names.add(name);
    }
  }

  return [...names].sort((a, b) =>
    a.localeCompare(b, "ru", { sensitivity: "base" })
  );
}

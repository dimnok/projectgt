import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";

export type EmployeeApplication = {
  id: string;
  applicationType: "vacation" | "unpaid_leave" | "resignation" | string;
  startDate: string;
  endDate: string | null;
  durationDays: number;
  scanName: string;
  scanPath: string;
  scanSize: number;
  scanType: string;
  createdAt: string;
};

export async function getEmployeeApplications(
  employeeId: string
): Promise<EmployeeApplication[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("employee_applications")
    .select(
      `
      id,
      application_type,
      start_date,
      end_date,
      duration_days,
      scan_name,
      scan_path,
      scan_size,
      scan_type,
      created_at
    `
    )
    .eq("company_id", companyId)
    .eq("employee_id", employeeId)
    .order("created_at", { ascending: false });

  if (error) {
    throw new Error(`Ошибка загрузки заявлений: ${error.message}`);
  }

  return (data || []).map((row) => ({
    id: row.id,
    applicationType: row.application_type,
    startDate: row.start_date,
    endDate: row.end_date,
    durationDays: row.duration_days,
    scanName: row.scan_name,
    scanPath: row.scan_path,
    scanSize: Number(row.scan_size) || 0,
    scanType: row.scan_type,
    createdAt: row.created_at,
  }));
}

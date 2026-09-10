import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";

export type EmployeeTmcAssignment = {
  id: string;
  itemId: string;
  itemName: string;
  inventoryNumber: string | null;
  objectId: string | null;
  objectName: string | null;
  quantity: number;
  unitPrice: number;
  totalCost: number;
  issuedAt: string;
  plannedReturnDate: string | null;
  isActive: boolean;
};

export async function getEmployeeTmcAssignments(
  employeeId: string
): Promise<EmployeeTmcAssignment[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("tmc_assignments")
    .select(
      `
      id,
      item_id,
      unit_id,
      quantity,
      issued_at,
      planned_return_date,
      is_active,
      object_id,
      tmc_items (
        name,
        unit_price
      ),
      tmc_units (
        inventory_number
      ),
      objects (
        name
      )
    `
    )
    .eq("company_id", companyId)
    .eq("employee_id", employeeId)
    .eq("is_active", true)
    .order("issued_at", { ascending: false });

  if (error) {
    throw new Error(`Ошибка загрузки ТМЦ: ${error.message}`);
  }

  return (data || []).map((row) => {
    const item = row.tmc_items as unknown as { name?: string; unit_price?: number } | null;
    const unit = row.tmc_units as unknown as { inventory_number?: string } | null;
    const object = row.objects as unknown as { name?: string } | null;

    const quantity = Number(row.quantity) || 1;
    const unitPrice = Number(item?.unit_price) || 0;
    const totalCost = quantity * unitPrice;

    return {
      id: row.id,
      itemId: row.item_id,
      itemName: item?.name || "Без названия",
      inventoryNumber: unit?.inventory_number || null,
      objectId: row.object_id,
      objectName: object?.name || null,
      quantity,
      unitPrice,
      totalCost,
      issuedAt: row.issued_at,
      plannedReturnDate: row.planned_return_date,
      isActive: row.is_active,
    };
  });
}

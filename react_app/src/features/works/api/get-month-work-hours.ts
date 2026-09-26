import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { toNumber } from "@/features/works/utils/work.utils";

type MonthWorkHoursRow = {
  work_id: string;
  hours: number | string | null;
};

/**
 * Часы по сменам месяца: по строке на смену.
 *
 * Сумму считает база (`get_month_work_hours`): область объектов и право
 * `works.read` проверяются внутри функции. Раньше веб перечислял id всех смен
 * месяца в адресе запроса — на больших месяцах адрес перерастал лимит шлюза,
 * запрос падал, и план в графике на главной пропадал.
 */
export async function getMonthWorkHours(
  month: string
): Promise<Record<string, number>> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_month_work_hours", {
    p_month: `${month}-01`,
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  const totals: Record<string, number> = {};
  for (const row of (data ?? []) as MonthWorkHoursRow[]) {
    totals[row.work_id] = toNumber(row.hours);
  }

  return totals;
}

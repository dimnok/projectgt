import { getRequiredClient } from "@/lib/supabase/client";
import type {
  ProfileFinance,
  ProfileFinanceHourRow,
  ProfileFinanceMoneyRow,
} from "@/features/profile/types/profile-finance.types";
import { toFinanceNumber } from "@/features/profile/utils/profile-finance.utils";

type RpcMoneyRow = {
  date?: unknown;
  amount?: unknown;
  reason?: unknown;
  comment?: unknown;
};

type RpcHourRow = {
  date?: unknown;
  hours?: unknown;
};

type RpcPayload = {
  linked?: unknown;
  employee_id?: unknown;
  year?: unknown;
  month?: unknown;
  hours?: unknown;
  base_salary?: unknown;
  business_trip_total?: unknown;
  bonuses_total?: unknown;
  penalties_total?: unknown;
  net_salary?: unknown;
  balance?: unknown;
  bonuses?: unknown;
  penalties?: unknown;
  payouts?: unknown;
  hours_by_date?: unknown;
};

function asDateString(value: unknown) {
  if (typeof value !== "string" || !value) {
    return "";
  }
  return value.split("T")[0];
}

function mapMoneyRows(
  value: unknown,
  noteKey: "reason" | "comment"
): ProfileFinanceMoneyRow[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.map((row) => {
    const item = row as RpcMoneyRow;
    const note = item[noteKey];
    return {
      date: asDateString(item.date),
      amount: toFinanceNumber(item.amount),
      note: typeof note === "string" ? note : "",
    };
  });
}

function mapHourRows(value: unknown): ProfileFinanceHourRow[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.map((row) => {
    const item = row as RpcHourRow;
    return {
      date: asDateString(item.date),
      hours: toFinanceNumber(item.hours),
    };
  });
}

export async function getMyProfileFinance(
  year: number,
  month: number
): Promise<ProfileFinance> {
  const client = getRequiredClient();
  const { data, error } = await client.rpc("get_my_profile_finance", {
    p_year: year,
    p_month: month,
  });

  if (error) {
    throw new Error(error.message);
  }

  const payload = (data ?? {}) as RpcPayload;
  if (payload.linked !== true) {
    return { linked: false };
  }

  return {
    linked: true,
    employeeId: typeof payload.employee_id === "string" ? payload.employee_id : "",
    year: toFinanceNumber(payload.year),
    month: toFinanceNumber(payload.month),
    hours: toFinanceNumber(payload.hours),
    baseSalary: toFinanceNumber(payload.base_salary),
    businessTripTotal: toFinanceNumber(payload.business_trip_total),
    bonusesTotal: toFinanceNumber(payload.bonuses_total),
    penaltiesTotal: toFinanceNumber(payload.penalties_total),
    netSalary: toFinanceNumber(payload.net_salary),
    balance: toFinanceNumber(payload.balance),
    bonuses: mapMoneyRows(payload.bonuses, "reason"),
    penalties: mapMoneyRows(payload.penalties, "reason"),
    payouts: mapMoneyRows(payload.payouts, "comment"),
    hoursByDate: mapHourRows(payload.hours_by_date),
  };
}

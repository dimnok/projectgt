"use client";

import { useQuery } from "@tanstack/react-query";

import { getEmployeePayrollTotals } from "@/features/payrolls/api/get-employee-payroll-totals";
import { getPayrollPayouts } from "@/features/payrolls/api/get-payroll-payouts";
import { getPayrollTransactions } from "@/features/payrolls/api/get-payroll-transactions";
import type {
  PayrollEmployeeTotals,
  PayrollPayoutItem,
  PayrollPeriod,
  PayrollTransactionItem,
} from "@/features/payrolls/types/payroll.types";
import { getPeriodKey } from "@/features/payrolls/utils/payroll.utils";
import { usePermissions } from "@/hooks/use-permissions";

type UsePayrollEmployeeHistoryParams = {
  employeeId: string | null;
  period: PayrollPeriod;
};

/** Операции сотрудника за период: премии, удержания и выплаты. */
export type PayrollEmployeeHistory = {
  bonuses: PayrollTransactionItem[];
  penalties: PayrollTransactionItem[];
  payouts: PayrollPayoutItem[];
};

/**
 * История операций одного сотрудника за период.
 *
 * Ключи кэша начинаются с общих префиксов модуля (`payroll-transactions`,
 * `payroll-payouts`), поэтому правка и удаление операции обновляют историю
 * автоматически, без отдельной инвалидации.
 */
export function usePayrollEmployeeHistory({
  employeeId,
  period,
}: UsePayrollEmployeeHistoryParams) {
  const { isReady } = usePermissions();
  const periodKey = getPeriodKey(period);
  const enabled = Boolean(employeeId) && isReady;

  const bonusesQuery = useQuery({
    queryKey: [
      "payroll-transactions",
      "history",
      "bonus",
      employeeId,
      periodKey,
    ],
    queryFn: () =>
      getPayrollTransactions({
        kind: "bonus",
        period,
        employeeId: employeeId ?? undefined,
      }),
    enabled,
  });

  const penaltiesQuery = useQuery({
    queryKey: [
      "payroll-transactions",
      "history",
      "penalty",
      employeeId,
      periodKey,
    ],
    queryFn: () =>
      getPayrollTransactions({
        kind: "penalty",
        period,
        employeeId: employeeId ?? undefined,
      }),
    enabled,
  });

  const payoutsQuery = useQuery({
    queryKey: ["payroll-payouts", "history", employeeId, periodKey],
    queryFn: () =>
      getPayrollPayouts({ period, employeeId: employeeId ?? undefined }),
    enabled,
  });

  // Итоги за всё время не зависят от выбранного периода.
  const totalsQuery = useQuery({
    queryKey: ["payroll-employee-totals", employeeId],
    queryFn: () => getEmployeePayrollTotals(employeeId ?? ""),
    enabled,
  });

  return {
    bonuses: bonusesQuery.data ?? [],
    penalties: penaltiesQuery.data ?? [],
    payouts: payoutsQuery.data ?? [],
    totals: (totalsQuery.data ?? null) as PayrollEmployeeTotals | null,
    isLoading:
      bonusesQuery.isLoading ||
      penaltiesQuery.isLoading ||
      payoutsQuery.isLoading,
    isTotalsLoading: totalsQuery.isLoading,
    isError:
      bonusesQuery.isError || penaltiesQuery.isError || payoutsQuery.isError,
  };
}

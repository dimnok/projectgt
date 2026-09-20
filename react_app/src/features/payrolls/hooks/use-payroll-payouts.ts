"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useMemo } from "react";

import { getPayrollPayouts } from "@/features/payrolls/api/get-payroll-payouts";
import type { PayrollPeriod } from "@/features/payrolls/types/payroll.types";
import {
  calculateListTotals,
  filterListRowsByName,
  sortListRowsByDateDesc,
} from "@/features/payrolls/utils/payroll-lists";
import { getPeriodKey } from "@/features/payrolls/utils/payroll.utils";
import { usePermissions } from "@/hooks/use-permissions";

type UsePayrollPayoutsParams = {
  period: PayrollPeriod;
  search: string;
};

/** Список выплат за период. */
export function usePayrollPayouts({
  period,
  search,
}: UsePayrollPayoutsParams) {
  const { isReady: permissionsReady } = usePermissions();

  const query = useQuery({
    queryKey: ["payroll-payouts", getPeriodKey(period)],
    queryFn: () => getPayrollPayouts({ period }),
    enabled: permissionsReady,
    placeholderData: keepPreviousData,
  });

  const rows = useMemo(() => {
    const byName = filterListRowsByName(query.data ?? [], search);
    return sortListRowsByDateDesc(byName);
  }, [query.data, search]);

  const totals = useMemo(() => calculateListTotals(rows), [rows]);

  return {
    rows,
    totals,
    isLoading: !permissionsReady || query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    error: query.error,
    refetch: query.refetch,
  };
}

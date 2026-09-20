"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useMemo } from "react";

import { getPayrollTransactions } from "@/features/payrolls/api/get-payroll-transactions";
import type {
  PayrollPeriod,
  PayrollTransactionKind,
} from "@/features/payrolls/types/payroll.types";
import {
  calculateListTotals,
  filterListRowsByName,
  sortListRowsByDateDesc,
} from "@/features/payrolls/utils/payroll-lists";
import { getPeriodKey } from "@/features/payrolls/utils/payroll.utils";
import { usePermissions } from "@/hooks/use-permissions";

type UsePayrollTransactionsParams = {
  kind: PayrollTransactionKind;
  period: PayrollPeriod;
  selectedObjectIds: string[];
  search: string;
};

/** Список премий или удержаний за период. */
export function usePayrollTransactions({
  kind,
  period,
  selectedObjectIds,
  search,
}: UsePayrollTransactionsParams) {
  const { isReady: permissionsReady } = usePermissions();

  const query = useQuery({
    queryKey: [
      "payroll-transactions",
      kind,
      getPeriodKey(period),
      selectedObjectIds,
    ],
    queryFn: () =>
      getPayrollTransactions({ kind, period, selectedObjectIds }),
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

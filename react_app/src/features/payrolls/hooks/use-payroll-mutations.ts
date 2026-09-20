"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  createPayrollPayout,
  createPayrollPayoutsBatch,
  deletePayrollPayout,
  deletePayrollPayouts,
  updatePayrollPayout,
  type PayrollPayoutDraft,
} from "@/features/payrolls/api/mutate-payouts";
import {
  createPayrollTransaction,
  createPayrollTransactionsBatch,
  deletePayrollTransaction,
  deletePayrollTransactions,
  updatePayrollTransaction,
  type PayrollTransactionDraft,
} from "@/features/payrolls/api/mutate-transactions";
import type { PayrollTransactionKind } from "@/features/payrolls/types/payroll.types";

/**
 * После любой операции пересчитываются и ведомость месяца, и FIFO выплат,
 * и оба списка — иначе цифры на вкладках разойдутся.
 */
function useInvalidatePayroll() {
  const queryClient = useQueryClient();

  return () => {
    void queryClient.invalidateQueries({ queryKey: ["payroll-month"] });
    void queryClient.invalidateQueries({ queryKey: ["payroll-fifo"] });
    void queryClient.invalidateQueries({ queryKey: ["payroll-transactions"] });
    void queryClient.invalidateQueries({ queryKey: ["payroll-payouts"] });
    void queryClient.invalidateQueries({ queryKey: ["payroll-employee-totals"] });
  };
}

/** Создание, правка и удаление премий или удержаний. */
export function usePayrollTransactionMutations(kind: PayrollTransactionKind) {
  const invalidate = useInvalidatePayroll();

  return {
    create: useMutation({
      mutationFn: (input: { draft: PayrollTransactionDraft; id?: string }) =>
        createPayrollTransaction(kind, input.draft, input.id),
      onSuccess: invalidate,
    }),
    update: useMutation({
      mutationFn: (input: {
        id: string;
        patch: Partial<PayrollTransactionDraft>;
      }) => updatePayrollTransaction(kind, input.id, input.patch),
      onSuccess: invalidate,
    }),
    remove: useMutation({
      mutationFn: (id: string) => deletePayrollTransaction(kind, id),
      onSuccess: invalidate,
    }),
    createMany: useMutation({
      mutationFn: (drafts: PayrollTransactionDraft[]) =>
        createPayrollTransactionsBatch(kind, drafts),
      onSuccess: invalidate,
    }),
    removeMany: useMutation({
      mutationFn: (ids: string[]) => deletePayrollTransactions(kind, ids),
      onSuccess: invalidate,
    }),
  };
}

/** Создание, правка и удаление выплат. */
export function usePayrollPayoutMutations() {
  const invalidate = useInvalidatePayroll();

  return {
    create: useMutation({
      mutationFn: (input: { draft: PayrollPayoutDraft; id?: string }) =>
        createPayrollPayout(input.draft, input.id),
      onSuccess: invalidate,
    }),
    update: useMutation({
      mutationFn: (input: { id: string; patch: Partial<PayrollPayoutDraft> }) =>
        updatePayrollPayout(input.id, input.patch),
      onSuccess: invalidate,
    }),
    remove: useMutation({
      mutationFn: (id: string) => deletePayrollPayout(id),
      onSuccess: invalidate,
    }),
    createMany: useMutation({
      mutationFn: (drafts: PayrollPayoutDraft[]) =>
        createPayrollPayoutsBatch(drafts),
      onSuccess: invalidate,
    }),
    removeMany: useMutation({
      mutationFn: (ids: string[]) => deletePayrollPayouts(ids),
      onSuccess: invalidate,
    }),
  };
}

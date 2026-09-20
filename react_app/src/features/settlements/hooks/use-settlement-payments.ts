"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  createSettlementPayment,
  deleteSettlementPayment,
  getSettlementPayments,
  updateSettlementPayment,
} from "@/features/settlements/api/settlement-payments";
import type { SettlementPaymentDraft } from "@/features/settlements/types/settlement.types";
import {
  settlementQueryKey,
  settlementsQueryKey,
} from "@/features/settlements/hooks/use-settlements";

/** Ключ кэша оплат по счёту. */
export function settlementPaymentsQueryKey(settlementOperationId: string) {
  return ["settlement-payments", settlementOperationId] as const;
}

/** Оплаты по счёту. */
export function useSettlementPayments(
  settlementOperationId: string | null,
  enabled = true
) {
  return useQuery({
    queryKey: settlementPaymentsQueryKey(settlementOperationId ?? "none"),
    queryFn: () => getSettlementPayments(settlementOperationId as string),
    enabled: Boolean(settlementOperationId) && enabled,
  });
}

/**
 * Сбрасывает кэш после правки оплаты: сами оплаты, реестр и карточку счёта —
 * суммы и статус пересчитывает база.
 */
function invalidatePaymentDependents(
  queryClient: ReturnType<typeof useQueryClient>,
  settlementOperationId: string
) {
  void queryClient.invalidateQueries({
    queryKey: settlementPaymentsQueryKey(settlementOperationId),
  });
  void queryClient.invalidateQueries({ queryKey: settlementsQueryKey });
  void queryClient.invalidateQueries({
    queryKey: settlementQueryKey(settlementOperationId),
  });
}

/** Добавляет оплату по счёту. */
export function useCreateSettlementPayment(settlementOperationId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: SettlementPaymentDraft) =>
      createSettlementPayment(settlementOperationId, draft),
    onSuccess: () =>
      invalidatePaymentDependents(queryClient, settlementOperationId),
  });
}

/** Меняет оплату по счёту. */
export function useUpdateSettlementPayment(settlementOperationId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      paymentId,
      draft,
    }: {
      paymentId: string;
      draft: SettlementPaymentDraft;
    }) => updateSettlementPayment(paymentId, draft),
    onSuccess: () =>
      invalidatePaymentDependents(queryClient, settlementOperationId),
  });
}

/** Удаляет оплату по счёту. */
export function useDeleteSettlementPayment(settlementOperationId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (paymentId: string) => deleteSettlementPayment(paymentId),
    onSuccess: () =>
      invalidatePaymentDependents(queryClient, settlementOperationId),
  });
}

"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  getPurchaseRequestCounts,
  getPurchaseRequests,
} from "@/features/purchase-requests/api/get-purchase-requests";
import { getPurchaseRequestsPaidByObject } from "@/features/purchase-requests/api/get-purchase-requests-paid-by-object";
import { getPurchaseRequestDetails } from "@/features/purchase-requests/api/get-purchase-request-details";
import {
  createPurchaseRequestDraft,
  deletePurchaseRequestDraft,
  replacePurchaseRequestItems,
  updatePurchaseRequestDraft,
} from "@/features/purchase-requests/api/mutate-draft";
import {
  approvePurchaseRequest,
  approvePurchaseRequestInvoice,
  markPurchaseRequestPaid,
  markPurchaseRequestReceived,
  queuePurchaseRequestPayment,
  returnPurchaseRequest,
  returnPurchaseRequestInvoice,
  submitPurchaseRequest,
  submitPurchaseRequestInvoices,
} from "@/features/purchase-requests/api/mutate-workflow";
import {
  createPurchaseRequestInvoice,
  deletePurchaseRequestInvoice,
} from "@/features/purchase-requests/api/mutate-invoices";
import { recognizePurchaseRequestInvoice } from "@/features/purchase-requests/api/recognize-purchase-invoice";
import {
  getPurchaseRequestCompanyUsers,
  getPurchaseRequestSettings,
  upsertPurchaseRequestSettings,
} from "@/features/purchase-requests/api/purchase-request-settings";
import { notifyPurchaseRequestPush } from "@/features/purchase-requests/api/notify-purchase-request-push";
import type {
  PurchaseRequestItemDraft,
  PurchaseRequestListFilter,
  PurchaseRequestSettings,
} from "@/features/purchase-requests/types/purchase-request.types";

/** Ключи кэша модуля. Наружу не отдаём — используются только здесь. */
const purchaseRequestsQueryKey = ["purchase-requests", "list"] as const;
const purchaseRequestCountsQueryKey = ["purchase-requests", "counts"] as const;
const purchaseRequestDetailsQueryKey = ["purchase-requests", "details"] as const;
const purchaseRequestSettingsQueryKey = ["purchase-requests", "settings"] as const;
const purchaseRequestPaidByObjectQueryKey = [
  "purchase-requests",
  "paid-by-object",
] as const;

export function usePurchaseRequests(
  filter: PurchaseRequestListFilter,
  search: string
) {
  return useQuery({
    queryKey: [...purchaseRequestsQueryKey, filter, search],
    queryFn: () => getPurchaseRequests({ filter, search }),
  });
}

/** Счётчики по статусам. `enabled` нужен, когда блок показывают по правам. */
export function usePurchaseRequestCounts(search: string, enabled = true) {
  return useQuery({
    queryKey: [...purchaseRequestCountsQueryKey, search],
    queryFn: () => getPurchaseRequestCounts(search),
    enabled,
  });
}

/** KPI «Оплачено по объектам». */
export function usePurchaseRequestPaidByObject(enabled = true) {
  return useQuery({
    queryKey: purchaseRequestPaidByObjectQueryKey,
    queryFn: getPurchaseRequestsPaidByObject,
    enabled,
  });
}

export function usePurchaseRequestDetails(requestId: string | null) {
  return useQuery({
    queryKey: [...purchaseRequestDetailsQueryKey, requestId],
    queryFn: () => getPurchaseRequestDetails(requestId!),
    enabled: Boolean(requestId),
  });
}

export function usePurchaseRequestSettings() {
  return useQuery({
    queryKey: purchaseRequestSettingsQueryKey,
    queryFn: getPurchaseRequestSettings,
  });
}

export function usePurchaseRequestCompanyUsers(enabled: boolean) {
  return useQuery({
    queryKey: ["purchase-requests", "company-users"],
    queryFn: getPurchaseRequestCompanyUsers,
    enabled,
  });
}

function useInvalidatePurchaseRequests() {
  const queryClient = useQueryClient();
  return (requestId?: string) => {
    void queryClient.invalidateQueries({ queryKey: purchaseRequestsQueryKey });
    void queryClient.invalidateQueries({ queryKey: purchaseRequestCountsQueryKey });
    void queryClient.invalidateQueries({
      queryKey: purchaseRequestPaidByObjectQueryKey,
    });
    if (requestId) {
      void queryClient.invalidateQueries({
        queryKey: [...purchaseRequestDetailsQueryKey, requestId],
      });
    } else {
      void queryClient.invalidateQueries({
        queryKey: purchaseRequestDetailsQueryKey,
      });
    }
  };
}

export function useCreatePurchaseRequestDraft() {
  const invalidate = useInvalidatePurchaseRequests();
  return useMutation({
    mutationFn: createPurchaseRequestDraft,
    onSuccess: (id) => invalidate(id),
  });
}

export function useUpdatePurchaseRequestDraft() {
  const invalidate = useInvalidatePurchaseRequests();
  return useMutation({
    mutationFn: updatePurchaseRequestDraft,
    onSuccess: (id) => invalidate(id),
  });
}

export function useDeletePurchaseRequestDraft() {
  const invalidate = useInvalidatePurchaseRequests();
  return useMutation({
    mutationFn: deletePurchaseRequestDraft,
    onSuccess: (_void, requestId) => invalidate(requestId),
  });
}

export function useReplacePurchaseRequestItems(requestId: string) {
  const invalidate = useInvalidatePurchaseRequests();
  return useMutation({
    mutationFn: (items: PurchaseRequestItemDraft[]) =>
      replacePurchaseRequestItems(requestId, items),
    onSuccess: () => invalidate(requestId),
  });
}

/**
 * Распознавание счёта по кнопке. Ничего не сохраняет — результат уходит в форму,
 * поэтому кэш заявок не трогаем.
 */
export function useRecognizePurchaseRequestInvoice() {
  return useMutation({
    mutationFn: (input: { requestId: string; file: File }) =>
      recognizePurchaseRequestInvoice(input),
  });
}

export function useUpsertPurchaseRequestSettings() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (settings: PurchaseRequestSettings) =>
      upsertPurchaseRequestSettings(settings),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: purchaseRequestSettingsQueryKey,
      });
    },
  });
}

export function usePurchaseRequestWorkflow(requestId: string) {
  const invalidate = useInvalidatePurchaseRequests();

  /** Смена статуса: обновляем данные и запускаем push получателям. */
  const afterTransition = {
    onSuccess: () => {
      invalidate(requestId);
      void notifyPurchaseRequestPush(requestId);
    },
  };

  /** Счёт статус заявки не меняет — push не нужен. */
  const after = {
    onSuccess: () => invalidate(requestId),
  };

  return {
    submit: useMutation({
      mutationFn: () => submitPurchaseRequest(requestId),
      ...afterTransition,
    }),
    approve: useMutation({
      mutationFn: () => approvePurchaseRequest(requestId),
      ...afterTransition,
    }),
    returnToRevision: useMutation({
      mutationFn: (comment: string) => returnPurchaseRequest(requestId, comment),
      ...afterTransition,
    }),
    submitInvoices: useMutation({
      mutationFn: () => submitPurchaseRequestInvoices(requestId),
      ...afterTransition,
    }),
    approveInvoice: useMutation({
      mutationFn: () => approvePurchaseRequestInvoice(requestId),
      ...afterTransition,
    }),
    returnInvoice: useMutation({
      mutationFn: (comment: string) =>
        returnPurchaseRequestInvoice(requestId, comment),
      ...afterTransition,
    }),
    queuePayment: useMutation({
      mutationFn: () => queuePurchaseRequestPayment(requestId),
      ...afterTransition,
    }),
    markPaid: useMutation({
      mutationFn: () => markPurchaseRequestPaid(requestId),
      ...afterTransition,
    }),
    markReceived: useMutation({
      mutationFn: () => markPurchaseRequestReceived(requestId),
      ...afterTransition,
    }),
    createInvoice: useMutation({
      mutationFn: createPurchaseRequestInvoice,
      ...after,
    }),
    deleteInvoice: useMutation({
      mutationFn: deletePurchaseRequestInvoice,
      ...after,
    }),
  };
}

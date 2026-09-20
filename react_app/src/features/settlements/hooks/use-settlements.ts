"use client";

import {
  keepPreviousData,
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";

import { createSettlement } from "@/features/settlements/api/create-settlement";
import { deleteSettlement } from "@/features/settlements/api/delete-settlement";
import { getSettlement } from "@/features/settlements/api/get-settlement";
import { getSettlements } from "@/features/settlements/api/get-settlements";
import {
  SETTLEMENT_PAGE_SIZE,
  getSettlementsPage,
  getSettlementsSummary,
  type SettlementListQuery,
} from "@/features/settlements/api/settlement-list";
import { updateSettlement } from "@/features/settlements/api/update-settlement";
import type {
  Settlement,
  SettlementDraft,
} from "@/features/settlements/types/settlement.types";

/** Корневой ключ кэша реестра: по нему сбрасываем список и карточки. */
export const settlementsQueryKey = ["settlements"] as const;

/** Ключ кэша одного счёта. */
export function settlementQueryKey(id: string) {
  return ["settlement", id] as const;
}

/** Счета активной компании; при `contractId` — только по договору. */
export function useSettlements(contractId?: string, enabled = true) {
  return useQuery({
    queryKey: contractId
      ? [...settlementsQueryKey, contractId]
      : settlementsQueryKey,
    queryFn: () => getSettlements(contractId),
    enabled,
  });
}

/** Один счёт по идентификатору. */
export function useSettlement(id: string | null) {
  return useQuery({
    queryKey: id ? settlementQueryKey(id) : ["settlement", "none"],
    queryFn: () => getSettlement(id as string),
    enabled: Boolean(id),
  });
}

/** Значимые части фильтров — чтобы кэш не зависел от лишних полей. */
function filterKeyParts(query: SettlementListQuery) {
  return {
    search: query.search ?? "",
    operationType: query.operationType ?? "all",
    paymentStatus: query.paymentStatus ?? "all",
    contractorId: query.contractorId ?? "",
    objectId: query.objectId ?? "",
    contractId: query.contractId ?? "",
  };
}

/** Части запроса страницы: фильтры, сортировка и страница. */
function pageKeyParts(query: SettlementListQuery) {
  return {
    ...filterKeyParts(query),
    sort: query.sort ? `${query.sort.key}:${query.sort.direction}` : "none",
    page: query.page ?? 0,
    pageSize: query.pageSize ?? SETTLEMENT_PAGE_SIZE,
  };
}

/** Ключ кэша страницы реестра (включая страницу и размер страницы). */
export function settlementsPageQueryKey(query: SettlementListQuery) {
  return [...settlementsQueryKey, "page", pageKeyParts(query)] as const;
}

/** Ключ кэша итогов по счетам: только фильтры, без сортировки и страницы. */
export function settlementsSummaryQueryKey(query: SettlementListQuery) {
  return [...settlementsQueryKey, "summary", filterKeyParts(query)] as const;
}

/**
 * Страница реестра счетов: поиск, фильтры и сортировку считает сервер.
 *
 * Обновляется при возврате на вкладку — оплаты могли измениться в ДДС.
 */
export function useSettlementsPage(query: SettlementListQuery) {
  return useQuery({
    queryKey: settlementsPageQueryKey(query),
    queryFn: () => getSettlementsPage(query),
    placeholderData: keepPreviousData,
    refetchOnWindowFocus: true,
  });
}

/**
 * Реестр с дозагрузкой (телефон).
 *
 * «Показать ещё» догружает следующую порцию и не перечитывает уже показанные
 * строки: страницы копятся в `data.pages`. Общее число берётся из первой
 * страницы — его считает база вместе со строками.
 */
export function useSettlementsInfinitePage(query: SettlementListQuery) {
  const pageSize = query.pageSize ?? SETTLEMENT_PAGE_SIZE;

  return useInfiniteQuery({
    queryKey: [...settlementsQueryKey, "infinite", filterKeyParts(query)],
    queryFn: ({ pageParam }) =>
      getSettlementsPage({ ...query, page: pageParam, pageSize }),
    initialPageParam: 0,
    getNextPageParam: (lastPage, pages) => {
      const loaded = pages.reduce((sum, page) => sum + page.items.length, 0);
      return loaded < lastPage.total ? pages.length : undefined;
    },
    placeholderData: keepPreviousData,
    refetchOnWindowFocus: true,
  });
}

/** Итоги по счетам для полосы показателей. */
export function useSettlementsSummary(query: SettlementListQuery) {
  return useQuery({
    queryKey: settlementsSummaryQueryKey(query),
    queryFn: () => getSettlementsSummary(query),
    refetchOnWindowFocus: true,
  });
}

/** Создаёт счёт и обновляет реестр и карточку. */
export function useCreateSettlement() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: SettlementDraft) => createSettlement(draft),
    onSuccess: (settlement: Settlement) => {
      void queryClient.invalidateQueries({ queryKey: settlementsQueryKey });
      void queryClient.invalidateQueries({
        queryKey: settlementQueryKey(settlement.id),
      });
    },
  });
}

/** Сохраняет правки счёта и обновляет реестр и карточку. */
export function useUpdateSettlement() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      settlement,
      draft,
    }: {
      settlement: Settlement;
      draft: SettlementDraft;
    }) => updateSettlement(settlement, draft),
    onSuccess: (settlement: Settlement) => {
      void queryClient.invalidateQueries({ queryKey: settlementsQueryKey });
      void queryClient.invalidateQueries({
        queryKey: settlementQueryKey(settlement.id),
      });
    },
  });
}

/** Удаляет счёт вместе с файлами. */
export function useDeleteSettlement() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteSettlement(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: settlementsQueryKey });
    },
  });
}

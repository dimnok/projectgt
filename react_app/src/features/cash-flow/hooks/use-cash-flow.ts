"use client";

import {
  keepPreviousData,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";

import {
  CASH_FLOW_PAGE_SIZE,
  getCashFlowMonthlyAnalytics,
  getCashFlowPage,
  getCashFlowSummary,
  type CashFlowListQuery,
} from "@/features/cash-flow/api/cash-flow-list";
import { createCashFlowTransaction } from "@/features/cash-flow/api/create-cash-flow-transaction";
import { deleteCashFlowCategory } from "@/features/cash-flow/api/delete-cash-flow-category";
import { deleteCashFlowTransaction } from "@/features/cash-flow/api/delete-cash-flow-transaction";
import { getCashFlowCategories } from "@/features/cash-flow/api/get-cash-flow-categories";
import {
  saveCashFlowCategory,
  type CashFlowCategoryDraft,
} from "@/features/cash-flow/api/save-cash-flow-category";
import { updateCashFlowTransaction } from "@/features/cash-flow/api/update-cash-flow-transaction";
import type { CashFlowDraft } from "@/features/cash-flow/types/cash-flow.types";
import { settlementsQueryKey } from "@/features/settlements/hooks/use-settlements";

/** Корневой ключ кэша реестра: по нему сбрасываем список, итоги и аналитику. */
export const cashFlowQueryKey = ["cash-flow"] as const;

/** Ключ кэша справочника статей ДДС. */
export const cashFlowCategoriesQueryKey = ["cash-flow-categories"] as const;

/** Значимые части фильтров — чтобы кэш не зависел от лишних полей. */
function filterKeyParts(query: CashFlowListQuery) {
  return {
    search: query.search?.trim() ?? "",
    year: query.year,
    objectId: query.objectId ?? "",
    contractorId: query.contractorId ?? "",
    contractIds: [...(query.contractIds ?? [])].sort().join(","),
    types: [...(query.types ?? [])].sort().join(","),
  };
}

/** Ключ кэша страницы реестра (включая страницу, размер и сортировку). */
export function cashFlowPageQueryKey(query: CashFlowListQuery) {
  return [
    ...cashFlowQueryKey,
    "page",
    {
      ...filterKeyParts(query),
      sort: query.sort ? `${query.sort.key}:${query.sort.direction}` : "none",
      page: query.page ?? 0,
      pageSize: query.pageSize ?? CASH_FLOW_PAGE_SIZE,
    },
  ] as const;
}

/** Ключ кэша итогов: только фильтры, без сортировки и страницы. */
export function cashFlowSummaryQueryKey(query: CashFlowListQuery) {
  return [...cashFlowQueryKey, "summary", filterKeyParts(query)] as const;
}

/** Ключ кэша аналитики: только фильтры, без сортировки и страницы. */
export function cashFlowAnalyticsQueryKey(query: CashFlowListQuery) {
  return [...cashFlowQueryKey, "analytics", filterKeyParts(query)] as const;
}

/**
 * Страница реестра операций: поиск, фильтры и сортировку считает сервер.
 *
 * Обновляется при возврате на вкладку — операции могли измениться
 * в приложении или при обработке банковской выписки.
 */
export function useCashFlowPage(query: CashFlowListQuery) {
  return useQuery({
    queryKey: cashFlowPageQueryKey(query),
    queryFn: () => getCashFlowPage(query),
    placeholderData: keepPreviousData,
    refetchOnWindowFocus: true,
  });
}

/** Итоги за период для полосы показателей. */
export function useCashFlowSummary(query: CashFlowListQuery) {
  return useQuery({
    queryKey: cashFlowSummaryQueryKey(query),
    queryFn: () => getCashFlowSummary(query),
    placeholderData: keepPreviousData,
    refetchOnWindowFocus: true,
  });
}

/**
 * Аналитика по месяцам за период.
 *
 * `enabled: false` откладывает загрузку: аналитика нужна только на своей
 * вкладке, а не при каждом изменении фильтров реестра.
 */
export function useCashFlowMonthlyAnalytics(
  query: CashFlowListQuery,
  enabled = true
) {
  return useQuery({
    queryKey: cashFlowAnalyticsQueryKey(query),
    queryFn: () => getCashFlowMonthlyAnalytics(query),
    enabled,
    placeholderData: keepPreviousData,
    refetchOnWindowFocus: true,
  });
}

/** Статьи ДДС компании. */
export function useCashFlowCategories() {
  return useQuery({
    queryKey: cashFlowCategoriesQueryKey,
    queryFn: getCashFlowCategories,
  });
}

/** Создаёт операцию и обновляет реестр. */
export function useCreateCashFlowTransaction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: CashFlowDraft) => createCashFlowTransaction(draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: cashFlowQueryKey });
    },
  });
}

/** Сохраняет правки операции и обновляет реестр. */
export function useUpdateCashFlowTransaction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, draft }: { id: string; draft: CashFlowDraft }) =>
      updateCashFlowTransaction(id, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: cashFlowQueryKey });
    },
  });
}

/**
 * Удаляет операцию и обновляет реестр.
 *
 * База удаляет вместе с операцией оплату по счёту взаиморасчётов, если
 * операция была создана из банковской выписки, — поэтому сбрасываем и кэш
 * взаиморасчётов.
 */
export function useDeleteCashFlowTransaction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteCashFlowTransaction(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: cashFlowQueryKey });
      void queryClient.invalidateQueries({ queryKey: settlementsQueryKey });
    },
  });
}

/** Создаёт или переименовывает статью ДДС. */
export function useSaveCashFlowCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      draft,
      categoryId,
    }: {
      draft: CashFlowCategoryDraft;
      categoryId?: string;
    }) => saveCashFlowCategory(draft, categoryId),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: cashFlowCategoriesQueryKey });
      void queryClient.invalidateQueries({ queryKey: cashFlowQueryKey });
    },
  });
}

/** Удаляет статью ДДС. */
export function useDeleteCashFlowCategory() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteCashFlowCategory(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: cashFlowCategoriesQueryKey });
      void queryClient.invalidateQueries({ queryKey: cashFlowQueryKey });
    },
  });
}

"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { deleteCompanyBankAccount } from "@/features/company/api/delete-company-bank-account";
import { getCompanyBankAccounts } from "@/features/company/api/get-company-bank-accounts";
import {
  createCompanyBankAccount,
  updateCompanyBankAccount,
} from "@/features/company/api/save-company-bank-account";
import type { CompanyBankAccountDraft } from "@/features/company/types/company.types";
import { useAuth } from "@/hooks/use-auth";

export const companyBankAccountsQueryKey = ["company-bank-accounts"] as const;

/**
 * Банковские счета компании.
 *
 * `enabled: false` откладывает загрузку: реквизиты нужны только для PDF счёта,
 * и их можно запросить вручную через `refetch()`.
 */
export function useCompanyBankAccounts(options?: { enabled?: boolean }) {
  const { session } = useAuth();

  return useQuery({
    queryKey: companyBankAccountsQueryKey,
    queryFn: getCompanyBankAccounts,
    enabled: Boolean(session?.user) && (options?.enabled ?? true),
  });
}

export function useCreateCompanyBankAccount() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: CompanyBankAccountDraft) =>
      createCompanyBankAccount(draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyBankAccountsQueryKey,
      });
    },
  });
}

export function useUpdateCompanyBankAccount() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      draft,
    }: {
      id: string;
      draft: CompanyBankAccountDraft;
    }) => updateCompanyBankAccount(id, draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyBankAccountsQueryKey,
      });
    },
  });
}

export function useDeleteCompanyBankAccount() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteCompanyBankAccount(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyBankAccountsQueryKey,
      });
    },
  });
}

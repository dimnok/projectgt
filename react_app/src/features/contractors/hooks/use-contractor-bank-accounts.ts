"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { getContractorBankAccounts } from "@/features/contractors/api/get-contractor-bank-accounts";
import {
  createContractorBankAccount,
  deleteContractorBankAccount,
  updateContractorBankAccount,
} from "@/features/contractors/api/save-contractor-bank-account";
import type {
  ContractorBankAccount,
  ContractorBankAccountDraft,
} from "@/features/contractors/types/contractor.types";

export function bankAccountsQueryKey(contractorId: string) {
  return ["contractor-bank-accounts", contractorId] as const;
}

export function useContractorBankAccounts(
  contractorId: string,
  enabled: boolean
) {
  return useQuery({
    queryKey: bankAccountsQueryKey(contractorId),
    queryFn: () => getContractorBankAccounts(contractorId),
    enabled,
  });
}

export function useCreateContractorBankAccount(contractorId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: ContractorBankAccountDraft) =>
      createContractorBankAccount(contractorId, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: bankAccountsQueryKey(contractorId),
      });
    },
  });
}

export function useUpdateContractorBankAccount(contractorId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      account,
      draft,
    }: {
      account: ContractorBankAccount;
      draft: ContractorBankAccountDraft;
    }) => updateContractorBankAccount(account, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: bankAccountsQueryKey(contractorId),
      });
    },
  });
}

export function useDeleteContractorBankAccount(contractorId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteContractorBankAccount(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: bankAccountsQueryKey(contractorId),
      });
    },
  });
}

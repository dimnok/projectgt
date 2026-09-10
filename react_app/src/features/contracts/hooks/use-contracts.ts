"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { createContract } from "@/features/contracts/api/create-contract";
import { deleteContract } from "@/features/contracts/api/delete-contract";
import { getContracts } from "@/features/contracts/api/get-contracts";
import { updateContract } from "@/features/contracts/api/update-contract";
import type {
  Contract,
  ContractDraft,
} from "@/features/contracts/types/contract.types";

const contractsQueryKey = ["contracts"] as const;

export function useContracts() {
  return useQuery({
    queryKey: contractsQueryKey,
    queryFn: getContracts,
  });
}

export function useCreateContract() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: ContractDraft) => createContract(draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: contractsQueryKey });
    },
  });
}

export function useUpdateContract() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      contract,
      draft,
    }: {
      contract: Contract;
      draft: ContractDraft;
    }) => updateContract(contract, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: contractsQueryKey });
    },
  });
}

export function useDeleteContract() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteContract(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: contractsQueryKey });
    },
  });
}

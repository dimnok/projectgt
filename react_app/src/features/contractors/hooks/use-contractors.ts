"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { createContractor } from "@/features/contractors/api/create-contractor";
import { deleteContractor } from "@/features/contractors/api/delete-contractor";
import { getContractors } from "@/features/contractors/api/get-contractors";
import { updateContractor } from "@/features/contractors/api/update-contractor";
import type {
  Contractor,
  ContractorDraft,
} from "@/features/contractors/types/contractor.types";

const contractorsQueryKey = ["contractors"] as const;

export function useContractors() {
  return useQuery({
    queryKey: contractorsQueryKey,
    queryFn: getContractors,
  });
}

export function useCreateContractor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: ContractorDraft) => createContractor(draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: contractorsQueryKey });
    },
  });
}

export function useUpdateContractor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      contractor,
      draft,
    }: {
      contractor: Contractor;
      draft: ContractorDraft;
    }) => updateContractor(contractor, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: contractorsQueryKey });
    },
  });
}

export function useDeleteContractor() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteContractor(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: contractorsQueryKey });
    },
  });
}

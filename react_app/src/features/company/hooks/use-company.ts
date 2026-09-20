"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

import { createCompany } from "@/features/company/api/create-company";
import { joinCompany } from "@/features/company/api/join-company";
import { searchCompanyByInn } from "@/features/company/api/search-company-by-inn";
import type { CompanyDraft } from "@/features/company/types/company.types";

export function useCreateCompany() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: CompanyDraft) => createCompany(draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries();
    },
  });
}

export function useJoinCompany() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (invitationCode: string) => joinCompany(invitationCode),
    onSuccess: async () => {
      await queryClient.invalidateQueries();
    },
  });
}

export function useSearchCompanyByInn() {
  return useMutation({
    mutationFn: (inn: string) => searchCompanyByInn(inn),
  });
}

"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { deleteCompanyDocument } from "@/features/company/api/delete-company-document";
import { getCompanyDocuments } from "@/features/company/api/get-company-documents";
import {
  createCompanyDocument,
  updateCompanyDocument,
} from "@/features/company/api/save-company-document";
import type { CompanyDocumentDraft } from "@/features/company/types/company.types";
import { useAuth } from "@/hooks/use-auth";

export const companyDocumentsQueryKey = ["company-documents"] as const;

export function useCompanyDocuments() {
  const { session } = useAuth();

  return useQuery({
    queryKey: companyDocumentsQueryKey,
    queryFn: getCompanyDocuments,
    enabled: Boolean(session?.user),
  });
}

export function useCreateCompanyDocument() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: CompanyDocumentDraft) => createCompanyDocument(draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyDocumentsQueryKey,
      });
    },
  });
}

export function useUpdateCompanyDocument() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      draft,
    }: {
      id: string;
      draft: CompanyDocumentDraft;
    }) => updateCompanyDocument(id, draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyDocumentsQueryKey,
      });
    },
  });
}

export function useDeleteCompanyDocument() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteCompanyDocument(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyDocumentsQueryKey,
      });
    },
  });
}

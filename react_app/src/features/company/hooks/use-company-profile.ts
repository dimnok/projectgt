"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { getCompany } from "@/features/company/api/get-company";
import { updateCompany } from "@/features/company/api/update-company";
import type { CompanyDraft } from "@/features/company/types/company.types";
import { useAuth } from "@/hooks/use-auth";

export const companyProfileQueryKey = ["company-profile"] as const;

/**
 * Профиль активной компании.
 *
 * `enabled: false` откладывает загрузку: реквизиты нужны только для PDF счёта,
 * и их можно запросить вручную через `refetch()`.
 */
export function useCompanyProfile(options?: { enabled?: boolean }) {
  const { session } = useAuth();

  return useQuery({
    queryKey: companyProfileQueryKey,
    queryFn: getCompany,
    enabled: Boolean(session?.user) && (options?.enabled ?? true),
  });
}

export function useUpdateCompany() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: CompanyDraft) => updateCompany(draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: companyProfileQueryKey });
      await queryClient.invalidateQueries({ queryKey: ["current-profile"] });
    },
  });
}

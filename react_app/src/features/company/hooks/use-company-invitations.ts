"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { createCompanyInvitation } from "@/features/company/api/create-company-invitation";
import { getCompanyInvitations } from "@/features/company/api/get-company-invitations";
import { revokeCompanyInvitation } from "@/features/company/api/revoke-company-invitation";
import { useAuth } from "@/hooks/use-auth";

export const companyInvitationsQueryKey = ["company-invitations"] as const;

export function useCompanyInvitations() {
  const { session } = useAuth();

  return useQuery({
    queryKey: companyInvitationsQueryKey,
    queryFn: getCompanyInvitations,
    enabled: Boolean(session?.user),
  });
}

export function useCreateCompanyInvitation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (expiresInDays: number) =>
      createCompanyInvitation(expiresInDays),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyInvitationsQueryKey,
      });
    },
  });
}

export function useRevokeCompanyInvitation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => revokeCompanyInvitation(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: companyInvitationsQueryKey,
      });
    },
  });
}

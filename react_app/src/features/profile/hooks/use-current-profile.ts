"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { deleteProfilePhoto, uploadProfilePhoto } from "@/features/profile/api/manage-profile-photo";
import { getCurrentProfile } from "@/features/profile/api/get-current-profile";
import { switchActiveCompany } from "@/features/profile/api/switch-company";
import { updateProfileNotifications } from "@/features/profile/api/update-profile-notifications";
import { updateCurrentProfile } from "@/features/profile/api/update-profile";
import {
  linkProfileEmployee,
  type LinkProfileEmployeeInput,
} from "@/features/profile/api/link-profile-employee";
import { updateCompanyMinOutputPerPersonHour } from "@/features/profile/api/update-company-output-norm";
import type { ProfileDraft } from "@/features/profile/types/profile.types";
import { companyUsersQueryKey } from "@/features/users/api/get-company-users";
import { useAuth } from "@/hooks/use-auth";

export const currentProfileQueryKey = ["current-profile"] as const;

export function useCurrentProfile() {
  const { session } = useAuth();

  return useQuery({
    queryKey: currentProfileQueryKey,
    queryFn: getCurrentProfile,
    enabled: Boolean(session?.user),
  });
}

export function useUpdateCurrentProfile() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: ProfileDraft) => updateCurrentProfile(draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: currentProfileQueryKey });
    },
  });
}

export function useUploadProfilePhoto() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => uploadProfilePhoto(file),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: currentProfileQueryKey });
    },
  });
}

export function useDeleteProfilePhoto() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => deleteProfilePhoto(),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: currentProfileQueryKey });
    },
  });
}

export function useSwitchActiveCompany() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (companyId: string) => switchActiveCompany(companyId),
    onSuccess: async () => {
      await queryClient.invalidateQueries();
    },
  });
}

export function useUpdateProfileNotifications() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (slotTimes: string[]) => updateProfileNotifications(slotTimes),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: currentProfileQueryKey });
    },
  });
}

export function useUpdateCompanyMinOutput() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (value: number | null) =>
      updateCompanyMinOutputPerPersonHour(value),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: currentProfileQueryKey });
    },
  });
}

export function useLinkProfileEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: LinkProfileEmployeeInput) => linkProfileEmployee(input),
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: currentProfileQueryKey }),
        queryClient.invalidateQueries({ queryKey: companyUsersQueryKey }),
      ]);
    },
  });
}

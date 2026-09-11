"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  currentProfileQueryKey,
  useCurrentProfile,
} from "@/features/profile/hooks/use-current-profile";
import { usePermissions } from "@/hooks/use-permissions";
import {
  companyUsersQueryKey,
  getCompanyUsers,
} from "@/features/users/api/get-company-users";
import {
  updateUserObjects,
  type UpdateUserObjectsInput,
} from "@/features/users/api/update-user-objects";

export { companyUsersQueryKey };

export function useCompanyUsers() {
  const { data: profile } = useCurrentProfile();
  const { can, isReady } = usePermissions();

  return useQuery({
    queryKey: companyUsersQueryKey,
    queryFn: getCompanyUsers,
    enabled: Boolean(profile && isReady && can("users", "read")),
  });
}

export function useUpdateUserObjects() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: UpdateUserObjectsInput) => updateUserObjects(input),
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: companyUsersQueryKey }),
        queryClient.invalidateQueries({ queryKey: currentProfileQueryKey }),
      ]);
    },
  });
}

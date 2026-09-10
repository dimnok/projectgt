"use client";

import { useQuery } from "@tanstack/react-query";

import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import { usePermissions } from "@/hooks/use-permissions";
import {
  companyUsersQueryKey,
  getCompanyUsers,
} from "@/features/users/api/get-company-users";

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

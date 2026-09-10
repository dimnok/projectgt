"use client";

import { useCallback } from "react";
import { useQuery } from "@tanstack/react-query";

import { isPermissionEnabled } from "@/config/permissions";
import {
  getRolePermissions,
  myRolePermissionsQueryKey,
} from "@/features/roles/api/get-role-permissions";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import { useAuth } from "@/hooks/use-auth";

/**
 * UI permission check. Matches Postgres `check_permission`:
 * owner (`is_owner`) has all rights; everyone else uses role_permissions.
 * Admin is not a full bypass.
 */
export function usePermissions() {
  const { session } = useAuth();
  const {
    data: profile,
    isFetched: profileFetched,
    isLoading: profileLoading,
  } = useCurrentProfile();

  const membership = profile?.activeMembership ?? null;
  const isOwner = membership?.isOwner === true;
  const roleId = membership?.roleId ?? null;
  const needsRole = Boolean(session && profileFetched && membership && !isOwner && !roleId);

  const permissionsQuery = useQuery({
    queryKey: myRolePermissionsQueryKey(roleId),
    queryFn: () => getRolePermissions(roleId!),
    enabled: Boolean(session && roleId && !isOwner),
  });

  const isReady =
    !session ||
    (profileFetched && (isOwner || !roleId || permissionsQuery.isFetched));

  const can = useCallback(
    (module: string, action: string) => {
      if (isOwner) {
        return true;
      }
      if (!roleId) {
        return false;
      }
      return isPermissionEnabled(permissionsQuery.data, module, action);
    },
    [isOwner, permissionsQuery.data, roleId]
  );

  return {
    can,
    isReady,
    isOwner,
    needsRole,
    isLoading: Boolean(session) && (profileLoading || permissionsQuery.isLoading),
  };
}

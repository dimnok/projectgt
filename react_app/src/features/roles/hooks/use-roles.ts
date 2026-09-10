"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { createCompanyRole } from "@/features/roles/api/create-role";
import { deleteCompanyRole } from "@/features/roles/api/delete-role";
import { getAppModules, appModulesQueryKey } from "@/features/roles/api/get-app-modules";
import {
  getRolePermissions,
  rolePermissionsQueryKey,
  myRolePermissionsQueryKey,
} from "@/features/roles/api/get-role-permissions";
import { companyRolesQueryKey, getCompanyRoles } from "@/features/roles/api/get-roles";
import { saveRolePermissions } from "@/features/roles/api/save-role-permissions";
import { updateMemberRole } from "@/features/roles/api/update-member-role";
import { currentProfileQueryKey } from "@/features/profile/hooks/use-current-profile";
import { companyUsersQueryKey } from "@/features/users/api/get-company-users";
import type { RolePermissionMap } from "@/config/permissions";

export function useCompanyRoles(enabled = true) {
  return useQuery({
    queryKey: companyRolesQueryKey,
    queryFn: getCompanyRoles,
    enabled,
  });
}

export function useAppModules(enabled = true) {
  return useQuery({
    queryKey: appModulesQueryKey,
    queryFn: getAppModules,
    enabled,
  });
}

export function useRolePermissions(roleId: string | null) {
  return useQuery({
    queryKey: roleId ? rolePermissionsQueryKey(roleId) : ["role-permissions", "none"],
    queryFn: () => getRolePermissions(roleId!),
    enabled: Boolean(roleId),
  });
}

export function useCreateRole() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createCompanyRole,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: companyRolesQueryKey });
    },
  });
}

export function useDeleteRole() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: deleteCompanyRole,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: companyRolesQueryKey });
    },
  });
}

export function useSaveRolePermissions() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      roleId,
      map,
    }: {
      roleId: string;
      map: RolePermissionMap;
    }) => saveRolePermissions(roleId, map),
    onSuccess: async (_data, variables) => {
      await Promise.all([
        queryClient.invalidateQueries({
          queryKey: rolePermissionsQueryKey(variables.roleId),
        }),
        queryClient.invalidateQueries({
          queryKey: myRolePermissionsQueryKey(variables.roleId),
        }),
      ]);
    },
  });
}

export function useUpdateMemberRole() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      userId,
      roleId,
    }: {
      userId: string;
      roleId: string | null;
    }) => updateMemberRole(userId, roleId),
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: companyUsersQueryKey }),
        queryClient.invalidateQueries({ queryKey: currentProfileQueryKey }),
        queryClient.invalidateQueries({ queryKey: ["my-role-permissions"] }),
      ]);
    },
  });
}

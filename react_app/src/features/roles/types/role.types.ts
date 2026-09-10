import type { RolePermissionMap } from "@/config/permissions";

export type AppModule = {
  id: string;
  code: string;
  name: string;
  sortOrder: number;
};

export type CompanyRole = {
  id: string;
  name: string;
  description: string;
  companyId: string | null;
  isSystem: boolean;
};

export type RolePermissionsState = {
  roleId: string;
  map: RolePermissionMap;
};

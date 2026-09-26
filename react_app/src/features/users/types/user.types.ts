import type { LinkedEmployee } from "@/features/profile/types/profile.types";
import type { TableSort } from "@/lib/table-sort";

export type CompanyUser = {
  id: string;
  fullName: string;
  shortName: string | null;
  photoUrl: string | null;
  email: string;
  phone: string;
  roleId: string | null;
  roleName: string;
  isActive: boolean;
  isOwner: boolean;
  employeeId: string | null;
  objectIds: string[];
  preferWebApp: boolean;
  linkedEmployee: LinkedEmployee | null;
};

export type CompanyUserLinkFilter = "all" | "linked" | "unlinked";

export type CompanyUserSortKey =
  | "name"
  | "role"
  | "status"
  | "employee"
  | "objects"
  | "web";

export type CompanyUserSort = TableSort<CompanyUserSortKey>;


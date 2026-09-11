import type { LinkedEmployee } from "@/features/profile/types/profile.types";

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
  linkedEmployee: LinkedEmployee | null;
};

export type CompanyUserLinkFilter = "all" | "linked" | "unlinked";

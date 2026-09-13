export type ProfileSystemRole = "owner" | "admin" | null;

export type ProfileCompanyMembership = {
  companyId: string;
  companyName: string;
  systemRole: ProfileSystemRole;
  roleId: string | null;
  roleName: string | null;
  isActive: boolean;
  isOwner: boolean;
  /** Минимум выработки, ₽ / чел. / час. Пусто — план не задан. */
  minOutputPerPersonHour: number | null;
};

export type ProfileObject = {
  id: string;
  name: string;
};

export type LinkedEmployee = {
  id: string;
  fullName: string;
  position: string | null;
  status: string | null;
  phone: string | null;
  employmentType: string | null;
  photoUrl: string | null;
};

export type CurrentProfile = {
  id: string;
  fullName: string;
  shortName: string | null;
  photoUrl: string | null;
  email: string;
  phone: string;
  employeeId: string | null;
  position: string | null;
  linkedEmployee: LinkedEmployee | null;
  lastCompanyId: string | null;
  objectIds: string[];
  objects: ProfileObject[];
  createdAt: string | null;
  slotTimes: string[];
  telegramUserId: number | null;
  memberships: ProfileCompanyMembership[];
  activeMembership: ProfileCompanyMembership | null;
  canManageUsers: boolean;
};

export type ProfileDraft = {
  fullName: string;
  phone: string;
};

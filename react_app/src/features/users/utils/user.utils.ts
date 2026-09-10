import type {
  CompanyUser,
  CompanyUserLinkFilter,
} from "@/features/users/types/user.types";
import { profileInitials } from "@/features/profile/utils/profile.utils";

export function userDisplayName(user: CompanyUser): string {
  return user.fullName.trim() || user.email || user.phone || "Пользователь";
}

export function userInitials(user: CompanyUser): string {
  return profileInitials(userDisplayName(user));
}

export function filterCompanyUsers(
  users: CompanyUser[],
  options: { search: string; link: CompanyUserLinkFilter }
): CompanyUser[] {
  const search = options.search.trim().toLowerCase();
  const digits = search.replace(/\D/g, "");

  return users.filter((user) => {
    if (options.link === "linked" && !user.employeeId) {
      return false;
    }
    if (options.link === "unlinked" && user.employeeId) {
      return false;
    }

    if (!search) {
      return true;
    }

    const haystack = [
      user.fullName,
      user.shortName ?? "",
      user.email,
      user.roleName,
      user.linkedEmployee?.fullName ?? "",
      user.linkedEmployee?.position ?? "",
    ]
      .join(" ")
      .toLowerCase();

    const phoneDigits = user.phone.replace(/\D/g, "");
    return (
      haystack.includes(search) ||
      Boolean(digits && phoneDigits.includes(digits))
    );
  });
}

export function countCompanyUsers(users: CompanyUser[]) {
  return {
    total: users.length,
    linked: users.filter((user) => Boolean(user.employeeId)).length,
    unlinked: users.filter((user) => !user.employeeId).length,
    inactive: users.filter((user) => !user.isActive).length,
  };
}

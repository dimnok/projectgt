import type {
  CompanyUser,
  CompanyUserLinkFilter,
} from "@/features/users/types/user.types";
import { profileInitials } from "@/features/profile/utils/profile.utils";

export function companyObjectIdsOfUser(
  objectIds: string[],
  companyObjectIds: Set<string>
): string[] {
  return [...new Set(objectIds.filter((id) => companyObjectIds.has(id)))];
}

export function userObjectNames(
  objectIds: string[],
  objects: { id: string; name: string }[]
): string[] {
  const names = new Map(objects.map((object) => [object.id, object.name]));
  return objectIds
    .map((id) => names.get(id))
    .filter((name): name is string => Boolean(name));
}

export function sameIdSet(left: string[], right: string[]): boolean {
  if (left.length !== right.length) {
    return false;
  }
  const rightSet = new Set(right);
  return left.every((id) => rightSet.has(id));
}

export function userDisplayName(user: CompanyUser): string {
  return user.fullName.trim() || user.email || user.phone || "Пользователь";
}

export function userInitials(user: CompanyUser): string {
  return profileInitials(userDisplayName(user));
}

export function filterCompanyUsers(
  users: CompanyUser[],
  options: {
    search: string;
    link: CompanyUserLinkFilter;
    objectNames?: Map<string, string>;
  }
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

    const assignedObjectNames = options.objectNames
      ? user.objectIds
          .map((id) => options.objectNames?.get(id) ?? "")
          .join(" ")
      : "";

    const haystack = [
      user.fullName,
      user.shortName ?? "",
      user.email,
      user.roleName,
      user.linkedEmployee?.fullName ?? "",
      user.linkedEmployee?.position ?? "",
      assignedObjectNames,
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
    withoutObjects: users.filter((user) => user.objectIds.length === 0).length,
    onWeb: users.filter((user) => user.preferWebApp).length,
  };
}

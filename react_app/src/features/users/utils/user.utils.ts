import type {
  CompanyUser,
  CompanyUserLinkFilter,
  CompanyUserSort,
  CompanyUserSortKey,
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

/** Разница двух строк по выбранной колонке: 0 — равны, знак задаёт порядок. */
function compareByKey(
  key: CompanyUserSortKey,
  left: CompanyUser,
  right: CompanyUser
): number {
  switch (key) {
    case "name":
      return userDisplayName(left).localeCompare(userDisplayName(right), "ru");
    case "role":
      return left.roleName.localeCompare(right.roleName, "ru");
    case "status":
      return Number(left.isActive) - Number(right.isActive);
    case "employee":
      return Number(Boolean(left.employeeId)) - Number(Boolean(right.employeeId));
    case "objects":
      return left.objectIds.length - right.objectIds.length;
    case "web":
      return Number(left.preferWebApp) - Number(right.preferWebApp);
  }
}

/** Сортировка списка пользователей. Равные значения идут по алфавиту. */
export function sortCompanyUsers(
  users: CompanyUser[],
  sort: CompanyUserSort
): CompanyUser[] {
  if (!sort) {
    return users;
  }

  const factor = sort.direction === "asc" ? 1 : -1;

  return [...users].sort((left, right) => {
    const diff = compareByKey(sort.key, left, right);
    if (diff !== 0) {
      return factor * diff;
    }
    return userDisplayName(left).localeCompare(userDisplayName(right), "ru");
  });
}

import type { ObjectFilters, SiteObject } from "@/features/objects/types/object.types";
import type { ObjectsRow } from "@/types/database.types";
import { isObjectStatus, type ObjectStatus } from "@/features/objects/utils/object-status";

export const OBJECT_SELECT =
  "id, company_id, name, address, description, status";

export function mapObjectRow(row: ObjectsRow): SiteObject {
  return {
    id: row.id,
    companyId: row.company_id,
    name: row.name,
    address: row.address,
    description: row.description,
    status: isObjectStatus(row.status) ? row.status : "active",
  };
}

export function sortObjectsByName(objects: SiteObject[]): SiteObject[] {
  return [...objects].sort((a, b) =>
    a.name.localeCompare(b.name, "ru", { sensitivity: "base" })
  );
}

export function filterObjects(
  objects: SiteObject[],
  filters: ObjectFilters
): SiteObject[] {
  const query = filters.search.trim().toLowerCase();

  return objects.filter((object) => {
    if (filters.status !== "all" && object.status !== filters.status) {
      return false;
    }
    if (!query) {
      return true;
    }
    const haystack =
      `${object.name} ${object.address} ${object.description ?? ""}`.toLowerCase();
    return haystack.includes(query);
  });
}

export function formatObjectCount(count: number): string {
  const n10 = count % 10;
  const n100 = count % 100;
  if (n10 === 1 && n100 !== 11) {
    return `${count} объект`;
  }
  if (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14)) {
    return `${count} объекта`;
  }
  return `${count} объектов`;
}

export function countObjectsByStatus(objects: SiteObject[]) {
  const byStatus: Record<ObjectStatus, number> = {
    active: 0,
    paused: 0,
    completed: 0,
  };

  for (const object of objects) {
    byStatus[object.status] += 1;
  }

  return {
    total: objects.length,
    byStatus,
  };
}

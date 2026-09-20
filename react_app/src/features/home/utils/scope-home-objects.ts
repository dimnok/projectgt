import type { SiteObject } from "@/features/objects/types/object.types";
import type { WorkAccessScope } from "@/features/works/api/get-work-membership";

/**
 * Limits home-page objects to the same scope as month shifts / the analytics chart.
 * Owner and super-admin see every company object; everyone else sees only
 * objects listed in `profiles.object_ids`.
 */
export function scopeHomeObjects(
  objects: SiteObject[],
  scope: WorkAccessScope | undefined
): SiteObject[] {
  if (!scope) {
    return [];
  }
  if (scope.isAllObjectsAccess) {
    return objects;
  }
  if (scope.objectIds.length === 0) {
    return [];
  }

  const allowed = new Set(scope.objectIds);
  return objects.filter((object) => allowed.has(object.id));
}

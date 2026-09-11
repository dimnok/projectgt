import { assertPermission } from "@/features/roles/api/assert-permission";
import type { LinkedEmployee } from "@/features/profile/types/profile.types";
import {
  asBoolean,
  asString,
  nestedRecord,
} from "@/features/profile/utils/nested-record";
import { membershipRoleLabel, parseSystemRole } from "@/features/profile/utils/profile.utils";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { formatPhone } from "@/lib/utils/phone";
import type { CompanyUser } from "@/features/users/types/user.types";

export const companyUsersQueryKey = ["company-users"] as const;

type MemberQueryRow = {
  user_id: string;
  system_role: string | null;
  role_id: string | null;
  is_active: boolean | null;
  is_owner: boolean | null;
  roles: { role_name: string | null } | { role_name: string | null }[] | null;
  profiles:
    | {
        id: string;
        full_name: string | null;
        short_name: string | null;
        photo_url: string | null;
        email: string | null;
        phone: string | null;
        employee_id: string | null;
        object_ids: string[] | null;
      }
    | {
        id: string;
        full_name: string | null;
        short_name: string | null;
        photo_url: string | null;
        email: string | null;
        phone: string | null;
        employee_id: string | null;
        object_ids: string[] | null;
      }[]
    | null;
};

type EmployeeQueryRow = {
  id: string;
  last_name: string | null;
  first_name: string | null;
  middle_name: string | null;
  position: string | null;
  status: string | null;
  phone: string | null;
  employment_type: string | null;
  photo_url: string | null;
};

function mapLinkedEmployee(row: EmployeeQueryRow): LinkedEmployee {
  const fullName = [row.last_name, row.first_name, row.middle_name]
    .filter(Boolean)
    .join(" ")
    .trim();

  return {
    id: row.id,
    fullName: fullName || "Сотрудник",
    position: asString(row.position),
    status: asString(row.status),
    phone: formatPhone(row.phone),
    employmentType: asString(row.employment_type),
    photoUrl: row.photo_url,
  };
}

/**
 * Loads company members for the active company.
 * Visible with `users.read`. Employee linking still requires `users.update`.
 */
export async function getCompanyUsers(): Promise<CompanyUser[]> {
  const { client } = await assertPermission("users", "read");
  const companyId = await getActiveCompanyId();

  const membersResult = await client
    .from("company_members")
    .select(
      "user_id, system_role, role_id, is_active, is_owner, roles(role_name), profiles(id, full_name, short_name, photo_url, email, phone, employee_id, object_ids)"
    )
    .eq("company_id", companyId);

  if (membersResult.error) {
    throw new Error(membersResult.error.message);
  }

  const members = (membersResult.data ?? []) as MemberQueryRow[];
  const employeeIds = members
    .map((row) => {
      const profile = nestedRecord(row.profiles);
      return asString(profile?.employee_id);
    })
    .filter((id): id is string => Boolean(id));

  const employeesById = new Map<string, LinkedEmployee>();

  if (employeeIds.length > 0) {
    const employeesResult = await client
      .from("employees")
      .select(
        "id, last_name, first_name, middle_name, position, status, phone, employment_type, photo_url"
      )
      .in("id", employeeIds);

    if (employeesResult.error) {
      throw new Error(employeesResult.error.message);
    }

    for (const row of (employeesResult.data ?? []) as EmployeeQueryRow[]) {
      employeesById.set(row.id, mapLinkedEmployee(row));
    }
  }

  return members
    .map((row) => {
      const profile = nestedRecord(row.profiles);
      if (!profile) {
        return null;
      }

      const employeeId = asString(profile.employee_id);
      const systemRole = parseSystemRole(row.system_role);
      const roleRecord = nestedRecord(row.roles);
      const isOwner = asBoolean(row.is_owner, row.system_role === "owner");

      return {
        id: asString(profile.id) ?? row.user_id,
        fullName: asString(profile.full_name) ?? "",
        shortName: asString(profile.short_name),
        photoUrl: asString(profile.photo_url),
        email: asString(profile.email) ?? "",
        phone: formatPhone(asString(profile.phone)),
        roleId: row.role_id,
        roleName: membershipRoleLabel({
          companyId,
          companyName: "",
          systemRole,
          roleId: row.role_id,
          roleName: asString(roleRecord?.role_name),
          isActive: asBoolean(row.is_active, true),
          isOwner,
        }),
        isActive: asBoolean(row.is_active, true),
        isOwner,
        employeeId,
        objectIds: Array.isArray(profile.object_ids)
          ? profile.object_ids.filter(
              (id): id is string => typeof id === "string" && id.length > 0
            )
          : [],
        linkedEmployee: employeeId ? employeesById.get(employeeId) ?? null : null,
      } satisfies CompanyUser;
    })
    .filter((item): item is CompanyUser => item !== null)
    .sort((a, b) => a.fullName.localeCompare(b.fullName, "ru"));
}

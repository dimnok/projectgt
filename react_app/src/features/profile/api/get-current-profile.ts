import { getRequiredClient } from "@/lib/supabase/client";
import { formatPhone } from "@/lib/utils/phone";
import type {
  CompaniesRow,
  ProfilesRow,
} from "@/types/database.types";
import type {
  CurrentProfile,
  ProfileCompanyMembership,
  ProfileObject,
} from "@/features/profile/types/profile.types";
import {
  asBoolean,
  asNumber,
  asString,
  nestedRecord,
} from "@/features/profile/utils/nested-record";
import { canManageUsers } from "@/features/profile/api/can-manage-users";
import {
  companyDisplayName,
  parseSystemRole,
} from "@/features/profile/utils/profile.utils";

const PROFILE_SELECT = [
  "id",
  "full_name",
  "short_name",
  "photo_url",
  "email",
  "phone",
  "employee_id",
  "last_company_id",
  "object_ids",
  "slot_times",
  "telegram_user_id",
  "created_at",
].join(", ");

type MemberQueryRow = {
  company_id: string;
  system_role: string | null;
  role_id: string | null;
  is_active: boolean | null;
  is_owner: boolean | null;
  companies: CompaniesRow | CompaniesRow[] | null;
  roles: { id: string; role_name: string | null } | { id: string; role_name: string | null }[] | null;
};

function mapMembership(row: MemberQueryRow): ProfileCompanyMembership {
  const company = nestedRecord(row.companies);
  const role = nestedRecord(row.roles);

  return {
    companyId: row.company_id,
    companyName: companyDisplayName(
      asString(company?.name_short),
      asString(company?.name_full)
    ),
    systemRole: parseSystemRole(row.system_role),
    roleId: row.role_id,
    roleName: asString(role?.role_name),
    isActive: asBoolean(row.is_active, true),
    isOwner: asBoolean(row.is_owner, row.system_role === "owner"),
    minOutputPerPersonHour: asNumber(company?.min_output_per_person_hour),
  };
}

/**
 * Loads the signed-in user's profile, company memberships, and assigned objects.
 */
export async function getCurrentProfile(): Promise<CurrentProfile> {
  const client = getRequiredClient();
  const {
    data: { user },
    error: userError,
  } = await client.auth.getUser();

  if (userError || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  const profileResult = await client
    .from("profiles")
    .select(PROFILE_SELECT)
    .eq("id", user.id)
    .maybeSingle();

  if (profileResult.error) {
    throw new Error(profileResult.error.message);
  }

  const profile = profileResult.data as ProfilesRow | null;
  if (!profile) {
    throw new Error("Профиль не найден");
  }

  const membersResult = await client
    .from("company_members")
    .select(
      "company_id, system_role, role_id, is_active, is_owner, companies(id, name_short, name_full, min_output_per_person_hour), roles(id, role_name)"
    )
    .eq("user_id", user.id);

  if (membersResult.error) {
    throw new Error(membersResult.error.message);
  }

  const memberships = ((membersResult.data ?? []) as MemberQueryRow[])
    .map(mapMembership)
    .sort((a, b) => a.companyName.localeCompare(b.companyName, "ru"));

  const lastCompanyId = profile.last_company_id;
  const activeMembership =
    memberships.find((item) => item.companyId === lastCompanyId) ??
    memberships.find((item) => item.isActive) ??
    null;

  let position: string | null = null;
  let linkedEmployee: CurrentProfile["linkedEmployee"] = null;

  if (profile.employee_id) {
    const employeeResult = await client
      .from("employees")
      .select(
        "id, last_name, first_name, middle_name, position, status, phone, employment_type, photo_url"
      )
      .eq("id", profile.employee_id)
      .maybeSingle();

    if (!employeeResult.error && employeeResult.data) {
      const row = employeeResult.data as {
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
      const fullName = [row.last_name, row.first_name, row.middle_name]
        .filter(Boolean)
        .join(" ")
        .trim();

      position = asString(row.position);
      linkedEmployee = {
        id: row.id,
        fullName: fullName || "Сотрудник",
        position,
        status: asString(row.status),
        phone: formatPhone(row.phone),
        employmentType: asString(row.employment_type),
        photoUrl: row.photo_url,
      };
    }
  }

  const objectIds = (profile.object_ids ?? []).filter(Boolean);
  let objects: ProfileObject[] = [];

  if (objectIds.length > 0) {
    const objectsResult = await client
      .from("objects")
      .select("id, name")
      .in("id", objectIds);

    if (!objectsResult.error) {
      objects = ((objectsResult.data ?? []) as { id: string; name: string }[])
        .map((row) => ({ id: row.id, name: row.name }))
        .sort((a, b) => a.name.localeCompare(b.name, "ru"));
    }
  }

  const phone = formatPhone(profile.phone) || formatPhone(user.phone);
  let canManage = false;
  try {
    canManage = await canManageUsers(client, user.id);
  } catch {
    canManage = false;
  }

  return {
    id: profile.id,
    fullName: profile.full_name?.trim() ?? "",
    shortName: profile.short_name,
    photoUrl: profile.photo_url,
    email: profile.email?.trim() || user.email || "",
    phone,
    employeeId: profile.employee_id,
    position,
    linkedEmployee,
    lastCompanyId,
    objectIds,
    objects,
    createdAt: profile.created_at,
    slotTimes: (profile.slot_times ?? []).filter(Boolean),
    telegramUserId: profile.telegram_user_id ?? null,
    memberships,
    activeMembership,
    canManageUsers: canManage,
  };
}

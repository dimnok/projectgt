import { formatPhone, normalizeRuPhoneE164 } from "@/lib/utils/phone";
import type {
  CurrentProfile,
  ProfileCompanyMembership,
  ProfileSystemRole,
} from "@/features/profile/types/profile.types";

/**
 * Builds a short display name: `Иванов И.И.` from a full name.
 * Same rule as Flutter `ProfileUtils.generateShortName`.
 */
export function generateShortName(fullName: string): string | null {
  const parts = fullName
    .trim()
    .split(/\s+/)
    .filter((part) => part.length > 0);

  if (parts.length === 0) {
    return null;
  }

  if (parts.length === 1) {
    return parts[0];
  }

  const lastName = parts[0];
  const initials = parts
    .slice(1)
    .map((part) => `${part[0].toUpperCase()}.`)
    .join("");

  return `${lastName} ${initials}`;
}

export function profileInitials(fullName: string): string {
  const trimmed = fullName.trim();
  const digits = trimmed.replace(/\D/g, "");

  if (!/[a-zа-яё]/i.test(trimmed)) {
    return digits.length >= 2 ? digits.slice(-2) : "П";
  }

  const parts = trimmed.split(/\s+/).filter((part) => part.length > 0);

  if (parts.length === 1) {
    return parts[0].slice(0, 2).toUpperCase();
  }

  return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
}

export function parseSystemRole(value: string | null | undefined): ProfileSystemRole {
  if (value === "owner" || value === "admin") {
    return value;
  }

  return null;
}

export function systemRoleLabel(role: ProfileSystemRole): string | null {
  if (role === "owner") {
    return "Владелец";
  }
  if (role === "admin") {
    return "Администратор";
  }
  return null;
}

export function membershipRoleLabel(
  membership: ProfileCompanyMembership | null
): string {
  if (!membership) {
    return "Участник";
  }

  return (
    systemRoleLabel(membership.systemRole) ??
    membership.roleName ??
    "Участник"
  );
}

export function companyDisplayName(
  shortName: string | null | undefined,
  fullName: string | null | undefined
): string {
  const short = shortName?.trim();
  const full = fullName?.trim();
  return short || full || "Компания";
}

export function profileDisplayName(profile: CurrentProfile): string {
  return profile.fullName.trim() || formatPhone(profile.phone) || "Пользователь";
}

export function formatJoinedDate(iso: string | null): string | null {
  if (!iso) {
    return null;
  }

  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return date.toLocaleDateString("ru-RU", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

export function validateProfileDraft(draft: {
  fullName: string;
  phone: string;
}): { fullName?: string; phone?: string } {
  const errors: { fullName?: string; phone?: string } = {};
  const fullName = draft.fullName.trim();

  if (!fullName) {
    errors.fullName = "Укажите фамилию и имя";
  }

  const phone = draft.phone.trim();
  if (phone && !normalizeRuPhoneE164(phone)) {
    errors.phone = "Введите номер в формате +7 900 000 00 00";
  }

  return errors;
}



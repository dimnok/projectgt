import type { CompanyInvitation } from "@/features/company/types/company.types";

type InvitationRow = {
  id: string;
  code: string | null;
  expires_at: string | null;
  used_at: string | null;
  revoked_at: string | null;
};

export const INVITATION_SELECT = "id, code, expires_at, used_at, revoked_at";

export function mapInvitationRow(row: InvitationRow): CompanyInvitation {
  return {
    id: row.id,
    code: (row.code ?? "").trim(),
    expiresAt: row.expires_at ?? "",
    usedAt: row.used_at,
    revokedAt: row.revoked_at,
  };
}

export type InvitationStatus = "active" | "used" | "revoked" | "expired";

export function invitationStatus(
  invitation: CompanyInvitation
): InvitationStatus {
  if (invitation.revokedAt) {
    return "revoked";
  }
  if (invitation.usedAt) {
    return "used";
  }
  const expires = new Date(invitation.expiresAt).getTime();
  if (!Number.isNaN(expires) && expires <= Date.now()) {
    return "expired";
  }
  return "active";
}

export const invitationStatusLabels: Record<InvitationStatus, string> = {
  active: "Активен",
  used: "Использован",
  revoked: "Отозван",
  expired: "Истёк",
};

export function formatInvitationDate(value: string): string {
  if (!value) {
    return "—";
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "—";
  }
  return date.toLocaleDateString("ru-RU");
}

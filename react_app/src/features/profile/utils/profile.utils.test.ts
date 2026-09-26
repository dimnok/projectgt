import { describe, expect, it } from "vitest";

import type { ProfileCompanyMembership } from "@/features/profile/types/profile.types";
import { canViewProductionNorm } from "@/features/profile/utils/profile.utils";

function membership(
  overrides: Partial<ProfileCompanyMembership> = {}
): ProfileCompanyMembership {
  return {
    companyId: "company",
    companyName: "ООО «Тест»",
    systemRole: null,
    roleId: null,
    roleName: "Прораб",
    isActive: true,
    isOwner: false,
    minOutputPerPersonHour: null,
    ...overrides,
  };
}

describe("canViewProductionNorm", () => {
  it("виден владельцу компании", () => {
    expect(canViewProductionNorm(membership({ isOwner: true }), false)).toBe(
      true
    );
  });

  it("виден администратору компании (system_role = admin)", () => {
    expect(
      canViewProductionNorm(membership({ systemRole: "admin" }), false)
    ).toBe(true);
  });

  it("виден супер-админу", () => {
    expect(canViewProductionNorm(membership(), true)).toBe(true);
  });

  it("скрыт от обычного участника", () => {
    expect(canViewProductionNorm(membership(), false)).toBe(false);
  });

  it("скрыт, если активной компании нет", () => {
    expect(canViewProductionNorm(null, true)).toBe(false);
  });
});

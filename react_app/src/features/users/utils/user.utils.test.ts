import { describe, expect, it } from "vitest";

import type { CompanyUser } from "@/features/users/types/user.types";
import { sortCompanyUsers } from "@/features/users/utils/user.utils";

function user(overrides: Partial<CompanyUser> = {}): CompanyUser {
  return {
    id: "id",
    fullName: "Иванов Иван",
    shortName: null,
    photoUrl: null,
    email: "",
    phone: "",
    roleId: null,
    roleName: "Прораб",
    isActive: true,
    isOwner: false,
    employeeId: null,
    objectIds: [],
    preferWebApp: false,
    linkedEmployee: null,
    ...overrides,
  };
}

function names(users: CompanyUser[]): string[] {
  return users.map((item) => item.fullName);
}

describe("sortCompanyUsers", () => {
  const users = [
    user({ id: "1", fullName: "Яковлев Пётр", objectIds: ["a"] }),
    user({ id: "2", fullName: "Абрамов Илья", objectIds: ["a", "b", "c"] }),
    user({ id: "3", fullName: "Борисов Олег", objectIds: [] }),
  ];

  it("без сортировки отдаёт список как есть", () => {
    expect(sortCompanyUsers(users, null)).toBe(users);
  });

  it("сортирует по имени", () => {
    expect(
      names(sortCompanyUsers(users, { key: "name", direction: "asc" }))
    ).toEqual(["Абрамов Илья", "Борисов Олег", "Яковлев Пётр"]);
  });

  it("сортирует по количеству объектов", () => {
    expect(
      names(sortCompanyUsers(users, { key: "objects", direction: "desc" }))
    ).toEqual(["Абрамов Илья", "Яковлев Пётр", "Борисов Олег"]);
  });

  it("равные значения идут по алфавиту", () => {
    const same = [
      user({ id: "1", fullName: "Яковлев Пётр", isActive: false }),
      user({ id: "2", fullName: "Абрамов Илья", isActive: false }),
    ];

    expect(
      names(sortCompanyUsers(same, { key: "status", direction: "desc" }))
    ).toEqual(["Абрамов Илья", "Яковлев Пётр"]);
  });
});

import { describe, expect, it } from "vitest";

import type { AppModule } from "@/features/roles/types/role.types";
import {
  HIDDEN_MATRIX_MODULE_CODES,
  matrixModules,
  setPermissionValue,
} from "@/features/roles/utils/role.utils";

function appModule(code: string, name = code): AppModule {
  return { id: `id-${code}`, code, name, sortOrder: 0 };
}

describe("matrixModules", () => {
  it("скрывает модуль ТМЦ, пока его реализация правится", () => {
    const modules = [appModule("works"), appModule("tmc"), appModule("roles")];

    expect(matrixModules(modules).map((item) => item.code)).toEqual([
      "works",
      "roles",
    ]);
    expect(HIDDEN_MATRIX_MODULE_CODES).toContain("tmc");
  });

  it("не меняет порядок остальных модулей", () => {
    const modules = [appModule("tmc"), appModule("chat"), appModule("company")];

    expect(matrixModules(modules).map((item) => item.code)).toEqual([
      "chat",
      "company",
    ]);
  });

  it("сохраняет права скрытого модуля при правке других", () => {
    const saved = { tmc: { read: true, issue: true }, works: { read: true } };
    const draft = setPermissionValue(saved, "works", "create", true);

    expect(draft.tmc).toEqual({ read: true, issue: true });
  });
});

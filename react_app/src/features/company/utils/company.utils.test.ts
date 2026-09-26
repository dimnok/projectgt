import { describe, expect, it } from "vitest";

import { emptyCompanyDraft } from "@/features/company/types/company.types";
import {
  companyDraftErrors,
  companyFieldBlurError,
  isCompanyFieldKey,
} from "@/features/company/utils/company.utils";

describe("companyFieldBlurError", () => {
  it("проверяет формат заполненного поля", () => {
    expect(companyFieldBlurError("inn", "7712345678")).toBe("");
    expect(companyFieldBlurError("inn", "123")).toBe("ИНН: нужно 10 или 12 цифр");
    expect(companyFieldBlurError("kpp", "123456789")).toBe("");
    expect(companyFieldBlurError("kpp", "12345")).toBe("КПП: нужно 9 цифр");
  });

  it("не ругается на пустое значение — обязательность проверяет сохранение", () => {
    expect(companyFieldBlurError("inn", "")).toBe("");
    expect(companyFieldBlurError("nameFull", "   ")).toBe("");
  });

  it("принимает заполненное наименование", () => {
    expect(companyFieldBlurError("nameFull", "ООО «ГТ»")).toBe("");
    expect(companyFieldBlurError("nameShort", "ГТ")).toBe("");
  });
});

describe("isCompanyFieldKey", () => {
  it("отличает проверяемые поля от остальных", () => {
    expect(isCompanyFieldKey("inn")).toBe(true);
    expect(isCompanyFieldKey("okpo")).toBe(true);
    expect(isCompanyFieldKey("phone")).toBe(false);
    expect(isCompanyFieldKey("vatRate")).toBe(false);
  });
});

describe("companyDraftErrors", () => {
  it("требует наименования и проверяет переданные цифровые поля", () => {
    const draft = { ...emptyCompanyDraft, inn: "123" };
    const errors = companyDraftErrors(draft, ["inn"]);

    expect(errors.nameFull).toBe("Введите полное наименование");
    expect(errors.nameShort).toBe("Введите краткое наименование");
    expect(errors.inn).toBe("ИНН: нужно 10 или 12 цифр");
  });

  it("не проверяет цифровые поля, которые пользователь не заполнял", () => {
    const draft = {
      ...emptyCompanyDraft,
      nameFull: "ООО «ГТ»",
      nameShort: "ГТ",
      kpp: "12345",
    };

    expect(companyDraftErrors(draft, [])).toEqual({});
  });

  it("без списка полей проверяет все цифровые поля — для новой организации", () => {
    const draft = {
      ...emptyCompanyDraft,
      nameFull: "ООО «ГТ»",
      nameShort: "ГТ",
      kpp: "12345",
    };

    expect(companyDraftErrors(draft)).toEqual({ kpp: "КПП: нужно 9 цифр" });
  });

  it("принимает корректные реквизиты", () => {
    const draft = {
      ...emptyCompanyDraft,
      nameFull: "ООО «ГТ»",
      nameShort: "ГТ",
      inn: "7712345678",
      kpp: "771234567",
      ogrn: "1234567890123",
      okpo: "12345678",
    };

    expect(companyDraftErrors(draft)).toEqual({});
  });
});

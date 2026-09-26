import { describe, expect, it } from "vitest";

import {
  canModifyWorkItems,
  resolveWorkPhotoUrls,
  workPhotoLegacyMode,
  workPhotoStoragePath,
} from "@/features/works/utils/work.utils";

const baseParams = {
  canUpdate: true,
  userId: "user-1",
  openedBy: "user-1",
  status: "open" as const,
  isSuperAdmin: false,
  isCompanyOwner: false,
};

describe("canModifyWorkItems", () => {
  it("автор правит свою открытую смену", () => {
    expect(canModifyWorkItems(baseParams)).toBe(true);
  });

  it("без права на правку работ не правит никто", () => {
    expect(canModifyWorkItems({ ...baseParams, canUpdate: false })).toBe(false);
  });

  it("автор не правит закрытую смену", () => {
    expect(canModifyWorkItems({ ...baseParams, status: "closed" })).toBe(false);
  });

  it("чужую открытую смену обычный пользователь не правит", () => {
    expect(canModifyWorkItems({ ...baseParams, openedBy: "user-2" })).toBe(false);
  });

  it("владелец компании правит чужую открытую смену, но не закрытую", () => {
    expect(
      canModifyWorkItems({
        ...baseParams,
        openedBy: "user-2",
        isCompanyOwner: true,
      })
    ).toBe(true);
    expect(
      canModifyWorkItems({
        ...baseParams,
        openedBy: "user-2",
        status: "closed",
        isCompanyOwner: true,
      })
    ).toBe(false);
  });

  it("супер-админ правит смену любого статуса", () => {
    expect(
      canModifyWorkItems({
        ...baseParams,
        openedBy: "user-2",
        status: "closed",
        isSuperAdmin: true,
      })
    ).toBe(true);
  });
});

describe("resolveWorkPhotoUrls", () => {
  it("берёт список, если он заполнен", () => {
    expect(resolveWorkPhotoUrls(["a", "b"], "legacy")).toEqual(["a", "b"]);
  });

  it("подставляет одиночное фото смены, открытой в мобильном приложении", () => {
    expect(resolveWorkPhotoUrls([], "legacy")).toEqual(["legacy"]);
    expect(resolveWorkPhotoUrls(null, "legacy")).toEqual(["legacy"]);
    expect(resolveWorkPhotoUrls(undefined, "legacy")).toEqual(["legacy"]);
  });

  it("игнорирует пустые значения", () => {
    expect(resolveWorkPhotoUrls(["", "  "], "")).toEqual([]);
    expect(resolveWorkPhotoUrls([], null)).toEqual([]);
    expect(resolveWorkPhotoUrls(null, undefined)).toEqual([]);
  });
});

describe("workPhotoLegacyMode", () => {
  it("без фото одиночное поле очищается", () => {
    expect(workPhotoLegacyMode([])).toBe("none");
  });

  it("одно фото уходит как есть", () => {
    expect(workPhotoLegacyMode(["a"])).toBe("single");
  });

  it("два и больше — коллаж для мобильного приложения", () => {
    expect(workPhotoLegacyMode(["a", "b"])).toBe("collage");
    expect(workPhotoLegacyMode(["a", "b", "c", "d"])).toBe("collage");
  });
});

describe("workPhotoStoragePath", () => {
  it("достаёт путь файла из публичной ссылки bucket works", () => {
    expect(
      workPhotoStoragePath(
        "https://demo.supabase.co/storage/v1/object/public/works/object-1/01-09-2026/2026-09-01_08-15-00_evening.jpg"
      )
    ).toBe("object-1/01-09-2026/2026-09-01_08-15-00_evening.jpg");
  });

  it("раскодирует русские буквы в пути", () => {
    expect(
      workPhotoStoragePath(
        "https://demo.supabase.co/storage/v1/object/public/works/object-1/01-09-2026/%D0%9E%D0%B1%D1%8A%D0%B5%D0%BA%D1%82.jpg"
      )
    ).toBe("object-1/01-09-2026/Объект.jpg");
  });

  it("не трогает файлы чужого bucket", () => {
    expect(
      workPhotoStoragePath(
        "https://demo.supabase.co/storage/v1/object/public/avatars/user-1/avatar.jpg"
      )
    ).toBeNull();
  });

  it("возвращает null для пустой ссылки, мусора и ссылки без public", () => {
    expect(workPhotoStoragePath(null)).toBeNull();
    expect(workPhotoStoragePath(undefined)).toBeNull();
    expect(workPhotoStoragePath("   ")).toBeNull();
    expect(workPhotoStoragePath("не ссылка")).toBeNull();
    expect(
      workPhotoStoragePath(
        "https://demo.supabase.co/storage/v1/object/works/object-1/photo.jpg"
      )
    ).toBeNull();
  });
});

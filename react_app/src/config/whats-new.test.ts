import { describe, expect, it } from "vitest";

import {
  formatWhatsNewDate,
  unreadWhatsNewEntries,
  type WhatsNewEntry,
} from "@/config/whats-new";

const entries: WhatsNewEntry[] = [
  {
    id: "works-photos-2026-09-20",
    date: "2026-09-20",
    title: "Фото смены — до 4 снимков",
    items: ["Пункт"],
    module: "works",
  },
  {
    id: "common-2026-09-01",
    date: "2026-09-01",
    title: "Общая новость",
    items: ["Пункт"],
  },
];

const allModules = () => true;
const noModules = () => false;

describe("formatWhatsNewDate", () => {
  it("показывает дату в привычном виде", () => {
    expect(formatWhatsNewDate("2026-09-20")).toBe("20.09.2026");
  });

  it("не ломается на неожиданном значении", () => {
    expect(formatWhatsNewDate("без даты")).toBe("без даты");
  });
});

describe("unreadWhatsNewEntries", () => {
  it("показывает все непрочитанные новости, свежие сверху", () => {
    expect(
      unreadWhatsNewEntries(entries, [], allModules).map((entry) => entry.id)
    ).toEqual(["works-photos-2026-09-20", "common-2026-09-01"]);
  });

  it("пропускает прочитанные", () => {
    expect(
      unreadWhatsNewEntries(
        entries,
        ["works-photos-2026-09-20"],
        allModules
      ).map((entry) => entry.id)
    ).toEqual(["common-2026-09-01"]);
  });

  it("не показывает новость модуля, к которому нет доступа", () => {
    expect(
      unreadWhatsNewEntries(entries, [], noModules).map((entry) => entry.id)
    ).toEqual(["common-2026-09-01"]);
  });

  it("когда всё прочитано — показывать нечего", () => {
    expect(
      unreadWhatsNewEntries(
        entries,
        ["works-photos-2026-09-20", "common-2026-09-01"],
        allModules
      )
    ).toEqual([]);
  });
});

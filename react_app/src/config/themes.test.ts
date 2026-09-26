import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import { findThemeOption, themeIds, themeOptions } from "@/config/themes";

const globalsCss = readFileSync(
  fileURLToPath(new URL("../styles/globals.css", import.meta.url)),
  "utf8"
);

/** Класс темы в стилях: светлая живёт в `:root`, остальные — в своём блоке. */
function styleBlockFor(themeId: string): string | null {
  const selector = themeId === "light" ? ":root" : `.${themeId}`;
  const match = globalsCss.match(
    new RegExp(`(^|\\n)${selector.replace(".", "\\.")} \\{([\\s\\S]*?)\\n\\}`)
  );
  return match ? match[2] : null;
}

describe("themeOptions", () => {
  it("содержит семь тем с уникальными кодами", () => {
    expect(themeOptions).toHaveLength(7);
    expect(new Set(themeIds).size).toBe(themeIds.length);
  });

  it("у каждой темы есть название, пояснение, образец и цвет строки браузера", () => {
    for (const theme of themeOptions) {
      expect(theme.label.length).toBeGreaterThan(0);
      expect(theme.description.length).toBeGreaterThan(0);
      expect(theme.swatch).toHaveLength(3);
      expect(theme.statusBarColor).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});

describe("стили тем", () => {
  it("на каждую тему из справочника есть блок цветов в globals.css", () => {
    for (const theme of themeOptions) {
      const block = styleBlockFor(theme.id);
      expect(block, `нет блока для темы «${theme.label}»`).not.toBeNull();
      expect(block).toContain("--background:");
      expect(block).toContain("--sidebar-foreground:");
    }
  });

  it("тёмные темы включают правило dark:, светлые — нет", () => {
    const darkVariant = globalsCss.match(/@custom-variant dark \(&:is\(([^)]*)\)\)/);
    expect(darkVariant).not.toBeNull();

    const darkSelectors = darkVariant![1];
    for (const theme of themeOptions.filter((item) => item.isDark)) {
      expect(darkSelectors, `тема «${theme.label}» не в правиле dark:`).toContain(
        `.${theme.id} *`
      );
    }
    for (const theme of themeOptions.filter((item) => !item.isDark)) {
      expect(darkSelectors).not.toContain(`.${theme.id} *`);
    }
  });
});

describe("findThemeOption", () => {
  it("находит тему по коду и не падает на чужих значениях", () => {
    expect(findThemeOption("nord")?.label).toBe("Северная");
    expect(findThemeOption("system")).toBeUndefined();
    expect(findThemeOption(undefined)).toBeUndefined();
  });
});

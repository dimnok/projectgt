/**
 * Справочник тем оформления веб-приложения.
 *
 * Единственное место, где перечислены темы: отсюда их берут переключатель в
 * профиле, кнопка темы в левом меню и подстановка цвета строки браузера.
 * Цвета самих тем живут в `src/styles/globals.css` (блоки `.dark`, `.brand`,
 * `.sand`, `.pastel`, `.nord`, `.graphite`).
 *
 * Выбор темы хранится на устройстве (`next-themes`, localStorage), в аккаунт
 * не пишется. Flutter-приложение этими темами не управляется.
 */

export type ThemeId =
  | "light"
  | "dark"
  | "brand"
  | "sand"
  | "pastel"
  | "nord"
  | "graphite";

export type ThemeOption = {
  id: ThemeId;
  /** Название в списке тем. */
  label: string;
  /** Короткое пояснение: чем тема отличается. */
  description: string;
  /** Тёмная ли тема — нужно для предпросмотра в списке. */
  isDark: boolean;
  /** Фон темы: он же цвет строки браузера на телефоне. */
  statusBarColor: string;
  /** Образец темы в списке: фон, акцент, текст. */
  swatch: [string, string, string];
};

export const themeOptions: ThemeOption[] = [
  {
    id: "light",
    label: "Светлая",
    description: "Белая, как раньше",
    isDark: false,
    statusBarColor: "#ffffff",
    swatch: ["#ffffff", "#343434", "#8a8a8a"],
  },
  {
    id: "dark",
    label: "Тёмная",
    description: "Чёрно-серая, для работы вечером",
    isDark: true,
    statusBarColor: "#0a0a0a",
    swatch: ["#252525", "#fbfbfb", "#a3a3a3"],
  },
  {
    id: "brand",
    label: "Фирменная",
    description: "Синяя, в цветах компании",
    isDark: false,
    statusBarColor: "#E6E9EE",
    swatch: ["#E6E9EE", "#0A5EDC", "#1F2833"],
  },
  {
    id: "sand",
    label: "Песочная",
    description: "Тёплая, мягкий бежевый фон",
    isDark: false,
    statusBarColor: "#F7F1E7",
    swatch: ["#F7F1E7", "#9A5B2A", "#3A2F26"],
  },
  {
    id: "pastel",
    label: "Пастельная",
    description: "Светлая с лавандой и мятой",
    isDark: false,
    statusBarColor: "#F6F4FB",
    swatch: ["#F6F4FB", "#6C58C4", "#DFF0EA"],
  },
  {
    id: "nord",
    label: "Северная",
    description: "Тёмная, холодные синие тона",
    isDark: true,
    statusBarColor: "#2E3440",
    swatch: ["#2E3440", "#88C0D0", "#ECEFF4"],
  },
  {
    id: "graphite",
    label: "Графит",
    description: "Тёмная, спокойный серый",
    isDark: true,
    statusBarColor: "#22252A",
    swatch: ["#22252A", "#C8CDD4", "#ECEEF1"],
  },
];

export const themeIds: ThemeId[] = themeOptions.map((theme) => theme.id);

/** Тема по её коду. Нужна там, где приходит произвольная строка из хранилища. */
export function findThemeOption(id: string | undefined): ThemeOption | undefined {
  return themeOptions.find((theme) => theme.id === id);
}

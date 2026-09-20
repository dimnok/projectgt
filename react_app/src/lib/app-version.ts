export type AppVersionInfo = {
  version: string;
  /** Код сборки: отпечаток содержимого сайта или коммит репозитория сайта. */
  buildId: string;
  /** Дата и время сборки в формате ISO. Пустая строка у старых сборок. */
  builtAt: string;
};

/** Данные сборки, вшитые в текущий клиентский пакет. */
export function getClientAppVersion(): AppVersionInfo {
  return {
    version: process.env.NEXT_PUBLIC_APP_VERSION ?? "0.1.0",
    buildId: process.env.NEXT_PUBLIC_BUILD_ID ?? "",
    builtAt: process.env.NEXT_PUBLIC_BUILD_TIME ?? "",
  };
}

/** Номер версии для показа: «v0.1.0». */
export function formatAppVersionLabel(version: string): string {
  return version.startsWith("v") ? version : `v${version}`;
}

/**
 * Короткий код сборки для поддержки: первые 7 символов, если это хеш.
 * Для остальных значений возвращает строку как есть.
 */
export function formatAppBuildLabel(buildId: string): string {
  const id = buildId.trim();
  if (!id) {
    return "";
  }
  if (/^[a-f0-9]{7,40}$/i.test(id)) {
    return id.slice(0, 7);
  }
  return id;
}

/**
 * Дата сборки для показа человеку: «17.09.2026, 09:10».
 * Если даты нет (старая сборка) или она некорректна — возвращает null.
 */
export function formatAppBuildTime(builtAt: string | undefined): string | null {
  const raw = builtAt?.trim();
  if (!raw) {
    return null;
  }

  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) {
    return null;
  }

  const day = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${day}.${month}.${date.getFullYear()}, ${hours}:${minutes}`;
}

/**
 * Короткая подпись сборки: «6dff91c от 17.09.2026, 21:10».
 * Если кода или даты нет — возвращает то, что есть, иначе null.
 */
export function formatAppBuildSummary(info: AppVersionInfo): string | null {
  const code = formatAppBuildLabel(info.buildId);
  const time = formatAppBuildTime(info.builtAt);
  if (code && time) {
    return `${code} от ${time}`;
  }
  return code || (time ? `от ${time}` : null);
}

/**
 * Есть ли на сервере более новая сборка, чем та, что открыта в браузере.
 * Сравниваем именно код сборки: номер версии в проекте не меняется.
 */
export function isAppUpdateAvailable(
  current: AppVersionInfo,
  remote: AppVersionInfo | undefined
): boolean {
  const currentId = current.buildId.trim();
  const remoteId = remote?.buildId?.trim() ?? "";
  if (!currentId || !remoteId) {
    return false;
  }
  return remoteId !== currentId;
}

/**
 * Обновляет приложение до новой сборки.
 *
 * Сервис-воркер сайта ничего не кэширует — он только проксирует запросы,
 * а файлы сборки имеют уникальные имена. Поэтому перезагрузка сразу отдаёт
 * новую версию, и ждать обновления воркера не нужно: это лишь добавляло
 * задержку без пользы.
 */
export function applyAppUpdate(): void {
  window.location.reload();
}

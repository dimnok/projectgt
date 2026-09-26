/**
 * «Что нового» — короткие новости о доработках приложения.
 *
 * Как добавить новость:
 * 1. Добавьте запись в начало списка `WHATS_NEW_ENTRIES` (свежие — сверху).
 * 2. `id` — постоянный, вида `модуль-тема-дата`. Меняйте его только для новой
 *    новости: по нему браузер понимает, что запись уже прочитана.
 * 3. `module` — право «просмотр» модуля: новость увидят только те, у кого есть
 *    доступ к разделу. Без `module` новость показывается всем.
 *
 * Отметка «прочитано» хранится в браузере (как у подсказок по сменам): на
 * другом устройстве новость покажется ещё раз.
 */

export type WhatsNewEntry = {
  id: string;
  /** Дата доработки, `YYYY-MM-DD`. */
  date: string;
  title: string;
  items: string[];
  /** Модуль доступа: новость видят только те, у кого есть право на просмотр. */
  module?: string;
};

export const WHATS_NEW_STORAGE_KEY = "projectgt.whats-new.v1";

/** Событие «открыть окно Что нового»: пункты меню и само окно не связаны напрямую. */
export const WHATS_NEW_OPEN_EVENT = "whats-new-open";

export const WHATS_NEW_ENTRIES: WhatsNewEntry[] = [
  {
    id: "purchase-requests-invoice-recognition-2026-09-20",
    date: "2026-09-20",
    title: "Заявки: счёт можно распознать",
    module: "purchase_requests",
    items: [
      "В окне добавления счёта есть кнопка «Распознать счёт» — она появляется после выбора файла.",
      "Заполняет поставщика (по ИНН), номер, дату, сумму и позиции счёта — остаётся проверить и поправить.",
      "Подходит PDF с текстом: скан или фото не распознаётся.",
      "Само ничего не сохраняется: счёт добавится только после вашего подтверждения.",
    ],
  },
  {
    id: "purchase-requests-push-2026-09-20",
    date: "2026-09-20",
    title: "Заявки: уведомления о ходе заявки",
    module: "purchase_requests",
    items: [
      "Приходят участникам текущего этапа и инициатору заявки: о согласовании, счетах, оплате и получении.",
      "Приходят на телефон и на компьютер; по нажатию открывается карточка заявки.",
      "Чтобы их получать, разрешите уведомления, когда браузер спросит после входа. Если отказали — включите вручную в настройках браузера для сайта (значок замка рядом с адресом).",
      "На телефоне — в установленном приложении (иконка на экране «Домой»). О своём действии уведомление не приходит.",
    ],
  },
  {
    id: "purchase-requests-invoice-preview-2026-09-20",
    date: "2026-09-20",
    title: "Заявки: счёт открывается прямо в приложении",
    module: "purchase_requests",
    items: [
      "PDF листается в окне, картинка показывается целиком — файл не покидает приложение.",
      "Рядом кнопки «Скачать» и «Закрыть», окно можно развернуть на весь экран.",
    ],
  },
  {
    id: "works-photos-2026-09-20",
    date: "2026-09-20",
    title: "Фото смены — теперь до 4 снимков",
    module: "works",
    items: [
      "Можно загрузить до 4 фото на начало смены и до 4 на конец.",
      "Любое фото можно заменить или удалить, пока смена открыта.",
      "На телефоне при добавлении — «Сделать фото» или «Выбрать из галереи».",
    ],
  },
];

/** Дата новости для показа: «20.09.2026». */
export function formatWhatsNewDate(date: string): string {
  const [year, month, day] = date.split("-");
  if (!year || !month || !day) {
    return date;
  }
  return `${day}.${month}.${year}`;
}

/**
 * Новости, которые пользователь ещё не читал и может увидеть:
 * без доступа к модулю новость не показываем.
 */
export function unreadWhatsNewEntries(
  entries: WhatsNewEntry[],
  seenIds: string[],
  canReadModule: (module: string) => boolean
): WhatsNewEntry[] {
  return entries.filter(
    (entry) =>
      !seenIds.includes(entry.id) &&
      (!entry.module || canReadModule(entry.module))
  );
}

/** Прочитанные новости, сохранённые в браузере. */
export function readSeenWhatsNewIds(): string[] {
  try {
    const raw = window.localStorage.getItem(WHATS_NEW_STORAGE_KEY);
    if (!raw) {
      return [];
    }
    const parsed: unknown = JSON.parse(raw);
    return Array.isArray(parsed)
      ? parsed.filter((id): id is string => typeof id === "string")
      : [];
  } catch {
    // Приватный режим или испорченное значение — считаем, что ничего не читали.
    return [];
  }
}

/** Отмечает новости прочитанными: больше это окно не появится. */
export function markWhatsNewSeen(ids: string[]): void {
  try {
    const seen = new Set([...readSeenWhatsNewIds(), ...ids]);
    window.localStorage.setItem(WHATS_NEW_STORAGE_KEY, JSON.stringify([...seen]));
  } catch {
    /* ignore private mode */
  }
}

/** Открыть окно «Что нового» из меню. */
export function openWhatsNew(): void {
  window.dispatchEvent(new Event(WHATS_NEW_OPEN_EVENT));
}

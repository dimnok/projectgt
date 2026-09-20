/** «14:32» — время сообщения в ленте. */
export function formatChatTime(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "";
  }
  return `${String(date.getHours()).padStart(2, "0")}:${String(
    date.getMinutes()
  ).padStart(2, "0")}`;
}

/**
 * Метка времени в списке диалогов: сегодня — часы, вчера — «вчера»,
 * дальше — дата. Так список читается без лишних цифр.
 */
export function formatChatStamp(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "";
  }

  const today = new Date();
  const dayStart = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate()
  ).getTime();
  const todayStart = new Date(
    today.getFullYear(),
    today.getMonth(),
    today.getDate()
  ).getTime();
  const dayMs = 24 * 60 * 60 * 1000;

  if (dayStart === todayStart) {
    return formatChatTime(value);
  }
  if (dayStart === todayStart - dayMs) {
    return "вчера";
  }

  return `${String(date.getDate()).padStart(2, "0")}.${String(
    date.getMonth() + 1
  ).padStart(2, "0")}.${date.getFullYear()}`;
}

/** Название диалога в списке: своё имя или подпись по умолчанию. */
export function chatThreadTitle(title: string | null): string {
  return title?.trim() || "Новый диалог";
}

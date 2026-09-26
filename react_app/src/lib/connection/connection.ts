/**
 * Чистая логика определения состояния соединения.
 *
 * Вынесена из React-хука отдельным модулем, чтобы её можно было
 * покрыть модульными тестами без браузера и таймеров.
 */

/**
 * Решает, считать ли соединение рабочим.
 *
 * Правила:
 * - нет сети у браузера — сразу офлайн, без обращения к серверу;
 * - сеть есть, но сервер не ответил — офлайн;
 * - сервер ещё не проверялся (`null`) — считаем онлайн, чтобы не мигать
 *   офлайном до первой проверки.
 *
 * @param navigatorOnline Значение `navigator.onLine` в момент проверки.
 * @param backendReachable Результат проверки backend/Supabase:
 *   `true` — ответил, `false` — недоступен, `null` — ещё не проверялся.
 * @returns `true`, когда интернет есть и сервер не подтвердил обратное.
 */
export function isConnectionOnline(
  navigatorOnline: boolean,
  backendReachable: boolean | null
): boolean {
  if (!navigatorOnline) {
    return false;
  }

  return backendReachable !== false;
}

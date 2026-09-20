"use client";

import { useEffect, useState } from "react";

/**
 * Возвращает значение после паузы `delayMs` без изменений.
 *
 * Нужен для поиска: запрос уходит на сервер не на каждую букву, а когда
 * пользователь перестал печатать. Пустая строка применяется сразу — иначе
 * очистка поиска срабатывала бы с задержкой.
 */
export function useDebouncedValue(value: string, delayMs: number): string {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    // Пустую строку применяем без задержки: очистка поиска не должна ждать.
    const delay = value.trim() === "" ? 0 : delayMs;

    const timer = window.setTimeout(() => {
      setDebounced(value);
    }, delay);

    return () => {
      window.clearTimeout(timer);
    };
  }, [value, delayMs]);

  return debounced;
}

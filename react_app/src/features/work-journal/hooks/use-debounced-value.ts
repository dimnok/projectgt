"use client";

import { useEffect, useState } from "react";

/**
 * Returns `value` after it has stayed unchanged for `delayMs`.
 * Empty strings update immediately so clearing search does not lag.
 */
export function useDebouncedValue(value: string, delayMs: number): string {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    if (value.trim() === "") {
      setDebounced(value);
      return;
    }

    const timer = window.setTimeout(() => {
      setDebounced(value);
    }, delayMs);

    return () => {
      window.clearTimeout(timer);
    };
  }, [value, delayMs]);

  return debounced;
}

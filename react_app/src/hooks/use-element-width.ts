"use client";

import { useEffect, useRef, useState } from "react";

/**
 * Ширина элемента в пикселях.
 *
 * Нужна графикам на SVG: если растягивать картинку по ширине, вместе с ней
 * растянулись бы линии и подписи. Поэтому координаты задаются в тех же
 * пикселях, что и размер на экране, а ширину сообщает наблюдатель.
 *
 * До первого замера ширина равна нулю — график рисуется по запасной.
 */
export function useElementWidth<T extends HTMLElement>(fallback = 0) {
  const ref = useRef<T | null>(null);
  const [width, setWidth] = useState(fallback);

  useEffect(() => {
    const element = ref.current;
    if (!element) {
      return;
    }

    // Наблюдатель сообщает текущий размер сразу после подписки — отдельный
    // замер в теле эффекта не нужен.
    const observer = new ResizeObserver((entries) => {
      setWidth(entries[0]?.contentRect.width ?? 0);
    });
    observer.observe(element);

    return () => {
      observer.disconnect();
    };
  }, []);

  return { ref, width };
}

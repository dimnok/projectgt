"use client";

import { useEffect } from "react";

/**
 * Locks screen orientation to portrait on platforms that support the Screen Orientation API
 * (e.g. Android PWA / Chrome), and restores it when unmounted.
 */
export function useLockPortrait() {
  useEffect(() => {
    if (typeof window === "undefined" || !("screen" in window)) {
      return;
    }

    const orientation = window.screen?.orientation as
      | (ScreenOrientation & {
          lock?: (
            orientation:
              | "portrait"
              | "landscape"
              | "natural"
              | "any"
              | "portrait-primary"
              | "portrait-secondary"
              | "landscape-primary"
              | "landscape-secondary"
          ) => Promise<void>;
        })
      | undefined;

    if (orientation && typeof orientation.lock === "function") {
      orientation.lock("portrait").catch(() => {
        // Ignored on unsupported browsers or if user gesture is required
      });
    }

    return () => {
      try {
        if (orientation && typeof orientation.unlock === "function") {
          orientation.unlock();
        }
      } catch {
        // Ignored
      }
    };
  }, []);
}

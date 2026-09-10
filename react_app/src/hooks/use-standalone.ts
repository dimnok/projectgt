import { useSyncExternalStore } from "react";

import { isStandaloneDisplay } from "@/lib/pwa/display-mode";

const STANDALONE_QUERY = "(display-mode: standalone)";

function subscribe(onChange: () => void) {
  const mediaQuery = window.matchMedia(STANDALONE_QUERY);
  mediaQuery.addEventListener("change", onChange);
  return () => mediaQuery.removeEventListener("change", onChange);
}

function getSnapshot() {
  return isStandaloneDisplay(window);
}

function getServerSnapshot() {
  return false;
}

export function useStandalone() {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}

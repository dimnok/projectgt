import { useSyncExternalStore } from "react";

const MOBILE_BREAKPOINT = 768;
const MOBILE_QUERY = `(max-width: ${MOBILE_BREAKPOINT - 1}px), (orientation: landscape) and (max-height: 500px) and (pointer: coarse)`;
const LANDSCAPE_MOBILE_QUERY = `(orientation: landscape) and (max-height: 500px) and (pointer: coarse)`;

function subscribe(onChange: () => void) {
  const mediaQuery = window.matchMedia(MOBILE_QUERY);
  mediaQuery.addEventListener("change", onChange);
  return () => mediaQuery.removeEventListener("change", onChange);
}

function getSnapshot() {
  return window.matchMedia(MOBILE_QUERY).matches;
}

function subscribeLandscape(onChange: () => void) {
  const mediaQuery = window.matchMedia(LANDSCAPE_MOBILE_QUERY);
  mediaQuery.addEventListener("change", onChange);
  return () => mediaQuery.removeEventListener("change", onChange);
}

function getLandscapeSnapshot() {
  return window.matchMedia(LANDSCAPE_MOBILE_QUERY).matches;
}

function getServerSnapshot() {
  return false;
}

export function useIsMobile() {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}

export function useIsLandscapeMobile() {
  return useSyncExternalStore(subscribeLandscape, getLandscapeSnapshot, getServerSnapshot);
}

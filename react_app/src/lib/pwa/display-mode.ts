const STANDALONE_QUERIES = [
  "(display-mode: standalone)",
  "(display-mode: fullscreen)",
  "(display-mode: minimal-ui)",
  "(display-mode: window-controls-overlay)",
] as const;

function isIosStandalone(navigatorLike: Navigator) {
  return (
    "standalone" in navigatorLike &&
    (navigatorLike as Navigator & { standalone?: boolean }).standalone === true
  );
}

/**
 * True when the page runs as an installed app, not as a browser tab.
 * Covers Chromium display-mode and iOS Safari `navigator.standalone`.
 */
export function isStandaloneDisplay(
  windowLike: Pick<Window, "matchMedia" | "navigator"> = window
) {
  if (isIosStandalone(windowLike.navigator)) {
    return true;
  }

  return STANDALONE_QUERIES.some(
    (query) => windowLike.matchMedia(query).matches
  );
}

export function isIosDevice(navigatorLike: Navigator = navigator) {
  const userAgent = navigatorLike.userAgent;
  if (/iPad|iPhone|iPod/i.test(userAgent)) {
    return true;
  }

  return navigatorLike.platform === "MacIntel" && navigatorLike.maxTouchPoints > 1;
}

export const WORKS_DESKTOP_TOUR_STORAGE_KEY =
  "projectgt.works-desktop-tour.v1";
export const WORKS_DESKTOP_TOUR_RESTART_KEY =
  "projectgt.works-desktop-tour.restart";
export const WORKS_DESKTOP_TOUR_START_EVENT = "works-desktop-tour-start";

export function markWorksDesktopTourSeen() {
  try {
    window.localStorage.setItem(WORKS_DESKTOP_TOUR_STORAGE_KEY, "1");
  } catch {
    /* ignore private mode */
  }
}

export function hasSeenWorksDesktopTour() {
  try {
    return window.localStorage.getItem(WORKS_DESKTOP_TOUR_STORAGE_KEY) === "1";
  } catch {
    return true;
  }
}

export function requestWorksDesktopTour(options?: { persistRestart?: boolean }) {
  if (options?.persistRestart) {
    try {
      window.sessionStorage.setItem(WORKS_DESKTOP_TOUR_RESTART_KEY, "1");
    } catch {
      /* ignore */
    }
    return;
  }
  window.dispatchEvent(new Event(WORKS_DESKTOP_TOUR_START_EVENT));
}

export function consumeWorksDesktopTourRestart() {
  try {
    const restart =
      window.sessionStorage.getItem(WORKS_DESKTOP_TOUR_RESTART_KEY) === "1";
    if (restart) {
      window.sessionStorage.removeItem(WORKS_DESKTOP_TOUR_RESTART_KEY);
    }
    return restart;
  } catch {
    return false;
  }
}

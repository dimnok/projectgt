export const WORKS_MOBILE_TOUR_STORAGE_KEY =
  "projectgt.works-mobile-tour.v1";
export const WORKS_MOBILE_TOUR_RESTART_KEY =
  "projectgt.works-mobile-tour.restart";
export const WORKS_MOBILE_TOUR_START_EVENT = "works-mobile-tour-start";

export {
  isVisibleTourElement,
  sleep,
  waitForTourElement,
} from "@/features/works/tour/works-tour-runtime";

export function markWorksMobileTourSeen() {
  try {
    window.localStorage.setItem(WORKS_MOBILE_TOUR_STORAGE_KEY, "1");
  } catch {
    /* ignore private mode */
  }
}

export function hasSeenWorksMobileTour() {
  try {
    return window.localStorage.getItem(WORKS_MOBILE_TOUR_STORAGE_KEY) === "1";
  } catch {
    return true;
  }
}

export function requestWorksMobileTour(options?: { persistRestart?: boolean }) {
  if (options?.persistRestart) {
    try {
      window.sessionStorage.setItem(WORKS_MOBILE_TOUR_RESTART_KEY, "1");
    } catch {
      /* ignore */
    }
    return;
  }
  window.dispatchEvent(new Event(WORKS_MOBILE_TOUR_START_EVENT));
}

export function consumeWorksMobileTourRestart() {
  try {
    const restart =
      window.sessionStorage.getItem(WORKS_MOBILE_TOUR_RESTART_KEY) === "1";
    if (restart) {
      window.sessionStorage.removeItem(WORKS_MOBILE_TOUR_RESTART_KEY);
    }
    return restart;
  } catch {
    return false;
  }
}

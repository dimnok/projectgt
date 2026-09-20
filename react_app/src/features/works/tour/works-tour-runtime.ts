import { driver, type Config, type DriveStep, type Driver } from "driver.js";

export function isVisibleTourElement(el: Element) {
  const rect = el.getBoundingClientRect();
  if (rect.width < 2 || rect.height < 2) {
    return false;
  }
  const style = window.getComputedStyle(el);
  return style.visibility !== "hidden" && style.display !== "none";
}

export async function waitForTourElement(
  selector: string,
  timeoutMs = 2500
): Promise<Element | null> {
  const deadline = Date.now() + timeoutMs;
  return new Promise((resolve) => {
    const tick = () => {
      const el = document.querySelector(selector);
      if (el && isVisibleTourElement(el)) {
        resolve(el);
        return;
      }
      if (Date.now() > deadline) {
        resolve(null);
        return;
      }
      requestAnimationFrame(tick);
    };
    tick();
  });
}

export function sleep(ms: number) {
  return new Promise((resolve) => {
    window.setTimeout(resolve, ms);
  });
}

export function queryVisibleTourEl(...selectors: string[]) {
  return () => {
    for (const selector of selectors) {
      const el = document.querySelector(selector);
      if (el && isVisibleTourElement(el)) {
        return el;
      }
    }
    return document.body;
  };
}

export const WORKS_TOUR_DRIVER_LOOK: Omit<Config, "steps"> = {
  animate: true,
  smoothScroll: true,
  showProgress: true,
  allowClose: true,
  overlayColor: "oklch(0 0 0)",
  overlayOpacity: 0.58,
  stagePadding: 10,
  stageRadius: 16,
  popoverOffset: 14,
  disableActiveInteraction: true,
  popoverClass: "works-tour-popover",
  progressText: "{{current}} из {{total}}",
  nextBtnText: "Далее",
  prevBtnText: "Назад",
  doneBtnText: "Готово",
  onPopoverRender: (popover) => {
    popover.closeButton.setAttribute("aria-label", "Пропустить");
  },
};

export function createWorksTour(
  steps: DriveStep[],
  onDestroyed: () => void
): Driver {
  return driver({
    ...WORKS_TOUR_DRIVER_LOOK,
    steps,
    onDestroyed,
  });
}

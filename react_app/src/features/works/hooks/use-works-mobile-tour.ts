"use client";

import { useCallback, useEffect, useRef } from "react";
import { driver, type DriveStep, type Driver } from "driver.js";
import "driver.js/dist/driver.css";

import type { Work } from "@/features/works/types/work.types";
import {
  consumeWorksMobileTourRestart,
  hasSeenWorksMobileTour,
  isVisibleTourElement,
  markWorksMobileTourSeen,
  sleep,
  waitForTourElement,
  WORKS_MOBILE_TOUR_START_EVENT,
} from "@/features/works/ui/mobile/works-mobile-tour";

type UseWorksMobileTourOptions = {
  enabled: boolean;
  isReady: boolean;
  canOpenShift: boolean;
  dayWorks: Work[];
  monthWorks: Work[];
  openWork: (work: Work) => void;
  closeWork: () => void;
  setDetailsTab: (tab: string) => void;
  setCalendarOpen: (open: boolean) => void;
};

function queryTourEl(...selectors: string[]) {
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

async function waitForItemsTarget() {
  await sleep(120);
  const add = document.querySelector("[data-tour='works-add-item']");
  if (add && isVisibleTourElement(add)) {
    return add;
  }
  return waitForTourElement("[data-tour='works-tab-items']");
}

function pickDemoWork(dayWorks: Work[], monthWorks: Work[]) {
  return (
    dayWorks.find((work) => work.status === "open") ??
    dayWorks[0] ??
    monthWorks.find((work) => work.status === "open") ??
    monthWorks[0] ??
    null
  );
}

export function useWorksMobileTour({
  enabled,
  isReady,
  canOpenShift,
  dayWorks,
  monthWorks,
  openWork,
  closeWork,
  setDetailsTab,
  setCalendarOpen,
}: UseWorksMobileTourOptions) {
  const driverRef = useRef<Driver | null>(null);
  const dayWorksRef = useRef(dayWorks);
  const monthWorksRef = useRef(monthWorks);
  const openWorkRef = useRef(openWork);
  const closeWorkRef = useRef(closeWork);
  const setDetailsTabRef = useRef(setDetailsTab);
  const setCalendarOpenRef = useRef(setCalendarOpen);
  const canOpenShiftRef = useRef(canOpenShift);

  dayWorksRef.current = dayWorks;
  monthWorksRef.current = monthWorks;
  openWorkRef.current = openWork;
  closeWorkRef.current = closeWork;
  setDetailsTabRef.current = setDetailsTab;
  setCalendarOpenRef.current = setCalendarOpen;
  canOpenShiftRef.current = canOpenShift;

  const stopTour = useCallback(() => {
    driverRef.current?.destroy();
    driverRef.current = null;
  }, []);

  const startTour = useCallback(async () => {
    if (!enabled) {
      return;
    }
    stopTour();
    closeWorkRef.current();
    setDetailsTabRef.current("data");
    setCalendarOpenRef.current(true);
    const calendar = await waitForTourElement("[data-tour='works-calendar']");
    if (!calendar) {
      return;
    }

    const hasDemoWork = Boolean(
      pickDemoWork(dayWorksRef.current, monthWorksRef.current)
    );
    const steps: DriveStep[] = [
      {
        element: "[data-tour='works-calendar']",
        popover: {
          title: "Это календарь",
          description:
            "Выберите день. Точка под числом — в этот день уже есть смена.",
          side: "bottom",
          align: "center",
        },
      },
    ];

    if (canOpenShiftRef.current) {
      steps.push({
        element: queryTourEl("[data-tour='works-open-shift']"),
        popover: {
          title: "Здесь открывается смена",
          description:
            "Дальше — объект, люди на смене и утреннее фото. Новую смену нельзя открыть, пока не закрыта ваша предыдущая.",
          side: "top",
          align: "center",
        },
      });
    }

    steps.push({
      element: "[data-tour='works-day-list']",
      popover: {
        title: "Смены выбранного дня",
        description: hasDemoWork
          ? "Нажмите на карточку, чтобы открыть смену. Сейчас откроем пример."
          : "Когда смена появится, она будет в этом списке.",
        side: "top",
        align: "center",
        onNextClick: async (_element, _step, { driver: tour }) => {
          const work = pickDemoWork(
            dayWorksRef.current,
            monthWorksRef.current
          );
          if (!work) {
            if (tour.hasNextStep()) {
              tour.moveNext();
            } else {
              tour.destroy();
            }
            return;
          }
          openWorkRef.current(work);
          const tabs = await waitForTourElement("[data-tour='works-tabs']");
          if (tabs) {
            tour.moveNext();
            return;
          }
          tour.destroy();
        },
      },
    });

    if (hasDemoWork) {
      steps.push(
        {
          element: queryTourEl("[data-tour='works-tabs']"),
          popover: {
            title: "Три вкладки смены",
            description:
              "Обзор — проверка и закрытие. Работы — что сделали. Люди — кто работал и сколько часов.",
            side: "bottom",
            align: "center",
            onPrevClick: async (_element, _step, { driver: tour }) => {
              closeWorkRef.current();
              const list = await waitForTourElement(
                "[data-tour='works-day-list']"
              );
              if (list) {
                tour.movePrevious();
              }
            },
            onNextClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("items");
              const target = await waitForItemsTarget();
              if (target) {
                tour.moveNext();
              }
            },
          },
        },
        {
          element: queryTourEl(
            "[data-tour='works-add-item']",
            "[data-tour='works-tab-items']"
          ),
          popover: {
            title: "Здесь добавляют работы",
            description:
              "Плюс — позиции из сметы и количество. Свайп вправо — изменить строку, влево — удалить.",
            side: "bottom",
            align: "end",
            onPrevClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("data");
              const tabs = await waitForTourElement("[data-tour='works-tabs']");
              if (tabs) {
                tour.movePrevious();
              }
            },
            onNextClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("data");
              const overview = await waitForTourElement(
                "[data-tour='works-overview']"
              );
              if (overview) {
                tour.moveNext();
              }
            },
          },
        },
        {
          element: queryTourEl("[data-tour='works-overview']"),
          popover: {
            title: "Здесь закрывают день",
            description:
              "Нужны работы с количеством, часы больше нуля и вечернее фото. Кнопка «Назад» смену не закрывает.",
            side: "top",
            align: "center",
            onPrevClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("items");
              const target = await waitForItemsTarget();
              if (target) {
                tour.movePrevious();
              }
            },
          },
        }
      );
    }

    const tour = driver({
      steps,
      animate: true,
      smoothScroll: true,
      showProgress: true,
      allowClose: true,
      overlayColor: "oklch(0 0 0)",
      overlayOpacity: 0.62,
      stagePadding: 8,
      stageRadius: 14,
      popoverOffset: 12,
      disableActiveInteraction: true,
      popoverClass: "works-tour-popover",
      progressText: "{{current}} из {{total}}",
      nextBtnText: "Далее",
      prevBtnText: "Назад",
      doneBtnText: "Готово",
      onPopoverRender: (popover) => {
        popover.closeButton.setAttribute("aria-label", "Пропустить");
      },
      onDestroyed: () => {
        markWorksMobileTourSeen();
        driverRef.current = null;
      },
    });
    driverRef.current = tour;
    tour.drive();
  }, [enabled, stopTour]);

  useEffect(() => {
    if (!enabled) {
      return;
    }
    function onStart() {
      void startTour();
    }
    window.addEventListener(WORKS_MOBILE_TOUR_START_EVENT, onStart);
    return () => {
      window.removeEventListener(WORKS_MOBILE_TOUR_START_EVENT, onStart);
    };
  }, [enabled, startTour]);

  useEffect(() => {
    if (!enabled || !isReady) {
      return;
    }
    if (consumeWorksMobileTourRestart()) {
      void startTour();
      return;
    }
    if (!hasSeenWorksMobileTour()) {
      const timer = window.setTimeout(() => {
        void startTour();
      }, 500);
      return () => window.clearTimeout(timer);
    }
  }, [enabled, isReady, startTour]);

  useEffect(() => {
    return () => {
      stopTour();
    };
  }, [stopTour]);
}

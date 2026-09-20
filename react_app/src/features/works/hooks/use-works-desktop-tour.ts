"use client";

import { useCallback, useEffect, useRef } from "react";
import type { DriveStep, Driver } from "driver.js";
import "driver.js/dist/driver.css";

import type { Work } from "@/features/works/types/work.types";
import {
  createWorksTour,
  isVisibleTourElement,
  queryVisibleTourEl,
  sleep,
  waitForTourElement,
} from "@/features/works/tour/works-tour-runtime";
import {
  consumeWorksDesktopTourRestart,
  hasSeenWorksDesktopTour,
  markWorksDesktopTourSeen,
  WORKS_DESKTOP_TOUR_START_EVENT,
} from "@/features/works/ui/desktop/works-desktop-tour";

type UseWorksDesktopTourOptions = {
  enabled: boolean;
  isReady: boolean;
  canOpenShift: boolean;
  dayWorks: Work[];
  monthWorks: Work[];
  openWork: (work: Work) => void;
  closeWork: () => void;
  setDetailsTab: (tab: string) => void;
};

function pickDemoWork(dayWorks: Work[], monthWorks: Work[]) {
  return (
    dayWorks.find((work) => work.status === "open") ??
    dayWorks[0] ??
    monthWorks.find((work) => work.status === "open") ??
    monthWorks[0] ??
    null
  );
}

async function waitForHoursTarget() {
  await sleep(140);
  const presets = document.querySelector("[data-tour='works-d-hours']");
  if (presets && isVisibleTourElement(presets)) {
    return presets;
  }
  return waitForTourElement("[data-tour='works-d-tab-hours']");
}

async function waitForWorksTarget() {
  await sleep(140);
  const add = document.querySelector("[data-tour='works-d-add-item']");
  if (add && isVisibleTourElement(add)) {
    return add;
  }
  return waitForTourElement("[data-tour='works-d-tab-items']");
}

export function useWorksDesktopTour({
  enabled,
  isReady,
  canOpenShift,
  dayWorks,
  monthWorks,
  openWork,
  closeWork,
  setDetailsTab,
}: UseWorksDesktopTourOptions) {
  const driverRef = useRef<Driver | null>(null);
  const dayWorksRef = useRef(dayWorks);
  const monthWorksRef = useRef(monthWorks);
  const openWorkRef = useRef(openWork);
  const closeWorkRef = useRef(closeWork);
  const setDetailsTabRef = useRef(setDetailsTab);
  const canOpenShiftRef = useRef(canOpenShift);

  dayWorksRef.current = dayWorks;
  monthWorksRef.current = monthWorks;
  openWorkRef.current = openWork;
  closeWorkRef.current = closeWork;
  setDetailsTabRef.current = setDetailsTab;
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
    const calendar = await waitForTourElement("[data-tour='works-d-calendar']");
    if (!calendar) {
      return;
    }

    const hasDemoWork = Boolean(
      pickDemoWork(dayWorksRef.current, monthWorksRef.current)
    );

    const steps: DriveStep[] = [
      {
        element: "[data-tour='works-d-calendar']",
        popover: {
          title: "Календарь смен",
          description:
            "Выберите день. Точка под числом — смена уже есть. Справа сразу сводка за месяц.",
          side: "right",
          align: "start",
        },
      },
    ];

    if (canOpenShiftRef.current) {
      steps.push({
        element: queryVisibleTourEl("[data-tour='works-d-open-shift']"),
        popover: {
          title: "Новая смена",
          description:
            "Объект, люди на смене и утреннее фото. Пока ваша предыдущая смена открыта, новую открыть нельзя.",
          side: "right",
          align: "center",
        },
      });
    }

    steps.push({
      element: "[data-tour='works-d-day-list']",
      popover: {
        title: "Смены выбранного дня",
        description:
          "Нажмите карточку — справа откроется смена. Повторный щелчок снимает выбор.",
        side: "right",
        align: "start",
      },
    });

    steps.push({
      element: queryVisibleTourEl("[data-tour='works-d-summary']"),
      popover: {
        title: "Сводка месяца",
        description:
          "Объём, график, объекты и системы. Это обзор, не журнал одной смены.",
        side: "left",
        align: "start",
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
          const tabs = await waitForTourElement("[data-tour='works-d-tabs']");
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
          element: queryVisibleTourEl("[data-tour='works-d-tabs']"),
          popover: {
            title: "Карточка смены",
            description:
              "Обзор и фото — закрытие дня. Работы — объём. Сотрудники — часы 8 / 10 / 12. «Скрыть» только убирает карточку, смену не закрывает.",
            side: "left",
            align: "start",
            onPrevClick: async (_element, _step, { driver: tour }) => {
              closeWorkRef.current();
              const summary = await waitForTourElement(
                "[data-tour='works-d-summary']"
              );
              if (summary) {
                tour.movePrevious();
              }
            },
            onNextClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("items");
              const target = await waitForWorksTarget();
              if (target) {
                tour.moveNext();
              }
            },
          },
        },
        {
          element: queryVisibleTourEl(
            "[data-tour='works-d-add-item']",
            "[data-tour='works-d-tab-items']"
          ),
          popover: {
            title: "Добавление работ",
            description:
              "Плюс — позиции из сметы и количество. Карандаш и корзина в строке — изменить или удалить.",
            side: "bottom",
            align: "end",
            onPrevClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("data");
              const tabs = await waitForTourElement(
                "[data-tour='works-d-tabs']"
              );
              if (tabs) {
                tour.movePrevious();
              }
            },
            onNextClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("hours");
              const hours = await waitForHoursTarget();
              if (hours) {
                tour.moveNext();
              }
            },
          },
        },
        {
          element: queryVisibleTourEl(
            "[data-tour='works-d-hours']",
            "[data-tour='works-d-tab-hours']"
          ),
          popover: {
            title: "Часы сотрудников",
            description:
              "Кнопки 8 / 10 / 12 ставят часы всем сразу. Потом «Сохранить». Плюс добавляет человека.",
            side: "bottom",
            align: "start",
            onPrevClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("items");
              const target = await waitForWorksTarget();
              if (target) {
                tour.movePrevious();
              }
            },
            onNextClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("data");
              const overview = await waitForTourElement(
                "[data-tour='works-d-overview']"
              );
              if (overview) {
                tour.moveNext();
              }
            },
          },
        },
        {
          element: queryVisibleTourEl("[data-tour='works-d-overview']"),
          popover: {
            title: "Закрытие дня",
            description:
              "Нужны работы с количеством, часы больше нуля и вечернее фото. Затем «Закрыть смену».",
            side: "left",
            align: "start",
            onPrevClick: async (_element, _step, { driver: tour }) => {
              setDetailsTabRef.current("hours");
              const hours = await waitForHoursTarget();
              if (hours) {
                tour.movePrevious();
              }
            },
          },
        }
      );
    }

    const tour = createWorksTour(steps, () => {
      markWorksDesktopTourSeen();
      driverRef.current = null;
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
    window.addEventListener(WORKS_DESKTOP_TOUR_START_EVENT, onStart);
    return () => {
      window.removeEventListener(WORKS_DESKTOP_TOUR_START_EVENT, onStart);
    };
  }, [enabled, startTour]);

  useEffect(() => {
    if (!enabled || !isReady) {
      return;
    }
    if (consumeWorksDesktopTourRestart()) {
      void startTour();
      return;
    }
    if (!hasSeenWorksDesktopTour()) {
      const timer = window.setTimeout(() => {
        void startTour();
      }, 650);
      return () => window.clearTimeout(timer);
    }
  }, [enabled, isReady, startTour]);

  useEffect(() => {
    return () => {
      stopTour();
    };
  }, [stopTour]);
}

"use client";

import { PlusIcon, SmartphoneIcon } from "lucide-react";
import { useMemo, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { usePermissions } from "@/hooks/use-permissions";
import { useIsLandscapeMobile } from "@/hooks/use-mobile";
import { useMyOpenWorkId } from "@/features/works/hooks/use-open-work";
import { useMonthWorks } from "@/features/works/hooks/use-works";
import type { Work } from "@/features/works/types/work.types";
import { WorkDetailsMobile } from "@/features/works/ui/mobile/work-details-mobile";
import { WorksMobileCalendar } from "@/features/works/ui/mobile/works-mobile-calendar";
import { WorksMobileList } from "@/features/works/ui/mobile/works-mobile-list";
import { WorkOpenSheet } from "@/features/works/ui/mobile/work-open-sheet";
import {
  currentMonthKey,
  defaultDayInMonth,
  formatRuDate,
  toMonthKey,
} from "@/features/works/utils/work.utils";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

export function WorksMobile() {
  const [visibleMonth, setVisibleMonth] = useState(currentMonthKey);
  const [selectedDate, setSelectedDate] = useState(() =>
    defaultDayInMonth(currentMonthKey())
  );
  const [selectedWork, setSelectedWork] = useState<Work | null>(null);
  const [calendarOpen, setCalendarOpen] = useState(true);
  const [openShiftOpen, setOpenShiftOpen] = useState(false);
  const isLandscape = useIsLandscapeMobile();
  const { can } = usePermissions();
  const myOpenQuery = useMyOpenWorkId();
  const canOpenShift = can("works", "create");
  const worksQuery = useMonthWorks(visibleMonth, undefined, true);
  const monthWorks = useMemo(
    () => worksQuery.data ?? [],
    [worksQuery.data]
  );
  const selectedWorkFresh = selectedWork
    ? (monthWorks.find((work) => work.id === selectedWork.id) ?? selectedWork)
    : null;

  const shiftDates = useMemo(
    () => [...new Set(monthWorks.map((work) => work.date.slice(0, 10)))],
    [monthWorks]
  );

  const dayWorks = useMemo(
    () => monthWorks.filter((work) => work.date.slice(0, 10) === selectedDate),
    [monthWorks, selectedDate]
  );

  function handleOpenedWork(work: Work) {
    const date = work.date.slice(0, 10);
    setSelectedDate(date);
    setVisibleMonth(toMonthKey(date));
    setCalendarOpen(false);
    setSelectedWork(work);
  }

  function handleOpenShiftClick() {
    if (myOpenQuery.data) {
      toast.error(
        "У вас уже есть открытая смена. Закройте её перед открытием новой."
      );
      return;
    }
    setOpenShiftOpen(true);
  }

  if (isLandscape) {
    return (
      <div
        data-fill-viewport
        className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col items-center justify-center bg-background p-6 text-center"
      >
        <div className="mb-4 flex size-12 items-center justify-center rounded-full bg-muted text-foreground">
          <SmartphoneIcon className="size-6" />
        </div>
        <h2 className="text-base font-semibold">Поверните устройство</h2>
        <p className="mt-1 max-w-xs text-sm text-muted-foreground">
          Модуль «Работы» работает в вертикальном (портретном) режиме.
        </p>
      </div>
    );
  }

  if (selectedWorkFresh) {
    return (
      <WorkDetailsMobile
        key={selectedWorkFresh.id}
        work={selectedWorkFresh}
        onBack={() => setSelectedWork(null)}
        onDeleted={() => setSelectedWork(null)}
      />
    );
  }

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <header className="shrink-0 border-b bg-background">
        <MobileAppBar
          title="Смены"
          className="border-b-0"
        />
        <WorksMobileCalendar
          month={visibleMonth}
          selectedDate={selectedDate}
          shiftDates={shiftDates}
          open={calendarOpen}
          onOpenChange={setCalendarOpen}
          onMonthChange={setVisibleMonth}
          onSelectDate={setSelectedDate}
        />
      </header>
      <div
        className="min-h-0 flex-1 overflow-y-auto overflow-x-hidden overscroll-y-contain px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]"
        onScroll={(event) => {
          if (calendarOpen && event.currentTarget.scrollTop > 8) {
            setCalendarOpen(false);
          }
        }}
      >
        {canOpenShift ? (
          <div className="mb-3">
            <Button
              type="button"
              className="w-full"
              onClick={handleOpenShiftClick}
            >
              <PlusIcon data-icon="inline-start" />
              Открыть смену
            </Button>
          </div>
        ) : null}
        <WorksMobileList
          works={dayWorks}
          isLoading={worksQuery.isLoading}
          errorMessage={
            worksQuery.isError
              ? worksQuery.error instanceof Error
                ? worksQuery.error.message
                : "Не удалось загрузить смены"
              : undefined
          }
          emptyDescription={`На ${formatRuDate(selectedDate)} смен нет.`}
          onSelectWork={setSelectedWork}
        />
      </div>
      <WorkOpenSheet
        open={openShiftOpen}
        onOpenChange={setOpenShiftOpen}
        onOpened={handleOpenedWork}
      />
    </div>
  );
}

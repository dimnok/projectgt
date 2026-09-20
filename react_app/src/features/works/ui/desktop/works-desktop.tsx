"use client";

import { ClipboardListIcon, PlusIcon, XIcon } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { usePermissions } from "@/hooks/use-permissions";
import { useMyOpenWorkId } from "@/features/works/hooks/use-open-work";
import { useMonthHeaders, useMonthWorks } from "@/features/works/hooks/use-works";
import type { MonthHeader, Work } from "@/features/works/types/work.types";
import { WorksCalendar } from "@/features/works/ui/shared/works-calendar";
import { WorksList } from "@/features/works/ui/desktop/works-list";
import {
  WorksMonthSummary,
  WorksMonthSummaryHeader,
} from "@/features/works/ui/desktop/works-month-summary";
import { WorkDetails } from "@/features/works/ui/shared/work-details";
import { WorkOpenDialog } from "@/features/works/ui/shared/work-open-dialog";
import { useWorksDesktopTour } from "@/features/works/hooks/use-works-desktop-tour";
import {
  currentMonthKey,
  defaultDayInMonth,
  formatRuDate,
  toMonthKey,
} from "@/features/works/utils/work.utils";

function headerForMonth(months: MonthHeader[], month: string): MonthHeader {
  return (
    months.find((item) => item.month === month) ?? {
      month,
      worksCount: 0,
      totalAmount: 0,
      ownTotalAmount: 0,
    }
  );
}

export function WorksDesktop() {
  const [visibleMonth, setVisibleMonth] = useState(currentMonthKey);
  const [selectedDate, setSelectedDate] = useState(() =>
    defaultDayInMonth(currentMonthKey())
  );
  const [selectedWork, setSelectedWork] = useState<Work | null>(null);
  const [selectedObjectId, setSelectedObjectId] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<"summary" | "shift">("summary");
  const [openShiftOpen, setOpenShiftOpen] = useState(false);
  const [detailsTab, setDetailsTab] = useState("data");
  const { can } = usePermissions();
  const myOpenQuery = useMyOpenWorkId();
  const canOpenShift = can("works", "create");

  const monthsQuery = useMonthHeaders();
  const worksQuery = useMonthWorks(visibleMonth, undefined, true);

  const months = monthsQuery.data ?? [];
  const selectedHeader = headerForMonth(months, visibleMonth);
  const monthWorks = worksQuery.data ?? [];
  const shiftDates = useMemo(
    () => [...new Set(monthWorks.map((work) => work.date.slice(0, 10)))],
    [monthWorks]
  );

  const dayWorks = useMemo(
    () => monthWorks.filter((work) => work.date.slice(0, 10) === selectedDate),
    [monthWorks, selectedDate]
  );

  useEffect(() => {
    if (!selectedWork) {
      return;
    }
    const fresh = monthWorks.find((work) => work.id === selectedWork.id);
    if (fresh && fresh !== selectedWork) {
      setSelectedWork(fresh);
    }
  }, [monthWorks, selectedWork]);

  function handleMonthChange(month: string) {
    setVisibleMonth(month);
    setSelectedWork(null);
    setSelectedObjectId(null);
    setViewMode("summary");
    setDetailsTab("data");
  }

  function handleSelectDate(date: string) {
    setSelectedDate(date);
    setVisibleMonth(date.slice(0, 7));
    setSelectedWork(null);
    setSelectedObjectId(null);
    setViewMode("summary");
    setDetailsTab("data");
  }

  function handleSelectWork(work: Work) {
    if (selectedWork?.id === work.id) {
      setSelectedWork(null);
      setViewMode("summary");
      setDetailsTab("data");
    } else {
      setSelectedWork(work);
      setSelectedDate(work.date.slice(0, 10));
      setVisibleMonth(work.date.slice(0, 7));
      setViewMode("shift");
      setDetailsTab("data");
    }
  }

  function handleOpenedWork(work: Work) {
    const date = work.date.slice(0, 10);
    setSelectedDate(date);
    setVisibleMonth(toMonthKey(date));
    setSelectedWork(work);
    setSelectedObjectId(null);
    setViewMode("shift");
    setDetailsTab("data");
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

  const showShift = Boolean(selectedWork) && viewMode === "shift";

  useWorksDesktopTour({
    enabled: true,
    isReady: !worksQuery.isLoading,
    canOpenShift,
    dayWorks,
    monthWorks,
    openWork: (work) => {
      const date = work.date.slice(0, 10);
      setSelectedDate(date);
      setVisibleMonth(toMonthKey(date));
      setSelectedWork(work);
      setSelectedObjectId(null);
      setViewMode("shift");
      setDetailsTab("data");
    },
    closeWork: () => {
      setSelectedWork(null);
      setViewMode("summary");
      setDetailsTab("data");
    },
    setDetailsTab,
  });

  const paneActions = selectedWork ? (
    <>
      <Button
        type="button"
        variant="ghost"
        size="sm"
        onClick={() => setViewMode("shift")}
        className="gap-1.5 text-xs font-medium"
      >
        <ClipboardListIcon className="size-3.5" />
        <span>Смена: {formatRuDate(selectedWork.date)}</span>
      </Button>
      <Button
        type="button"
        variant="ghost"
        size="xs"
        onClick={() => {
          setSelectedWork(null);
          setViewMode("summary");
          setDetailsTab("data");
        }}
        className="gap-1 text-xs text-muted-foreground hover:text-foreground"
      >
        <span>Скрыть</span>
        <XIcon className="size-3.5" />
      </Button>
    </>
  ) : null;

  return (
    <div
      data-fill-viewport
      className="grid h-full min-h-0 min-w-0 w-full flex-1 grid-cols-1 content-stretch items-stretch gap-3 lg:grid-cols-[var(--content-aside-width)_minmax(0,1fr)] lg:gap-6"
    >
      <div className="flex min-h-0 min-w-0 flex-1 flex-col gap-3">
        <div data-tour="works-d-calendar">
          <WorksCalendar
            month={visibleMonth}
            selectedDate={selectedDate}
            shiftDates={shiftDates}
            onMonthChange={handleMonthChange}
            onSelectDate={handleSelectDate}
          />
        </div>
        <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto scroll-shadow-gutter">
          {canOpenShift ? (
            <div className="mb-3 shrink-0" data-tour="works-d-open-shift">
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
          <div data-tour="works-d-day-list">
            <WorksList
              works={dayWorks}
              selectedWork={selectedWork}
              isLoading={worksQuery.isLoading}
              errorMessage={
                worksQuery.isError
                  ? worksQuery.error instanceof Error
                    ? worksQuery.error.message
                    : "Не удалось загрузить смены"
                  : undefined
              }
              emptyTitle="Смен нет"
              emptyDescription={`На ${formatRuDate(selectedDate)} смен нет.`}
              onSelectWork={handleSelectWork}
            />
          </div>
        </div>
      </div>

      <aside className="flex min-h-0 min-w-0 w-full flex-1 flex-col gap-3">
        {showShift && selectedWork ? (
          <WorkDetails
            work={selectedWork}
            headerMonth={visibleMonth}
            tab={detailsTab}
            onTabChange={setDetailsTab}
            onSwitchToSummary={() => setViewMode("summary")}
            onClose={() => {
              setSelectedWork(null);
              setViewMode("summary");
              setDetailsTab("data");
            }}
            onDeleted={() => {
              setSelectedWork(null);
              setViewMode("summary");
              setDetailsTab("data");
            }}
          />
        ) : (
          <>
            <div className="shrink-0">
              <WorksMonthSummaryHeader
                header={selectedHeader}
                actions={paneActions}
              />
            </div>
            <div
              className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto scroll-shadow-gutter"
              data-tour="works-d-summary"
            >
              <WorksMonthSummary
                header={selectedHeader}
                selectedObjectId={selectedObjectId}
                onSelectObject={setSelectedObjectId}
              />
            </div>
          </>
        )}
      </aside>
      <WorkOpenDialog
        open={openShiftOpen}
        onOpenChange={setOpenShiftOpen}
        onOpened={handleOpenedWork}
      />
    </div>
  );
}

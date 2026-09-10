"use client";

import { useMemo, useRef, useState } from "react";
import { Loader2Icon, PinIcon, XIcon } from "lucide-react";
import {
  Popover,
  PopoverTrigger,
  PopoverContent,
  PopoverClose,
} from "@/components/ui/popover";

import { useEstimateItemHistory } from "@/features/estimates/hooks/use-estimate-item-history";
import { useEstimateItemEditHistory } from "@/features/estimates/hooks/use-estimate-item-edit-history";
import { buildEstimateItemTimeline } from "@/features/estimates/utils/estimate-history-format";
import type { EstimateItem } from "@/features/estimates/types/estimate.types";
import {
  formatCurrency,
  formatQuantity,
  formatRuDate,
} from "@/features/estimates/utils/estimate.utils";
import { cn } from "@/lib/utils";

type EstimateQuantityCellProps = {
  item: EstimateItem;
  displayQuantity?: number;
  highlightOverrun?: boolean;
};

type AggregatedSection = {
  section: string;
  total: number;
  floors: Array<{ floor: string; quantity: number }>;
};

type ViewMode = "history" | "summary" | "edits";

export function EstimateQuantityCell({
  item,
  displayQuantity,
  highlightOverrun = false,
}: EstimateQuantityCellProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [isPinned, setIsPinned] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>("history");
  const [size, setSize] = useState<{ width: number; height: number } | null>(null);

  const cardRef = useRef<HTMLDivElement | null>(null);

  // 1. История фактического выполнения (акты / закрытия работ)
  const {
    data: history,
    isLoading: isHistoryLoading,
    isError: isHistoryError,
    error: historyError,
  } = useEstimateItemHistory(item.id, isOpen);

  // 2. История ручных изменений сметной позиции
  const {
    data: editHistory,
    isLoading: isEditLoading,
    isError: isEditError,
    error: editError,
  } = useEstimateItemEditHistory(item.id, isOpen);

  const timelineEvents = useMemo(
    () => buildEstimateItemTimeline(item, editHistory ?? []),
    [item, editHistory]
  );

  const shownQuantity = displayQuantity !== undefined ? displayQuantity : item.quantity;
  const formattedShownQuantity = formatQuantity(shownQuantity);
  const formattedPlanQuantity = formatQuantity(item.quantity);

  const totalCompleted = history?.reduce((sum, h) => sum + h.quantity, 0) ?? 0;
  const isOverrun = totalCompleted > item.quantity + 0.0001;

  const summary = useMemo<AggregatedSection[]>(() => {
    if (!history || history.length === 0) return [];
    const sectionMap = new Map<string, Map<string, number>>();

    for (const entry of history) {
      const s = entry.section && entry.section !== "—" ? entry.section : "Без участка";
      const f = entry.floor && entry.floor !== "—" ? entry.floor : "—";

      let floorMap = sectionMap.get(s);
      if (!floorMap) {
        floorMap = new Map();
        sectionMap.set(s, floorMap);
      }
      floorMap.set(f, (floorMap.get(f) ?? 0) + entry.quantity);
    }

    const result: AggregatedSection[] = [];

    for (const [sectionName, floorMap] of sectionMap.entries()) {
      const floors: Array<{ floor: string; quantity: number }> = [];
      let total = 0;
      for (const [floorName, qty] of floorMap.entries()) {
        floors.push({ floor: floorName, quantity: qty });
        total += qty;
      }
      floors.sort((a, b) => {
        const na = parseFloat(a.floor.replace(",", "."));
        const nb = parseFloat(b.floor.replace(",", "."));
        if (!isNaN(na) && !isNaN(nb)) return na - nb;
        return a.floor.localeCompare(b.floor, "ru", { numeric: true });
      });
      result.push({ section: sectionName, total, floors });
    }

    result.sort((a, b) => a.section.localeCompare(b.section, "ru", { numeric: true }));
    return result;
  }, [history]);

  function handleOpenChange(
    nextOpen: boolean,
    details?: { reason?: string }
  ) {
    if (isPinned && !nextOpen && details?.reason === "hover-out") {
      return;
    }
    setIsOpen(nextOpen);
    if (!nextOpen) {
      setIsPinned(false);
      setSize(null);
      setViewMode("history");
    }
  }

  function handleTogglePin(e: React.MouseEvent) {
    e.stopPropagation();
    setIsPinned((prev) => !prev);
  }

  function startResize(e: React.MouseEvent, corner: "bottom-left" | "bottom-right") {
    e.preventDefault();
    e.stopPropagation();
    setIsPinned(true);

    const card = cardRef.current;
    if (!card) return;

    const startRect = card.getBoundingClientRect();
    const startX = e.clientX;
    const startY = e.clientY;

    function onPointerMove(moveEvent: MouseEvent) {
      const deltaY = moveEvent.clientY - startY;
      const newHeight = Math.max(180, Math.min(window.innerHeight * 0.85, startRect.height + deltaY));

      let newWidth = startRect.width;
      if (corner === "bottom-right") {
        const deltaX = moveEvent.clientX - startX;
        newWidth = Math.max(340, Math.min(window.innerWidth * 0.9, startRect.width + deltaX));
      } else {
        const deltaX = startX - moveEvent.clientX;
        newWidth = Math.max(340, Math.min(window.innerWidth * 0.9, startRect.width + deltaX));
      }

      setSize({ width: newWidth, height: newHeight });
    }

    function onPointerUp() {
      window.removeEventListener("mousemove", onPointerMove);
      window.removeEventListener("mouseup", onPointerUp);
    }

    window.addEventListener("mousemove", onPointerMove);
    window.addEventListener("mouseup", onPointerUp);
  }

  return (
    <Popover open={isOpen} onOpenChange={handleOpenChange}>
      <PopoverTrigger
        render={<button type="button" />}
        openOnHover={!isPinned}
        delay={160}
        closeDelay={120}
        onClick={() => {
          setIsPinned(true);
        }}
        className={cn(
          "inline-block font-medium tabular-nums transition-colors cursor-pointer select-none hover:text-primary",
          highlightOverrun && "text-destructive"
        )}
        title="Наведите для просмотра или нажмите для фиксации окна"
      >
        <span>{formattedShownQuantity}</span>
      </PopoverTrigger>

      <PopoverContent
        side="top"
        align="center"
        sideOffset={6}
        ref={cardRef}
        style={
          size
            ? {
                width: `${size.width}px`,
                height: `${size.height}px`,
                maxWidth: "90vw",
                maxHeight: "85vh",
              }
            : undefined
        }
        className={cn(
          "relative z-50 flex flex-col rounded-xl border border-border/80 bg-popover p-3 text-popover-foreground shadow-xl outline-none select-text",
          !size && "w-96 sm:w-115 min-w-[340px] max-w-[90vw] min-h-[190px] max-h-[85vh]"
        )}
      >
        {/* Шапка карточки: параметры позиции */}
        <div className="shrink-0 border-b border-border/60 pb-2">
          <div className="flex items-center justify-between gap-2">
            <span className="text-xs font-semibold text-foreground">
              Детали позиции
            </span>
            <div className="flex items-center gap-1">
              <span className="text-[11px] text-muted-foreground tabular-nums mr-1">
                По смете: {formattedPlanQuantity} {item.unit}
              </span>
              <button
                type="button"
                onClick={handleTogglePin}
                className={cn(
                  "inline-flex size-5 items-center justify-center rounded transition-colors cursor-pointer",
                  isPinned
                    ? "bg-primary text-primary-foreground hover:bg-primary/90"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground"
                )}
                title={isPinned ? "Снять фиксацию окна" : "Зафиксировать окно"}
                aria-label={isPinned ? "Снять фиксацию" : "Зафиксировать"}
              >
                <PinIcon className="size-3 shrink-0" />
              </button>
              <PopoverClose
                className="inline-flex size-5 items-center justify-center rounded text-muted-foreground hover:bg-muted hover:text-foreground transition-colors cursor-pointer"
                title="Закрыть"
                aria-label="Закрыть"
              >
                <XIcon className="size-3 shrink-0" />
              </PopoverClose>
            </div>
          </div>

          {item.name ? (
            <p className="mt-0.5 line-clamp-1 text-[11px] font-medium text-foreground" title={item.name}>
              {item.number ? `№ ${item.number} · ` : ""}
              {item.name}
            </p>
          ) : null}

          <div className="mt-0.5 flex flex-wrap items-center gap-x-2 text-[10.5px] text-muted-foreground">
            {item.system ? (
              <span className="truncate max-w-[180px]" title={item.system}>
                {item.system}
                {item.subsystem ? ` › ${item.subsystem}` : ""}
              </span>
            ) : null}
            <span>Цена: {formatCurrency(item.price)}</span>
            <span>Сумма: {formatCurrency(item.total)}</span>
          </div>

          {/* Переключатель режимов: Выполнение / Сводка / Правки сметы */}
          <div className="mt-2 flex items-center gap-1 rounded-lg bg-muted/60 p-0.5 w-fit">
            <button
              type="button"
              onClick={() => setViewMode("history")}
              className={cn(
                "rounded-md px-2.5 py-0.5 text-[11px] font-medium transition-colors cursor-pointer",
                viewMode === "history"
                  ? "bg-card text-foreground shadow-xs font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              Выполнение ({history?.length ?? 0})
            </button>
            <button
              type="button"
              onClick={() => setViewMode("summary")}
              className={cn(
                "rounded-md px-2.5 py-0.5 text-[11px] font-medium transition-colors cursor-pointer",
                viewMode === "summary"
                  ? "bg-card text-foreground shadow-xs font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              Сводка ({summary.length})
            </button>
            <button
              type="button"
              onClick={() => setViewMode("edits")}
              className={cn(
                "rounded-md px-2.5 py-0.5 text-[11px] font-medium transition-colors cursor-pointer",
                viewMode === "edits"
                  ? "bg-card text-foreground shadow-xs font-semibold"
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              Правки ({editHistory?.length ?? 0})
            </button>
          </div>
        </div>

        {/* Содержимое в зависимости от выбранного режима */}
        <div className="pt-2 flex flex-1 min-h-0 flex-col">
          {viewMode === "history" ? (
            /* Вкладка 1: Выполнение (акты и закрытые объемы) */
            isHistoryLoading ? (
              <div className="flex items-center justify-center py-4 text-xs text-muted-foreground">
                <Loader2Icon className="mr-1.5 size-3.5 animate-spin" />
                Загрузка данных...
              </div>
            ) : isHistoryError ? (
              <div className="py-2 text-center text-xs text-destructive">
                {historyError instanceof Error
                  ? historyError.message
                  : "Не удалось загрузить историю выполнения"}
              </div>
            ) : !history || history.length === 0 ? (
              <div className="py-4 text-center text-xs text-muted-foreground">
                Работ по этой позиции пока не вносилось
              </div>
            ) : (
              <div className="flex flex-1 min-h-0 flex-col gap-1.5">
                <div className="flex-1 min-h-24 overflow-y-auto pr-0.5">
                  <table className="w-full text-left text-[11px]">
                    <thead>
                      <tr className="border-b border-border/50 text-muted-foreground">
                        <th className="pb-1 font-medium">Дата</th>
                        <th className="pb-1 font-medium">Участок</th>
                        <th className="pb-1 font-medium">Этаж</th>
                        <th className="pb-1 text-right font-medium">Кол-во</th>
                        <th className="pb-1 pl-2 font-medium">Кто внёс</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border/30">
                      {history.map((entry) => (
                        <tr key={entry.id} className="hover:bg-muted/40 transition-colors">
                          <td className="py-1 whitespace-nowrap text-foreground font-medium">
                            {formatRuDate(entry.date)}
                          </td>
                          <td className="py-1 whitespace-nowrap text-muted-foreground">
                            {entry.section || "—"}
                          </td>
                          <td className="py-1 whitespace-nowrap text-muted-foreground">
                            {entry.floor || "—"}
                          </td>
                          <td className="py-1 whitespace-nowrap text-right text-foreground font-medium tabular-nums">
                            {formatQuantity(entry.quantity)}
                          </td>
                          <td
                            className="py-1 pl-2 whitespace-nowrap text-muted-foreground max-w-[110px] truncate"
                            title={entry.openedByName}
                          >
                            {entry.openedByName}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Итоги выполнения */}
                <div className="mt-auto shrink-0 flex flex-col gap-0.5 border-t border-border/60 pt-1.5 text-[11px]">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Всего выполнено:</span>
                    <span className="font-semibold text-foreground tabular-nums">
                      {formatQuantity(totalCompleted)} {item.unit}
                    </span>
                  </div>
                  {isOverrun ? (
                    <div className="flex items-center justify-between text-destructive">
                      <span>Превышение сметы:</span>
                      <span className="font-semibold tabular-nums">
                        +{formatQuantity(totalCompleted - item.quantity)} {item.unit}
                      </span>
                    </div>
                  ) : (
                    <div className="flex items-center justify-between text-muted-foreground">
                      <span>Остаток:</span>
                      <span className="tabular-nums">
                        {formatQuantity(item.quantity - totalCompleted)} {item.unit}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            )
          ) : viewMode === "summary" ? (
            /* Вкладка 2: Сводка по участкам и этажам */
            isHistoryLoading ? (
              <div className="flex items-center justify-center py-4 text-xs text-muted-foreground">
                <Loader2Icon className="mr-1.5 size-3.5 animate-spin" />
                Загрузка данных...
              </div>
            ) : isHistoryError ? (
              <div className="py-2 text-center text-xs text-destructive">
                {historyError instanceof Error
                  ? historyError.message
                  : "Не удалось загрузить сводку"}
              </div>
            ) : !history || history.length === 0 ? (
              <div className="py-4 text-center text-xs text-muted-foreground">
                Работ по этой позиции пока не вносилось
              </div>
            ) : (
              <div className="flex flex-1 min-h-0 flex-col gap-1.5">
                <div className="flex-1 min-h-24 overflow-y-auto pr-0.5 flex flex-col gap-2">
                  {summary.map((sec) => (
                    <div
                      key={sec.section}
                      className="rounded-lg border border-border/60 bg-muted/20 overflow-hidden"
                    >
                      <div className="flex items-center justify-between bg-muted/50 px-2.5 py-1.5 text-[11px] font-semibold text-foreground">
                        <span>{sec.section}</span>
                        <span className="tabular-nums font-bold text-foreground">
                          {formatQuantity(sec.total)} {item.unit}
                        </span>
                      </div>
                      <div className="divide-y divide-border/30 px-2.5 py-1 text-[11px]">
                        {sec.floors.map((fl) => (
                          <div
                            key={fl.floor}
                            className="flex items-center justify-between py-1 text-muted-foreground"
                          >
                            <span>этаж — {fl.floor}</span>
                            <span className="tabular-nums font-medium text-foreground">
                              {formatQuantity(fl.quantity)} {item.unit}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>

                {/* Итоги выполнения */}
                <div className="mt-auto shrink-0 flex flex-col gap-0.5 border-t border-border/60 pt-1.5 text-[11px]">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Всего выполнено:</span>
                    <span className="font-semibold text-foreground tabular-nums">
                      {formatQuantity(totalCompleted)} {item.unit}
                    </span>
                  </div>
                  {isOverrun ? (
                    <div className="flex items-center justify-between text-destructive">
                      <span>Превышение сметы:</span>
                      <span className="font-semibold tabular-nums">
                        +{formatQuantity(totalCompleted - item.quantity)} {item.unit}
                      </span>
                    </div>
                  ) : (
                    <div className="flex items-center justify-between text-muted-foreground">
                      <span>Остаток:</span>
                      <span className="tabular-nums">
                        {formatQuantity(item.quantity - totalCompleted)} {item.unit}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            )
          ) : (
            /* Вкладка 3: История правок сметной позиции */
            isEditLoading ? (
              <div className="flex items-center justify-center py-4 text-xs text-muted-foreground">
                <Loader2Icon className="mr-1.5 size-3.5 animate-spin" />
                Загрузка истории правок...
              </div>
            ) : isEditError ? (
              <div className="py-2 text-center text-xs text-destructive">
                {editError instanceof Error
                  ? editError.message
                  : "Не удалось загрузить историю правок"}
              </div>
            ) : timelineEvents.length === 0 ? (
              <div className="py-4 text-center text-xs text-muted-foreground">
                История изменений отсутствует
              </div>
            ) : (
              <div className="flex flex-1 min-h-0 flex-col gap-1.5">
                <div className="flex-1 min-h-24 overflow-y-auto pr-0.5 flex flex-col gap-2">
                  {timelineEvents.map((event) => (
                    <div
                      key={event.id}
                      className="rounded-lg border border-border/60 bg-muted/20 p-2 text-[11px]"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="flex items-center gap-1.5">
                          <span
                            className={cn(
                              "inline-flex items-center rounded-sm px-1.5 py-0.2 text-[10px] font-medium",
                              event.type === "create"
                                ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20"
                                : "bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20"
                            )}
                          >
                            {event.action}
                          </span>
                          <span className="font-medium text-foreground">
                            {event.formattedDate}
                          </span>
                        </div>
                        <span
                          className="text-muted-foreground max-w-[130px] truncate"
                          title={event.author}
                        >
                          {event.author}
                        </span>
                      </div>

                      {event.changeDetails.length > 0 ? (
                        <div className="mt-1.5 flex flex-col gap-0.5 border-t border-border/40 pt-1 text-muted-foreground">
                          {event.changeDetails.map((detail, idx) => (
                            <div key={idx} className="flex items-center gap-1">
                              <span className="text-foreground font-medium">
                                {detail}
                              </span>
                            </div>
                          ))}
                        </div>
                      ) : event.type === "create" ? (
                        <p className="mt-1 text-[10.5px] text-muted-foreground">
                          Строка внесена в смету
                        </p>
                      ) : null}
                    </div>
                  ))}
                </div>

                {/* Параметры в смете */}
                <div className="mt-auto shrink-0 flex flex-col gap-0.5 border-t border-border/60 pt-1.5 text-[11px]">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Параметры сметы:</span>
                    <span className="font-semibold text-foreground tabular-nums">
                      {formatQuantity(item.quantity)} {item.unit} · {formatCurrency(item.total)}
                    </span>
                  </div>
                </div>
              </div>
            )
          )}
        </div>

        {/* Манипулятор изменения размера: левый нижний угол */}
        <div
          role="separator"
          aria-orientation="horizontal"
          aria-label="Изменить размер за левый угол"
          title="Потяните для изменения размера"
          onMouseDown={(e) => startResize(e, "bottom-left")}
          className="absolute bottom-0 left-0 size-4 cursor-nesw-resize z-20 flex items-end justify-start p-1 text-muted-foreground/40 hover:text-foreground transition-colors"
        >
          <svg className="size-2.5 rotate-90" viewBox="0 0 6 6" fill="currentColor">
            <circle cx="1" cy="5" r="0.75" />
            <circle cx="3" cy="5" r="0.75" />
            <circle cx="5" cy="5" r="0.75" />
            <circle cx="3" cy="3" r="0.75" />
            <circle cx="5" cy="3" r="0.75" />
            <circle cx="5" cy="1" r="0.75" />
          </svg>
        </div>

        {/* Манипулятор изменения размера: правый нижний угол */}
        <div
          role="separator"
          aria-orientation="horizontal"
          aria-label="Изменить размер за правый угол"
          title="Потяните для изменения размера"
          onMouseDown={(e) => startResize(e, "bottom-right")}
          className="absolute bottom-0 right-0 size-4 cursor-nwse-resize z-20 flex items-end justify-end p-1 text-muted-foreground/40 hover:text-foreground transition-colors"
        >
          <svg className="size-2.5" viewBox="0 0 6 6" fill="currentColor">
            <circle cx="5" cy="5" r="0.75" />
            <circle cx="3" cy="5" r="0.75" />
            <circle cx="1" cy="5" r="0.75" />
            <circle cx="5" cy="3" r="0.75" />
            <circle cx="3" cy="3" r="0.75" />
            <circle cx="5" cy="1" r="0.75" />
          </svg>
        </div>
      </PopoverContent>
    </Popover>
  );
}

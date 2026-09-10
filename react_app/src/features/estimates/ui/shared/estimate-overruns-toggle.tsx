"use client";

import { TriangleAlertIcon } from "lucide-react";

import { cn } from "@/lib/utils";

type EstimateOverrunsToggleProps = {
  pressed: boolean;
  disabled?: boolean;
  count?: number;
  size?: "sm" | "default";
  onPressedChange: (pressed: boolean) => void;
};

export function EstimateOverrunsToggle({
  pressed,
  disabled = false,
  count,
  size = "default",
  onPressedChange,
}: EstimateOverrunsToggleProps) {
  const hasCount = typeof count === "number" && count > 0;
  const isSm = size === "sm";

  return (
    <button
      type="button"
      disabled={disabled}
      aria-pressed={pressed}
      aria-label={
        pressed
          ? "Показать все позиции"
          : "Показать только позиции с превышением сметы"
      }
      title={
        pressed
          ? "Показать все позиции"
          : "Показать позиции с превышением выполнения над сметой"
      }
      className={cn(
        "inline-flex items-center gap-1.5 rounded-lg font-medium transition-colors cursor-pointer select-none disabled:pointer-events-none disabled:opacity-50",
        isSm ? "h-7 px-2.5 text-[0.8rem]" : "h-6 px-2 text-[11px] rounded",
        !pressed && [
          "border border-border/80 bg-background text-foreground hover:bg-muted/60",
          hasCount &&
            "border-destructive/40 text-destructive hover:bg-destructive/10 dark:border-destructive/50 dark:hover:bg-destructive/20",
        ],
        pressed &&
          "border border-destructive bg-destructive text-white shadow-xs hover:bg-destructive/90 active:bg-destructive"
      )}
      onClick={() => onPressedChange(!pressed)}
    >
      <TriangleAlertIcon
        className={cn(
          "shrink-0",
          isSm ? "size-3.5" : "size-3",
          hasCount && !pressed && "text-destructive"
        )}
      />
      <span>Превышения</span>
      {hasCount ? (
        <span
          className={cn(
            "ml-0.5 inline-flex items-center justify-center rounded-full px-1 font-semibold tabular-nums leading-none",
            isSm ? "h-4 min-w-4 text-[11px]" : "h-3.5 min-w-3.5 text-[10px]",
            pressed
              ? "bg-white/25 text-white"
              : "bg-destructive/15 text-destructive"
          )}
        >
          {count}
        </span>
      ) : null}
    </button>
  );
}

"use client";

import { ActivityIcon } from "lucide-react";
import { cn } from "@/lib/utils";

type EstimateExecutionToggleProps = {
  pressed: boolean;
  disabled?: boolean;
  size?: "sm" | "default";
  onPressedChange: (pressed: boolean) => void;
};

export function EstimateExecutionToggle({
  pressed,
  disabled = false,
  size = "default",
  onPressedChange,
}: EstimateExecutionToggleProps) {
  const isSm = size === "sm";

  return (
    <button
      type="button"
      disabled={disabled}
      aria-pressed={pressed}
      aria-label={
        pressed ? "Скрыть колонки выполнения" : "Показать колонки выполнения"
      }
      title={pressed ? "Скрыть выполнение" : "Показать выполнение"}
      className={cn(
        "inline-flex items-center gap-1.5 rounded-lg font-medium transition-colors cursor-pointer select-none disabled:pointer-events-none disabled:opacity-50",
        isSm ? "h-7 px-2.5 text-[0.8rem]" : "h-6 px-2 text-[11px] rounded",
        !pressed &&
          "border border-border/80 bg-background text-foreground hover:bg-muted/60",
        pressed &&
          "border border-primary bg-primary text-primary-foreground shadow-xs hover:bg-primary/90 active:bg-primary"
      )}
      onClick={() => onPressedChange(!pressed)}
    >
      <ActivityIcon className={cn("shrink-0", isSm ? "size-3.5" : "size-3")} />
      <span>Выполнение</span>
    </button>
  );
}

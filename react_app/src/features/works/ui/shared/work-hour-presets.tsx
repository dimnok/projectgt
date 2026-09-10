"use client";

import { Button } from "@/components/ui/button";
import { WORK_HOUR_PRESETS } from "@/features/works/utils/work-hours-mass-edit";
import { cn } from "@/lib/utils";

type WorkHourPresetsProps = {
  selected: number | null;
  disabled?: boolean;
  onSelect: (hours: number) => void;
};

export function WorkHourPresets({
  selected,
  disabled = false,
  onSelect,
}: WorkHourPresetsProps) {
  return (
    <div className="flex items-center gap-1.5">
      <span className="px-1 text-xs font-medium text-muted-foreground">
        Всем
      </span>
      {WORK_HOUR_PRESETS.map((preset) => {
        const isSelected = selected === preset;
        return (
          <Button
            key={preset}
            type="button"
            size="sm"
            variant="outline"
            disabled={disabled}
            aria-pressed={isSelected}
            aria-label={`Заполнить всем ${preset} часов`}
            className={cn(isSelected && "bg-muted")}
            onClick={() => onSelect(preset)}
          >
            {preset} ч
          </Button>
        );
      })}
    </div>
  );
}

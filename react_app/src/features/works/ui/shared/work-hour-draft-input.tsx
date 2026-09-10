"use client";

import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

type WorkHourDraftInputProps = {
  value: string;
  disabled?: boolean;
  className?: string;
  "aria-label": string;
  onChange: (value: string) => void;
};

export function WorkHourDraftInput({
  value,
  disabled = false,
  className,
  onChange,
  "aria-label": ariaLabel,
}: WorkHourDraftInputProps) {
  return (
    <Input
      value={value}
      inputMode="decimal"
      disabled={disabled}
      aria-label={ariaLabel}
      className={cn(
        "h-8 w-16 text-right text-base tabular-nums md:h-7 md:text-sm",
        className
      )}
      onChange={(event) => onChange(event.target.value)}
    />
  );
}

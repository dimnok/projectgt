"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import type { WorkHour } from "@/features/works/types/work.types";
import { WorkHourForm } from "@/features/works/ui/shared/work-hour-form";

type WorkHourFormSheetProps = {
  open: boolean;
  workId: string;
  objectId: string;
  existingHours: WorkHour[];
  hour?: WorkHour | null;
  onOpenChange: (open: boolean) => void;
};

export function WorkHourFormSheet({
  open,
  workId,
  objectId,
  existingHours,
  hour = null,
  onOpenChange,
}: WorkHourFormSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <WorkHourForm
          key={hour?.id ?? "new"}
          layout="sheet"
          workId={workId}
          objectId={objectId}
          existingHours={existingHours}
          initial={hour}
          onCancel={() => onOpenChange(false)}
        />
      ) : null}
    </MobileSheet>
  );
}

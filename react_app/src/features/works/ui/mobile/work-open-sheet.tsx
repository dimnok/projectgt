"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import { WorkOpenForm } from "@/features/works/ui/shared/work-open-form";
import type { Work } from "@/features/works/types/work.types";

type WorkOpenSheetProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onOpened: (work: Work) => void;
};

export function WorkOpenSheet({
  open,
  onOpenChange,
  onOpened,
}: WorkOpenSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <WorkOpenForm
          layout="sheet"
          onCancel={() => onOpenChange(false)}
          onOpened={(work) => {
            onOpenChange(false);
            onOpened(work);
          }}
        />
      ) : null}
    </MobileSheet>
  );
}

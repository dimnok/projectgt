"use client";

import { MobileSheet } from "@/components/shared/mobile-sheet-chrome";
import type { WorkItem } from "@/features/works/types/work.types";
import { WorkItemAddForm } from "@/features/works/ui/shared/work-item-add-form";

type WorkItemAddSheetProps = {
  open: boolean;
  workId: string;
  objectId: string;
  existingItems: WorkItem[];
  item?: WorkItem | null;
  onOpenChange: (open: boolean) => void;
};

export function WorkItemAddSheet({
  open,
  workId,
  objectId,
  existingItems,
  item = null,
  onOpenChange,
}: WorkItemAddSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <WorkItemAddForm
          key={item?.id ?? "new"}
          layout="sheet"
          workId={workId}
          objectId={objectId}
          existingItems={existingItems}
          initial={item}
          onCancel={() => onOpenChange(false)}
        />
      ) : null}
    </MobileSheet>
  );
}

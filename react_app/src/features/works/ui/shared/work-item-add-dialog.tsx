"use client";

import { Dialog, DialogContent } from "@/components/ui/dialog";
import type { WorkItem } from "@/features/works/types/work.types";
import { WorkItemAddForm } from "@/features/works/ui/shared/work-item-add-form";

type WorkItemAddDialogProps = {
  open: boolean;
  workId: string;
  objectId: string;
  existingItems: WorkItem[];
  item?: WorkItem | null;
  onOpenChange: (open: boolean) => void;
};

export function WorkItemAddDialog({
  open,
  workId,
  objectId,
  existingItems,
  item = null,
  onOpenChange,
}: WorkItemAddDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="flex! max-h-[min(90vh,52rem)] min-h-0 flex-col overflow-hidden sm:max-w-3xl">
        {open ? (
          <WorkItemAddForm
            key={item?.id ?? "new"}
            layout="dialog"
            workId={workId}
            objectId={objectId}
            existingItems={existingItems}
            initial={item}
            onCancel={() => onOpenChange(false)}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

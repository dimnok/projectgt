"use client";

import { MapPinIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import { usePermissions } from "@/hooks/use-permissions";
import { useWorkMembership } from "@/features/works/hooks/use-work-item-mutations";
import { useWork } from "@/features/works/hooks/use-works";
import { WorkItemsTab } from "@/features/works/ui/shared/work-items-tab";
import { WorkStatusBadge } from "@/features/works/ui/shared/work-status-badge";
import {
  canModifyWorkItems,
  formatRuDate,
} from "@/features/works/utils/work.utils";

export type WorkJournalShiftTarget = {
  workId: string;
  workItemId: string;
};

type WorkJournalShiftDialogProps = {
  target: WorkJournalShiftTarget | null;
  onOpenChange: (open: boolean) => void;
};

export function WorkJournalShiftDialog({
  target,
  onOpenChange,
}: WorkJournalShiftDialogProps) {
  const workId = target?.workId ?? null;
  const workQuery = useWork(workId);
  const membershipQuery = useWorkMembership();
  const { can } = usePermissions();
  const work = workQuery.data;
  const canModify = work
    ? canModifyWorkItems({
        canUpdate: can("works", "update"),
        userId: membershipQuery.data?.userId ?? null,
        openedBy: work.openedBy,
        status: work.status,
        isSuperAdmin: membershipQuery.data?.isSuperAdmin ?? false,
      })
    : false;

  return (
    <Dialog open={Boolean(target)} onOpenChange={onOpenChange}>
      <DialogContent className="flex h-[90vh] w-[min(94vw,62rem)] flex-col gap-0 overflow-hidden rounded-2xl border border-border/80 p-0 shadow-2xl sm:max-w-5xl">
        <DialogHeader className="shrink-0 bg-muted/25 px-6 pt-5 pb-3 pr-12">
          <DialogTitle>
            {work ? `Смена ${formatRuDate(work.date)}` : "Смена"}
          </DialogTitle>
          <DialogDescription>
            {work ? work.objectName : "Работы выбранной смены"}
          </DialogDescription>
          {work ? (
            <div className="flex flex-wrap items-center gap-2 pt-1">
              <WorkStatusBadge status={work.status} />
              <span className="inline-flex min-w-0 items-center gap-1 text-sm text-muted-foreground">
                <MapPinIcon className="size-3.5 shrink-0" />
                <span className="truncate">{work.objectName}</span>
              </span>
            </div>
          ) : null}
        </DialogHeader>

        <div className="flex min-h-0 flex-1 flex-col overflow-hidden px-6 py-4">
          {!target ? null : workQuery.isLoading ? (
            <div className="flex flex-1 items-center justify-center">
              <Spinner className="size-6" />
            </div>
          ) : workQuery.isError ? (
            <ErrorState
              message={
                workQuery.error instanceof Error
                  ? workQuery.error.message
                  : "Не удалось открыть смену"
              }
            />
          ) : work ? (
            <WorkItemsTab
              workId={work.id}
              objectId={work.objectId}
              canModify={canModify}
              highlightedItemId={target.workItemId}
            />
          ) : (
            <EmptyState
              title="Смена не найдена"
              description="Эту смену нельзя открыть. Обновите журнал и попробуйте снова."
            />
          )}
        </div>

        <div className="flex shrink-0 items-center justify-end border-t border-border/60 bg-muted/20 px-6 py-3.5">
          <DialogClose render={<Button type="button" variant="outline" size="sm" />}>
            Закрыть
          </DialogClose>
        </div>
      </DialogContent>
    </Dialog>
  );
}

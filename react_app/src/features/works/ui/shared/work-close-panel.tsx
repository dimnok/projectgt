"use client";

import { useState } from "react";
import { toast } from "sonner";
import { CheckCircle2Icon, CircleIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import {
  useCloseWork,
  useReopenWork,
} from "@/features/works/hooks/use-open-work";
import { WorkPhotoGallery } from "@/features/works/ui/shared/work-photo-gallery";
import type { Work, WorkHour, WorkItem } from "@/features/works/types/work.types";
import { getWorkCloseChecks } from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorkClosePanelProps = {
  work: Work;
  items: WorkItem[] | undefined;
  hours: WorkHour[] | undefined;
  canModify: boolean;
  canReopen: boolean;
};

export function WorkClosePanel({
  work,
  items,
  hours,
  canModify,
  canReopen,
}: WorkClosePanelProps) {
  const closeMutation = useCloseWork();
  const reopenMutation = useReopenWork();
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [reopenOpen, setReopenOpen] = useState(false);
  const { ready, checks, message } = getWorkCloseChecks(work, items, hours);

  if (work.status === "closed") {
    if (!canReopen) {
      return null;
    }
    return (
      <>
        <Button
          type="button"
          variant="outline"
          className="w-full"
          onClick={() => setReopenOpen(true)}
        >
          Открыть смену
        </Button>
        <ReopenConfirmDialog
          open={reopenOpen}
          isSaving={reopenMutation.isPending}
          onOpenChange={setReopenOpen}
          onConfirm={() => void handleReopen()}
        />
      </>
    );
  }

  if (!items || !hours) {
    return null;
  }

  async function handleClose() {
    try {
      await closeMutation.mutateAsync(work.id);
      toast.success("Смена закрыта");
      setConfirmOpen(false);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось закрыть смену"
      );
    }
  }

  async function handleReopen() {
    try {
      await reopenMutation.mutateAsync(work.id);
      toast.success("Смена снова открыта");
      setReopenOpen(false);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось открыть смену"
      );
    }
  }

  const eveningPhotos = (
    <WorkPhotoGallery
      work={work}
      kind="evening"
      canModify={canModify}
      compact
    />
  );

  if (ready) {
    if (!canModify) {
      return null;
    }
    return (
      <>
        <div className="flex flex-col gap-3">
          <Button
            type="button"
            className="w-full"
            onClick={() => setConfirmOpen(true)}
          >
            Закрыть смену
          </Button>
          {eveningPhotos}
        </div>
        <CloseConfirmDialog
          open={confirmOpen}
          isSaving={closeMutation.isPending}
          onOpenChange={setConfirmOpen}
          onConfirm={() => void handleClose()}
        />
      </>
    );
  }

  return (
    <div className="rounded-xl border border-destructive/20 bg-destructive/5 p-4">
      <p className="mb-3 text-sm font-semibold text-destructive">
        Для закрытия смены:
      </p>
      <ul className="flex flex-col gap-1.5">
        {checks.map((check) => (
          <li key={check.id} className="flex items-center gap-2 text-sm">
            {check.done ? (
              <CheckCircle2Icon className="size-4 text-green-600" />
            ) : (
              <CircleIcon className="size-4 text-destructive" />
            )}
            <span className={cn(!check.done && "text-destructive")}>
              {check.label}
            </span>
          </li>
        ))}
      </ul>
      <div className="mt-3">{eveningPhotos}</div>
      {message ? (
        <p className="mt-2 text-xs italic text-destructive">{message}</p>
      ) : null}
    </div>
  );
}

function CloseConfirmDialog({
  open,
  isSaving,
  onOpenChange,
  onConfirm,
}: {
  open: boolean;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Подтверждение закрытия смены</DialogTitle>
          <DialogDescription>
            После закрытия смены будет невозможно добавлять и менять работы,
            сотрудников и фото. Закрыть смену?
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={isSaving}
            onClick={() => onOpenChange(false)}
          >
            Отмена
          </Button>
          <Button
            type="button"
            variant="destructive"
            disabled={isSaving}
            onClick={onConfirm}
          >
            {isSaving ? <Spinner data-icon="inline-start" /> : null}
            Закрыть смену
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function ReopenConfirmDialog({
  open,
  isSaving,
  onOpenChange,
  onConfirm,
}: {
  open: boolean;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Открыть закрытую смену?</DialogTitle>
          <DialogDescription>
            Смена снова станет открытой. Можно будет менять работы, сотрудников
            и фото.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={isSaving}
            onClick={() => onOpenChange(false)}
          >
            Отмена
          </Button>
          <Button type="button" disabled={isSaving} onClick={onConfirm}>
            {isSaving ? <Spinner data-icon="inline-start" /> : null}
            Открыть смену
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

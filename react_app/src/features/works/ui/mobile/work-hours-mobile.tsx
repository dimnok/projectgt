"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";
import { ClockIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/ui/spinner";
import { useWorkHours } from "@/features/works/hooks/use-works";
import { useWorkHoursMassEdit } from "@/features/works/hooks/use-work-hours-mass-edit";
import {
  useDeleteWorkHour,
  useUpdateWorkHoursBulk,
} from "@/features/works/hooks/use-work-item-mutations";
import type { WorkHour } from "@/features/works/types/work.types";
import { SwipeEditDeleteRow } from "@/features/works/ui/mobile/swipe-edit-delete-row";
import { WorkHourDeleteDialog } from "@/features/works/ui/shared/work-hour-delete-dialog";
import { WorkHourDraftInput } from "@/features/works/ui/shared/work-hour-draft-input";
import { WorkHourFormSheet } from "@/features/works/ui/mobile/work-hour-form-sheet";
import { WorkHourPresets } from "@/features/works/ui/shared/work-hour-presets";
import { filterWorkHours, formatQuantity } from "@/features/works/utils/work.utils";
import { hoursDraftFromValue } from "@/features/works/utils/work-hours-mass-edit";

type WorkHoursMobileProps = {
  workId: string;
  objectId: string;
  search?: string;
  canModify?: boolean;
};

export function WorkHoursMobile({
  workId,
  objectId,
  search = "",
  canModify = false,
}: WorkHoursMobileProps) {
  const { data, isLoading, isError, error } = useWorkHours(workId);
  const deleteHour = useDeleteWorkHour(workId);
  const saveHours = useUpdateWorkHoursBulk(workId);
  const [hourToEdit, setHourToEdit] = useState<WorkHour | null>(null);
  const [hourToDelete, setHourToDelete] = useState<WorkHour | null>(null);
  const allHours = useMemo(() => data ?? [], [data]);
  const hours = useMemo(
    () => filterWorkHours(allHours, search),
    [allHours, search]
  );
  const massEdit = useWorkHoursMassEdit(allHours);

  async function handleDelete() {
    if (!hourToDelete) {
      return;
    }
    try {
      await deleteHour.mutateAsync(hourToDelete.id);
      toast.success("Сотрудник удалён из смены");
      setHourToDelete(null);
    } catch (deleteError) {
      toast.error(
        deleteError instanceof Error
          ? deleteError.message
          : "Не удалось удалить сотрудника"
      );
    }
  }

  async function handleSaveHours() {
    if (massEdit.hasInvalidDrafts()) {
      toast.error("Проверьте часы — можно только числа, не меньше нуля");
      return;
    }
    const updates = massEdit.changes();
    try {
      if (updates.length > 0) {
        await saveHours.mutateAsync(updates);
        toast.success(
          updates.length === 1
            ? "Часы сохранены"
            : `Часы сохранены · ${updates.length}`
        );
      }
      massEdit.exitMassEdit();
    } catch (saveError) {
      toast.error(
        saveError instanceof Error
          ? saveError.message
          : "Не удалось сохранить часы"
      );
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        <div className="flex flex-col gap-2">
          <Skeleton className="h-20 w-full" />
          <Skeleton className="h-20 w-full" />
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        <ErrorState
          message={error instanceof Error ? error.message : "Неизвестная ошибка"}
        />
      </div>
    );
  }

  if (allHours.length === 0) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        <EmptyState
          title="Сотрудников нет"
          description={
            canModify
              ? "Добавьте людей кнопкой «+» выше."
              : "В эту смену ещё не добавлены люди."
          }
        />
      </div>
    );
  }

  if (hours.length === 0) {
    return (
      <div className="min-h-0 flex-1 overflow-y-auto px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        <EmptyState
          title="Ничего не найдено"
          description="Измените поисковый запрос."
        />
      </div>
    );
  }

  const saving = saveHours.isPending;

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <ul className="flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto overscroll-y-contain px-4 pt-3 pb-3">
        {hours.map((row) => (
          <li key={row.id}>
            <SwipeEditDeleteRow
              disabled={!canModify}
              editLabel="Изменить"
              deleteLabel="Удалить"
              onEdit={() => setHourToEdit(row)}
              onDelete={() => setHourToDelete(row)}
            >
              <Card
                size="sm"
                className={canModify ? "shadow-none ring-0" : "shadow-float"}
              >
                <CardContent className="flex items-start gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium">{row.employeeName}</p>
                    {row.comment?.trim() ? (
                      <p className="mt-1 text-xs text-muted-foreground">
                        {row.comment.trim()}
                      </p>
                    ) : null}
                  </div>
                  {massEdit.isMassEdit && canModify ? (
                    <WorkHourDraftInput
                      value={
                        massEdit.drafts[row.id] ??
                        hoursDraftFromValue(row.hours)
                      }
                      disabled={saving}
                      className="shrink-0"
                      aria-label={`Часы ${row.employeeName}`}
                      onChange={(value) => massEdit.setDraft(row.id, value)}
                    />
                  ) : (
                    <p className="shrink-0 text-sm font-medium tabular-nums">
                      {formatQuantity(row.hours)} ч
                    </p>
                  )}
                </CardContent>
              </Card>
            </SwipeEditDeleteRow>
          </li>
        ))}
      </ul>
      {canModify ? (
        <div className="shrink-0 border-t bg-background px-4 py-2 pb-[max(0.5rem,env(safe-area-inset-bottom))]">
          <div className="flex items-center gap-2">
          <WorkHourPresets
            selected={massEdit.selectedPreset}
            disabled={saving}
            onSelect={massEdit.applyPreset}
          />
          {massEdit.isMassEdit ? (
            <Button
              type="button"
              className="ml-auto shrink-0"
              disabled={saving}
              onClick={() => void handleSaveHours()}
            >
              {saving ? <Spinner data-icon="inline-start" /> : null}
              Сохранить
            </Button>
          ) : (
            <Button
              type="button"
              variant="outline"
              size="icon"
              className="ml-auto shrink-0"
              aria-label="Править часы в списке"
              onClick={massEdit.enterMassEdit}
            >
              <ClockIcon />
            </Button>
          )}
          </div>
        </div>
      ) : (
        <div className="shrink-0 pb-[max(0.75rem,env(safe-area-inset-bottom))]" />
      )}
      <WorkHourFormSheet
        open={Boolean(hourToEdit)}
        workId={workId}
        objectId={objectId}
        existingHours={allHours}
        hour={hourToEdit}
        onOpenChange={(open) => {
          if (!open) {
            setHourToEdit(null);
          }
        }}
      />
      <WorkHourDeleteDialog
        hour={hourToDelete}
        isDeleting={deleteHour.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setHourToDelete(null);
          }
        }}
        onConfirm={() => {
          void handleDelete();
        }}
      />
    </div>
  );
}

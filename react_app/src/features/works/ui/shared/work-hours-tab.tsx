"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";
import { ClockIcon, PencilIcon, Trash2Icon } from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/ui/spinner";
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useWorkHours } from "@/features/works/hooks/use-works";
import { useWorkHoursMassEdit } from "@/features/works/hooks/use-work-hours-mass-edit";
import {
  useDeleteWorkHour,
  useUpdateWorkHoursBulk,
} from "@/features/works/hooks/use-work-item-mutations";
import type { WorkHour } from "@/features/works/types/work.types";
import { WorkHourDeleteDialog } from "@/features/works/ui/shared/work-hour-delete-dialog";
import { WorkHourDraftInput } from "@/features/works/ui/shared/work-hour-draft-input";
import { WorkHourFormDialog } from "@/features/works/ui/shared/work-hour-form-dialog";
import { WorkHourPresets } from "@/features/works/ui/shared/work-hour-presets";
import { filterWorkHours, formatQuantity } from "@/features/works/utils/work.utils";
import { hoursDraftFromValue } from "@/features/works/utils/work-hours-mass-edit";

type WorkHoursTabProps = {
  workId: string;
  objectId: string;
  search?: string;
  canModify?: boolean;
};

export function WorkHoursTab({
  workId,
  objectId,
  search = "",
  canModify = false,
}: WorkHoursTabProps) {
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
    return <Skeleton className="h-48 w-full" />;
  }

  if (isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  if (allHours.length === 0) {
    return (
      <EmptyState
        title="Сотрудников нет"
        description={
          canModify
            ? "Добавьте людей кнопкой «+» в шапке."
            : "В эту смену ещё не добавлены люди."
        }
      />
    );
  }

  if (hours.length === 0) {
    return (
      <EmptyState
        title="Ничего не найдено"
        description="Измените поисковый запрос."
      />
    );
  }

  const saving = saveHours.isPending;

  return (
    <>
      {canModify ? (
        <div className="mb-2 flex flex-wrap items-center justify-between gap-2">
          <WorkHourPresets
            selected={massEdit.selectedPreset}
            disabled={saving}
            onSelect={massEdit.applyPreset}
          />
          {massEdit.isMassEdit ? (
            <Button
              type="button"
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
              aria-label="Править часы в списке"
              onClick={massEdit.enterMassEdit}
            >
              <ClockIcon data-icon="inline-start" />
              Часы
            </Button>
          )}
        </div>
      ) : null}
      <div className="overflow-hidden rounded-xl border border-border/80 bg-card">
        <Table>
          <TableCaption className="sr-only">Часы сотрудников смены</TableCaption>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead>Сотрудник</TableHead>
              <TableHead>Должность</TableHead>
              <TableHead className="text-right">Часы</TableHead>
              <TableHead>Комментарий</TableHead>
              {canModify ? (
                <TableHead className="w-16">
                  <span className="sr-only">Действия</span>
                </TableHead>
              ) : null}
            </TableRow>
          </TableHeader>
          <TableBody>
            {hours.map((row) => {
              const initials = row.employeeName
                .split(" ")
                .slice(0, 2)
                .map((part) => part.charAt(0))
                .join("");

              return (
                <TableRow key={row.id}>
                  <TableCell>
                    <div className="flex min-w-0 items-center gap-2">
                      <Avatar size="sm">
                        {row.employeePhotoUrl ? (
                          <AvatarImage
                            src={row.employeePhotoUrl}
                            alt={row.employeeName}
                          />
                        ) : null}
                        <AvatarFallback>{initials}</AvatarFallback>
                      </Avatar>
                      <span className="min-w-0 truncate font-medium">
                        {row.employeeName}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    {row.employeePosition || (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                  <TableCell className="text-right">
                    {massEdit.isMassEdit && canModify ? (
                      <WorkHourDraftInput
                        value={
                          massEdit.drafts[row.id] ??
                          hoursDraftFromValue(row.hours)
                        }
                        disabled={saving}
                        className="ml-auto"
                        aria-label={`Часы ${row.employeeName}`}
                        onChange={(value) => massEdit.setDraft(row.id, value)}
                      />
                    ) : (
                      <span className="tabular-nums">
                        {formatQuantity(row.hours)}
                      </span>
                    )}
                  </TableCell>
                  <TableCell>
                    {row.comment?.trim() || (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </TableCell>
                  {canModify ? (
                    <TableCell>
                      <div className="flex items-center justify-end gap-0.5">
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-xs"
                          aria-label={`Изменить ${row.employeeName}`}
                          onClick={() => setHourToEdit(row)}
                        >
                          <PencilIcon />
                        </Button>
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-xs"
                          aria-label={`Удалить ${row.employeeName}`}
                          onClick={() => setHourToDelete(row)}
                        >
                          <Trash2Icon />
                        </Button>
                      </div>
                    </TableCell>
                  ) : null}
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </div>
      <WorkHourFormDialog
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
    </>
  );
}

"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useWorkItems } from "@/features/works/hooks/use-works";
import {
  useDeleteWorkItem,
  useUpdateWorkItemQuantity,
} from "@/features/works/hooks/use-work-item-mutations";
import type { WorkItem } from "@/features/works/types/work.types";
import { SwipeEditDeleteRow } from "@/features/works/ui/mobile/swipe-edit-delete-row";
import { WorkItemAddSheet } from "@/features/works/ui/mobile/work-item-add-sheet";
import { WorkItemDeleteDialog } from "@/features/works/ui/shared/work-item-delete-dialog";
import { WorkItemQuantityCell } from "@/features/works/ui/shared/work-item-quantity-cell";
import {
  filterWorkItems,
  formatCurrency,
  type WorkItemPlaceFilter,
} from "@/features/works/utils/work.utils";

type WorkItemsMobileProps = {
  workId: string;
  objectId: string;
  search?: string;
  placeFilter?: WorkItemPlaceFilter;
  canModify?: boolean;
};

function placeLine(item: WorkItem): string | null {
  const parts = [item.system.trim(), item.section.trim(), item.floor.trim()].filter(
    Boolean
  );
  return parts.length > 0 ? parts.join(" · ") : null;
}

export function WorkItemsMobile({
  workId,
  objectId,
  search = "",
  placeFilter,
  canModify = false,
}: WorkItemsMobileProps) {
  const { data, isLoading, isError, error } = useWorkItems(workId);
  const updateQuantity = useUpdateWorkItemQuantity(workId);
  const deleteItem = useDeleteWorkItem(workId);
  const [itemToDelete, setItemToDelete] = useState<WorkItem | null>(null);
  const [itemToEdit, setItemToEdit] = useState<WorkItem | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);

  const allItems = useMemo(() => data ?? [], [data]);
  const items = useMemo(
    () => filterWorkItems(allItems, search, placeFilter),
    [allItems, search, placeFilter]
  );
  const hasPlaceFilter = Boolean(
    placeFilter?.system || placeFilter?.section || placeFilter?.floor
  );
  const totalAmount = useMemo(
    () => items.reduce((sum, item) => sum + item.total, 0),
    [items]
  );

  async function handleQuantitySave(item: WorkItem, quantity: number) {
    setSavingId(item.id);
    try {
      await updateQuantity.mutateAsync({ itemId: item.id, quantity });
    } catch (saveError) {
      toast.error(
        saveError instanceof Error
          ? saveError.message
          : "Не удалось сохранить количество"
      );
    } finally {
      setSavingId(null);
    }
  }

  async function handleDelete() {
    if (!itemToDelete) {
      return;
    }
    try {
      await deleteItem.mutateAsync(itemToDelete.id);
      toast.success("Работа удалена");
      setItemToDelete(null);
    } catch (deleteError) {
      toast.error(
        deleteError instanceof Error
          ? deleteError.message
          : "Не удалось удалить работу"
      );
    }
  }

  if (isLoading) {
    return (
      <div className="flex flex-col gap-2">
        <Skeleton className="h-24 w-full" />
        <Skeleton className="h-24 w-full" />
      </div>
    );
  }

  if (isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  if ((data ?? []).length === 0) {
    return (
      <EmptyState
        title="Работ нет"
        description={
          canModify
            ? "Добавьте позиции кнопкой «+» выше."
            : "В эту смену ещё не добавлены позиции."
        }
      />
    );
  }

  if (items.length === 0) {
    return (
      <EmptyState
        title="Ничего не найдено"
        description={
          hasPlaceFilter
            ? "Измените фильтр или поисковый запрос."
            : "Измените поисковый запрос."
        }
      />
    );
  }

  return (
    <>
      <ul className="flex flex-col gap-2">
        {items.map((item) => {
          const details = placeLine(item);
          const inAct = Boolean(item.contractActId);
          const canEditRow = canModify && !inAct;

          return (
            <li key={item.id}>
              <SwipeEditDeleteRow
                disabled={!canEditRow}
                editLabel="Изменить"
                deleteLabel="Удалить"
                onEdit={() => setItemToEdit(item)}
                onDelete={() => setItemToDelete(item)}
              >
                <Card
                  size="sm"
                  className={canEditRow ? "shadow-none ring-0" : "shadow-float"}
                >
                  <CardContent className="flex flex-col gap-1 text-xs">
                    <p className="text-[11px] tabular-nums text-muted-foreground">
                      № {item.number ?? "—"}
                    </p>
                    <div className="flex items-start justify-between gap-3">
                      <p className="min-w-0 font-medium leading-snug">
                        {item.name}
                      </p>
                      <p className="flex shrink-0 items-baseline gap-1 pt-px font-medium tabular-nums">
                        <span className="inline-flex [&_button]:ml-0 [&_input]:ml-0">
                          <WorkItemQuantityCell
                            item={item}
                            canEdit={canEditRow}
                            isSaving={savingId === item.id}
                            onSave={(quantity) =>
                              handleQuantitySave(item, quantity)
                            }
                          />
                        </span>
                        <span className="font-normal text-muted-foreground">
                          {item.unit.trim() || "—"}
                        </span>
                      </p>
                    </div>
                    {details ? (
                      <p className="text-[11px] text-muted-foreground">{details}</p>
                    ) : null}
                    {inAct ? (
                      <p className="text-[11px] text-muted-foreground">
                        В акте, правка недоступна
                      </p>
                    ) : null}
                    <div className="flex items-center justify-between gap-3">
                      <span className="min-w-0 truncate text-[11px] text-muted-foreground">
                        {item.contractorName ?? "Свои"}
                      </span>
                      <span className="shrink-0 font-medium tabular-nums">
                        {formatCurrency(item.total)}
                      </span>
                    </div>
                  </CardContent>
                </Card>
              </SwipeEditDeleteRow>
            </li>
          );
        })}
      </ul>
      <p className="px-1 pt-2 text-sm font-medium">
        Итого · {items.length} поз. · {formatCurrency(totalAmount)}
      </p>
      <WorkItemAddSheet
        open={Boolean(itemToEdit)}
        workId={workId}
        objectId={objectId}
        existingItems={data ?? []}
        item={itemToEdit}
        onOpenChange={(open) => {
          if (!open) {
            setItemToEdit(null);
          }
        }}
      />
      <WorkItemDeleteDialog
        item={itemToDelete}
        isDeleting={deleteItem.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setItemToDelete(null);
          }
        }}
        onConfirm={() => {
          void handleDelete();
        }}
      />
    </>
  );
}

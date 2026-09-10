"use client";

import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import { PencilIcon, Trash2Icon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useWorkItems } from "@/features/works/hooks/use-works";
import {
  useDeleteWorkItem,
  useUpdateWorkItemQuantity,
} from "@/features/works/hooks/use-work-item-mutations";
import type { WorkItem } from "@/features/works/types/work.types";
import { WorkItemAddDialog } from "@/features/works/ui/shared/work-item-add-dialog";
import { WorkItemDeleteDialog } from "@/features/works/ui/shared/work-item-delete-dialog";
import { WorkItemQuantityCell } from "@/features/works/ui/shared/work-item-quantity-cell";
import {
  filterWorkItems,
  formatCurrency,
  type WorkItemPlaceFilter,
} from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorkItemsTabProps = {
  workId: string;
  objectId: string;
  search?: string;
  placeFilter?: WorkItemPlaceFilter;
  canModify?: boolean;
  highlightedItemId?: string | null;
};

const TABLE_MIN_WIDTH = 640;

const col = {
  number: "w-14 min-w-14",
  name: "min-w-[280px] whitespace-normal",
  qty: "min-w-24 text-right",
  unit: "min-w-14",
  amount: "min-w-32 whitespace-normal text-right",
  actions: "w-16 min-w-16",
} as const;

const headClass =
  "sticky top-0 z-10 h-8 border-b border-border/80 bg-muted px-3 py-1.5 text-xs font-semibold text-foreground/75";

const cellClass = "border-b border-border/50 px-3 py-1 align-top leading-snug";

function formatWorkItemDetails(item: WorkItem): string | null {
  const parts = [item.system.trim(), item.section.trim(), item.floor.trim()].filter(
    Boolean
  );
  return parts.length > 0 ? parts.join(" · ") : null;
}

export function WorkItemsTab({
  workId,
  objectId,
  search = "",
  placeFilter,
  canModify = false,
  highlightedItemId = null,
}: WorkItemsTabProps) {
  const { data, isLoading, isError, error } = useWorkItems(workId);
  const updateQuantity = useUpdateWorkItemQuantity(workId);
  const deleteItem = useDeleteWorkItem(workId);
  const [itemToDelete, setItemToDelete] = useState<WorkItem | null>(null);
  const [itemToEdit, setItemToEdit] = useState<WorkItem | null>(null);
  const [savingId, setSavingId] = useState<string | null>(null);

  const items = useMemo(
    () => filterWorkItems(data ?? [], search, placeFilter),
    [data, search, placeFilter]
  );
  const hasPlaceFilter = Boolean(
    placeFilter?.system || placeFilter?.section || placeFilter?.floor
  );
  const totalAmount = useMemo(
    () => items.reduce((sum, item) => sum + item.total, 0),
    [items]
  );

  useEffect(() => {
    if (!highlightedItemId) {
      return;
    }
    const frame = window.requestAnimationFrame(() => {
      document
        .getElementById(`work-item-${highlightedItemId}`)
        ?.scrollIntoView({ block: "center", behavior: "smooth" });
    });
    return () => window.cancelAnimationFrame(frame);
  }, [highlightedItemId, items]);

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
    return <Skeleton className="h-48 w-full" />;
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
            ? "Добавьте позиции кнопкой «+» в шапке."
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
      <div className="flex h-full min-h-0 flex-1 flex-col overflow-hidden rounded-xl border border-border/80">
        <div className="min-h-0 flex-1 overflow-auto">
          <table
            aria-label="Работы смены"
            className="w-full border-separate border-spacing-0 text-sm"
            style={{ minWidth: TABLE_MIN_WIDTH }}
          >
            <TableHeader className="sticky top-0 z-10">
              <TableRow className="hover:bg-transparent">
                <TableHead className={cn(headClass, col.number)}>№</TableHead>
                <TableHead className={cn(headClass, col.name)}>
                  Наименование
                </TableHead>
                <TableHead className={cn(headClass, col.qty)}>Кол-во</TableHead>
                <TableHead className={cn(headClass, col.unit)}>Ед.</TableHead>
                <TableHead className={cn(headClass, col.amount)}>Сумма</TableHead>
                {canModify ? (
                  <TableHead className={cn(headClass, col.actions)}>
                    <span className="sr-only">Действия</span>
                  </TableHead>
                ) : null}
              </TableRow>
            </TableHeader>
            <TableBody>
              {items.map((item) => (
                <WorkItemRow
                  key={item.id}
                  item={item}
                  canModify={canModify}
                  isHighlighted={item.id === highlightedItemId}
                  isSaving={savingId === item.id}
                  onQuantitySave={(quantity) =>
                    handleQuantitySave(item, quantity)
                  }
                  onEdit={() => setItemToEdit(item)}
                  onDelete={() => setItemToDelete(item)}
                />
              ))}
            </TableBody>
            <TableFooter className="sticky bottom-0 z-10 bg-muted">
              <TableRow className="hover:bg-transparent">
                <TableCell
                  colSpan={4}
                  className="border-t border-border/80 bg-muted px-3 py-1.5 font-medium"
                >
                  Итого · {items.length} поз.
                </TableCell>
                <TableCell
                  className={cn(
                    "border-t border-border/80 bg-muted px-3 py-1.5 font-medium tabular-nums",
                    col.amount
                  )}
                >
                  {formatCurrency(totalAmount)}
                </TableCell>
                {canModify ? (
                  <TableCell className="border-t border-border/80 bg-muted" />
                ) : null}
              </TableRow>
            </TableFooter>
          </table>
        </div>
      </div>
      <WorkItemAddDialog
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

function WorkItemRow({
  item,
  canModify,
  isHighlighted,
  isSaving,
  onQuantitySave,
  onEdit,
  onDelete,
}: {
  item: WorkItem;
  canModify: boolean;
  isHighlighted: boolean;
  isSaving: boolean;
  onQuantitySave: (quantity: number) => Promise<void>;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const itemDetails = formatWorkItemDetails(item);
  const inAct = Boolean(item.contractActId);
  const canEditRow = canModify && !inAct;

  return (
    <TableRow
      id={`work-item-${item.id}`}
      className={cn(
        "hover:bg-muted/40",
        isHighlighted && "bg-primary/10 hover:bg-primary/15"
      )}
    >
      <TableCell
        className={cn(
          cellClass,
          col.number,
          "tabular-nums text-muted-foreground"
        )}
      >
        {item.number ?? "—"}
      </TableCell>
      <TableCell className={cn(cellClass, col.name)}>
        <span className="block font-medium">{item.name}</span>
        {itemDetails ? (
          <span className="block text-[11px] leading-tight text-muted-foreground">
            {itemDetails}
          </span>
        ) : null}
        {inAct ? (
          <span className="block text-[11px] text-muted-foreground">
            В акте, правка недоступна
          </span>
        ) : null}
      </TableCell>
      <TableCell className={cn(cellClass, col.qty)}>
        <WorkItemQuantityCell
          item={item}
          canEdit={canEditRow}
          isSaving={isSaving}
          onSave={onQuantitySave}
        />
      </TableCell>
      <TableCell className={cn(cellClass, col.unit)}>
        {item.unit.trim() || "—"}
      </TableCell>
      <TableCell className={cn(cellClass, col.amount)}>
        <span className="block tabular-nums">{formatCurrency(item.total)}</span>
        <span className="block truncate text-[11px] leading-tight text-muted-foreground">
          {item.contractorName ?? "Свои"}
        </span>
      </TableCell>
      {canModify ? (
        <TableCell className={cn(cellClass, col.actions)}>
          <div className="flex items-center justify-end gap-0.5">
            <Button
              type="button"
              variant="ghost"
              size="icon-xs"
              disabled={!canEditRow}
              aria-label={`Изменить ${item.name}`}
              onClick={onEdit}
            >
              <PencilIcon />
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="icon-xs"
              disabled={!canEditRow}
              aria-label={`Удалить ${item.name}`}
              onClick={onDelete}
            >
              <Trash2Icon />
            </Button>
          </div>
        </TableCell>
      ) : null}
    </TableRow>
  );
}

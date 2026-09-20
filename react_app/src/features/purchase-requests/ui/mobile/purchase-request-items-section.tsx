"use client";

import { PlusIcon, Trash2Icon } from "lucide-react";

import { Button } from "@/components/ui/button";
import type { PurchaseRequestItem } from "@/features/purchase-requests/types/purchase-request.types";
import { formatQuantity } from "@/features/purchase-requests/utils/format";
import {
  EmptySection,
  SectionTitle,
} from "@/features/purchase-requests/ui/mobile/purchase-request-section";

type PurchaseRequestItemsSectionProps = {
  items: PurchaseRequestItem[];
  /** Можно добавлять и удалять позиции. */
  canEdit: boolean;
  /** Операция с позициями выполняется. */
  isPending: boolean;
  onAdd: () => void;
  onDelete: (item: PurchaseRequestItem) => void;
};

/** Позиции заявки: список карточками и добавление. */
export function PurchaseRequestItemsSection({
  items,
  canEdit,
  isPending,
  onAdd,
  onDelete,
}: PurchaseRequestItemsSectionProps) {
  return (
    <section className="flex flex-col gap-2">
      <SectionTitle
        title="Позиции"
        count={items.length}
        action={
          canEdit ? (
            <Button
              type="button"
              size="sm"
              variant="ghost"
              onClick={onAdd}
            >
              <PlusIcon data-icon="inline-start" />
              Добавить
            </Button>
          ) : null
        }
      />

      {items.length === 0 ? (
        <EmptySection text="Позиций пока нет" />
      ) : (
        items.map((item) => (
          <div
            key={item.id}
            className="flex items-start justify-between gap-3 rounded-xl border border-border/60 p-3"
          >
            <div className="min-w-0 flex-1">
              <p className="text-sm font-medium">{item.name}</p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                {formatQuantity(item.quantity)} {item.unit}
                {item.article ? ` · арт. ${item.article}` : ""}
              </p>
            </div>
            {canEdit ? (
              <Button
                type="button"
                size="icon"
                variant="ghost"
                className="shrink-0 text-destructive hover:text-destructive"
                aria-label="Удалить позицию"
                disabled={isPending}
                onClick={() => onDelete(item)}
              >
                <Trash2Icon />
              </Button>
            ) : null}
          </div>
        ))
      )}
    </section>
  );
}

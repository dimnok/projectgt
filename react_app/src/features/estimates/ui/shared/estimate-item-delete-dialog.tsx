"use client";

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
import type { EstimateItem } from "@/features/estimates/types/estimate.types";
import { formatCurrency, formatQuantity } from "@/features/estimates/utils/estimate.utils";

type EstimateItemDeleteDialogProps = {
  item: EstimateItem | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function EstimateItemDeleteDialog({
  item,
  isDeleting,
  onOpenChange,
  onConfirm,
}: EstimateItemDeleteDialogProps) {
  return (
    <Dialog open={Boolean(item)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить позицию сметы?</DialogTitle>
          <DialogDescription>
            {item ? (
              <span className="flex flex-col gap-1.5">
                <span>
                  Позиция {item.number ? `№ ${item.number} ` : ""}«<strong>{item.name}</strong>» будет удалена.
                </span>
                <span className="text-xs text-muted-foreground">
                  Количество: {formatQuantity(item.quantity)} {item.unit} · Сумма: {formatCurrency(item.total)}
                </span>
                <span className="text-xs text-destructive font-medium">
                  Это действие нельзя отменить.
                </span>
              </span>
            ) : (
              ""
            )}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={isDeleting}
            onClick={() => onOpenChange(false)}
          >
            Отмена
          </Button>
          <Button
            type="button"
            variant="destructive"
            disabled={isDeleting}
            onClick={onConfirm}
          >
            {isDeleting ? <Spinner data-icon="inline-start" /> : null}
            {isDeleting ? "Удаление..." : "Удалить позицию"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

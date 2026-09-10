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
import type { EstimateFile } from "@/features/estimates/types/estimate.types";
import { formatCurrency, formatQuantity } from "@/features/estimates/utils/estimate.utils";

type EstimateFileDeleteDialogProps = {
  file: EstimateFile | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function EstimateFileDeleteDialog({
  file,
  isDeleting,
  onOpenChange,
  onConfirm,
}: EstimateFileDeleteDialogProps) {
  return (
    <Dialog open={Boolean(file)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить смету?</DialogTitle>
          <DialogDescription>
            {file ? (
              <span className="flex flex-col gap-1">
                <span>
                  Смета «<strong>{file.estimateTitle}</strong>» будет полностью удалена из договора.
                </span>
                <span className="text-xs text-muted-foreground">
                  Позиций к удалению: {formatQuantity(file.itemsCount)} на общую сумму {formatCurrency(file.total)}.
                </span>
                <span className="text-xs text-destructive font-medium mt-1">
                  Это действие необратимо.
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
            {isDeleting ? "Удаление..." : "Удалить смету"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

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
import type { Contractor } from "@/features/contractors/types/contractor.types";

type ContractorDeleteDialogProps = {
  contractor: Contractor | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function ContractorDeleteDialog({
  contractor,
  isDeleting,
  onOpenChange,
  onConfirm,
}: ContractorDeleteDialogProps) {
  return (
    <Dialog open={Boolean(contractor)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить контрагента?</DialogTitle>
          <DialogDescription>
            {contractor
              ? `Контрагент «${contractor.shortName}» будет удалён. Это действие нельзя отменить.`
              : ""}
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
            Удалить
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

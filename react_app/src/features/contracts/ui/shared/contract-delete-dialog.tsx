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
import type { Contract } from "@/features/contracts/types/contract.types";

type ContractDeleteDialogProps = {
  contract: Contract | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function ContractDeleteDialog({
  contract,
  isDeleting,
  onOpenChange,
  onConfirm,
}: ContractDeleteDialogProps) {
  return (
    <Dialog open={Boolean(contract)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить договор?</DialogTitle>
          <DialogDescription>
            {contract
              ? `Договор № ${contract.number} будет удалён. Это действие нельзя отменить.`
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

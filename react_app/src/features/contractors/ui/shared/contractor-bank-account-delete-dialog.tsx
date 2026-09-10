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
import type { ContractorBankAccount } from "@/features/contractors/types/contractor.types";

type ContractorBankAccountDeleteDialogProps = {
  account: ContractorBankAccount | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function ContractorBankAccountDeleteDialog({
  account,
  isDeleting,
  onOpenChange,
  onConfirm,
}: ContractorBankAccountDeleteDialogProps) {
  return (
    <Dialog open={Boolean(account)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить счёт?</DialogTitle>
          <DialogDescription>
            {account
              ? `Вы уверены, что хотите удалить счёт в банке «${account.bankName}»?`
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

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
import type { CompanyBankAccount } from "@/features/company/types/company.types";

type CompanyBankAccountDeleteDialogProps = {
  account: CompanyBankAccount | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function CompanyBankAccountDeleteDialog({
  account,
  isDeleting,
  onOpenChange,
  onConfirm,
}: CompanyBankAccountDeleteDialogProps) {
  return (
    <Dialog open={Boolean(account)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить счёт?</DialogTitle>
          <DialogDescription>
            {account
              ? `Счёт «${account.bankName}» будет удалён без возможности восстановления.`
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

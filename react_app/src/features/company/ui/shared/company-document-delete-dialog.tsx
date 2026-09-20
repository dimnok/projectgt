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
import type { CompanyDocument } from "@/features/company/types/company.types";

type CompanyDocumentDeleteDialogProps = {
  document: CompanyDocument | null;
  isDeleting: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

export function CompanyDocumentDeleteDialog({
  document,
  isDeleting,
  onOpenChange,
  onConfirm,
}: CompanyDocumentDeleteDialogProps) {
  return (
    <Dialog open={Boolean(document)} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Удалить документ?</DialogTitle>
          <DialogDescription>
            {document
              ? `«${document.title}» будет удалён без возможности восстановления.`
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

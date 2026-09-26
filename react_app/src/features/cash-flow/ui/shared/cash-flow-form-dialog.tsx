"use client";

import { TrashIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { Contract } from "@/features/contracts/types/contract.types";
import type {
  CashFlowCategory,
  CashFlowDraft,
  CashFlowPickItem,
  CashFlowTransaction,
} from "@/features/cash-flow/types/cash-flow.types";
import { CashFlowForm } from "@/features/cash-flow/ui/shared/cash-flow-form";

type CashFlowFormDialogProps = {
  open: boolean;
  transaction?: CashFlowTransaction | null;
  categories: CashFlowCategory[];
  objects: CashFlowPickItem[];
  contractors: CashFlowPickItem[];
  contracts: Contract[];
  isSaving: boolean;
  canDelete: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (draft: CashFlowDraft) => void;
  onDelete: () => void;
};

/** Окно создания и правки операции ДДС. */
export function CashFlowFormDialog({
  open,
  transaction,
  categories,
  objects,
  contractors,
  contracts,
  isSaving,
  canDelete,
  onOpenChange,
  onSubmit,
  onDelete,
}: CashFlowFormDialogProps) {
  const isNew = !transaction;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(92vh,56rem)] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <div className="flex items-start justify-between gap-3">
            <div className="flex flex-col gap-1.5">
              <DialogTitle>
                {isNew ? "Новая операция" : "Операция"}
              </DialogTitle>
              <DialogDescription>
                Дата и сумма обязательны. Статья, объект, контрагент и договор
                уточняют операцию в аналитике.
              </DialogDescription>
            </div>
            {!isNew && canDelete ? (
              <Button
                type="button"
                variant="ghost"
                size="icon"
                aria-label="Удалить операцию"
                title="Удалить операцию"
                disabled={isSaving}
                onClick={onDelete}
              >
                <TrashIcon className="text-destructive" />
              </Button>
            ) : null}
          </div>
        </DialogHeader>
        <CashFlowForm
          key={transaction?.id ?? "new"}
          transaction={transaction}
          categories={categories}
          objects={objects}
          contractors={contractors}
          contracts={contracts}
          isSaving={isSaving}
          onCancel={() => onOpenChange(false)}
          onSubmit={onSubmit}
        />
      </DialogContent>
    </Dialog>
  );
}

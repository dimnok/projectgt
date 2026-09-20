"use client";

import { useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import type { PurchaseRequestItemDraft } from "@/features/purchase-requests/types/purchase-request.types";
import { parseAmountInput } from "@/features/purchase-requests/utils/amount";

type ItemDialogProps = {
  open: boolean;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (item: PurchaseRequestItemDraft) => void;
};

export function PurchaseRequestItemDialog({
  open,
  isSaving,
  onOpenChange,
  onSubmit,
}: ItemDialogProps) {
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("1");
  const [unit, setUnit] = useState("шт");
  const [article, setArticle] = useState("");

  function reset() {
    setName("");
    setQuantity("1");
    setUnit("шт");
    setArticle("");
  }

  function handleSubmit() {
    const trimmedName = name.trim();
    const qty = parseAmountInput(quantity);
    if (!trimmedName) {
      toast.error("Укажите наименование");
      return;
    }
    if (qty === null || qty <= 0) {
      toast.error("Количество должно быть больше нуля");
      return;
    }
    onSubmit({
      name: trimmedName,
      quantity: qty,
      unit: unit.trim() || "шт",
      article: article.trim() || null,
    });
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!next) {
          reset();
        }
        onOpenChange(next);
      }}
    >
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Позиция заявки</DialogTitle>
          <DialogDescription>
            Наименование и количество обязательны. Артикул можно не заполнять.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-3">
          <Field>
            <FieldLabel htmlFor="pr-item-name">Наименование</FieldLabel>
            <Input
              id="pr-item-name"
              value={name}
              onChange={(event) => setName(event.target.value)}
            />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field>
              <FieldLabel htmlFor="pr-item-qty">Количество</FieldLabel>
              <Input
                id="pr-item-qty"
                value={quantity}
                onChange={(event) => setQuantity(event.target.value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="pr-item-unit">Ед. изм.</FieldLabel>
              <Input
                id="pr-item-unit"
                value={unit}
                onChange={(event) => setUnit(event.target.value)}
              />
            </Field>
          </div>
          <Field>
            <FieldLabel htmlFor="pr-item-article">Артикул</FieldLabel>
            <Input
              id="pr-item-article"
              value={article}
              onChange={(event) => setArticle(event.target.value)}
            />
          </Field>
        </div>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            disabled={isSaving}
            onClick={() => onOpenChange(false)}
          >
            Отмена
          </Button>
          <Button type="button" disabled={isSaving} onClick={handleSubmit}>
            {isSaving ? <Spinner data-icon="inline-start" /> : null}
            Добавить
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

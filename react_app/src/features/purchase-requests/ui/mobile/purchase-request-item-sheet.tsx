"use client";

import { useState } from "react";
import { toast } from "sonner";

import { MobileSheet, MobileSheetBody, MobileSheetChrome } from "@/components/shared/mobile-sheet-chrome";
import { Field, FieldLabel } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import type { PurchaseRequestItemDraft } from "@/features/purchase-requests/types/purchase-request.types";
import { parseItemInput } from "@/features/purchase-requests/utils/items";

type PurchaseRequestItemSheetProps = {
  open: boolean;
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (item: PurchaseRequestItemDraft) => void;
};

/** Добавление позиции заявки (телефон). Правила — общие с остальным модулем. */
export function PurchaseRequestItemSheet({
  open,
  isSaving,
  onOpenChange,
  onSubmit,
}: PurchaseRequestItemSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? <ItemForm isSaving={isSaving} onSubmit={onSubmit} /> : null}
    </MobileSheet>
  );
}

function ItemForm({
  isSaving,
  onSubmit,
}: {
  isSaving: boolean;
  onSubmit: (item: PurchaseRequestItemDraft) => void;
}) {
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("1");
  const [unit, setUnit] = useState("шт");
  const [article, setArticle] = useState("");

  function handleSubmit() {
    const parsed = parseItemInput({ name, quantity, unit, article });
    if (!parsed.ok) {
      toast.error(parsed.error);
      return;
    }
    onSubmit(parsed.draft);
  }

  return (
    <>
      <MobileSheetChrome
        title="Позиция заявки"
        description="Наименование и количество обязательны. Артикул можно не заполнять."
        confirmLabel="Добавить"
        confirmDisabled={isSaving}
        confirmPending={isSaving}
        confirmShowLabelWhenEnabled
        onConfirm={handleSubmit}
      />
      <MobileSheetBody>
        <Field>
          <FieldLabel htmlFor="pr-mobile-item-name">Наименование</FieldLabel>
          <Input
            id="pr-mobile-item-name"
            value={name}
            onChange={(event) => setName(event.target.value)}
          />
        </Field>
        <div className="grid grid-cols-2 gap-2">
          <Field>
            <FieldLabel htmlFor="pr-mobile-item-qty">Количество</FieldLabel>
            <Input
              id="pr-mobile-item-qty"
              inputMode="decimal"
              value={quantity}
              onChange={(event) => setQuantity(event.target.value)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="pr-mobile-item-unit">Ед. изм.</FieldLabel>
            <Input
              id="pr-mobile-item-unit"
              value={unit}
              onChange={(event) => setUnit(event.target.value)}
            />
          </Field>
        </div>
        <Field>
          <FieldLabel htmlFor="pr-mobile-item-article">Артикул</FieldLabel>
          <Input
            id="pr-mobile-item-article"
            value={article}
            onChange={(event) => setArticle(event.target.value)}
          />
        </Field>
      </MobileSheetBody>
    </>
  );
}

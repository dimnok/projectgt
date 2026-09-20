"use client";

import { useState } from "react";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import {
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Spinner } from "@/components/ui/spinner";
import { Textarea } from "@/components/ui/textarea";
import type {
  SettlementPayment,
  SettlementPaymentDraft,
} from "@/features/settlements/types/settlement.types";
import {
  formatAmount,
  parseAmount,
  todayDateInput,
} from "@/features/settlements/utils/settlement.utils";

type SettlementPaymentFormProps = {
  layout: "dialog" | "sheet";
  payment?: SettlementPayment | null;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: SettlementPaymentDraft) => void;
};

/**
 * Форма оплаты: общая для настольного окна и мобильного окна снизу.
 */
export function SettlementPaymentForm({
  layout,
  payment,
  isSaving,
  onCancel,
  onSubmit,
}: SettlementPaymentFormProps) {
  const [draft, setDraft] = useState<SettlementPaymentDraft>(() => ({
    paymentDate: payment?.paymentDate ?? todayDateInput(),
    amount: payment ? formatAmount(payment.amount) : "",
    note: payment?.note ?? "",
  }));
  const [error, setError] = useState<string | null>(null);

  const title = payment ? "Редактировать оплату" : "Новая оплата";
  const description =
    "Оплаты уменьшают остаток и меняют статус счёта автоматически.";

  const enteredAmount = parseAmount(draft.amount);
  const canSave = enteredAmount !== null && enteredAmount > 0;

  function submitDraft() {
    if (!canSave) {
      setError("Укажите сумму оплаты");
      return;
    }
    setError(null);
    onSubmit(draft);
  }

  const fields = (
    <>
      <FieldGroup className="grid gap-3 sm:grid-cols-2">
        <Field data-invalid={Boolean(error)}>
          <FieldLabel htmlFor="payment-amount">Сумма</FieldLabel>
          <Input
            id="payment-amount"
            inputMode="decimal"
            value={draft.amount}
            disabled={isSaving}
            aria-invalid={Boolean(error)}
            placeholder="0,00"
            onChange={(event) =>
              setDraft((current) => ({
                ...current,
                amount: event.target.value,
              }))
            }
          />
          <FieldError>{error}</FieldError>
        </Field>
        <Field>
          <FieldLabel htmlFor="payment-date">Дата оплаты</FieldLabel>
          <Input
            id="payment-date"
            type="date"
            value={draft.paymentDate}
            disabled={isSaving}
            onChange={(event) =>
              setDraft((current) => ({
                ...current,
                paymentDate: event.target.value,
              }))
            }
          />
        </Field>
      </FieldGroup>
      <Field>
        <FieldLabel htmlFor="payment-note">Примечание</FieldLabel>
        <Textarea
          id="payment-note"
          rows={2}
          value={draft.note}
          disabled={isSaving}
          onChange={(event) =>
            setDraft((current) => ({ ...current, note: event.target.value }))
          }
        />
      </Field>
    </>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title={title}
          description={description}
          confirmLabel="Сохранить"
          confirmDisabled={isSaving || !canSave}
          confirmPending={isSaving}
          onConfirm={submitDraft}
        />
        <MobileSheetBody>{fields}</MobileSheetBody>
      </>
    );
  }

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(event) => {
        event.preventDefault();
        submitDraft();
      }}
    >
      <DialogHeader>
        <DialogTitle>{title}</DialogTitle>
        <DialogDescription>{description}</DialogDescription>
      </DialogHeader>
      {fields}
      <DialogFooter>
        <Button
          type="button"
          variant="outline"
          disabled={isSaving}
          onClick={onCancel}
        >
          Отмена
        </Button>
        <Button type="submit" disabled={isSaving}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </form>
  );
}

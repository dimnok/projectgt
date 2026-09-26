"use client";

import { useMemo, useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import type { Contract } from "@/features/contracts/types/contract.types";
import type {
  CashFlowCategory,
  CashFlowDraft,
  CashFlowPickItem,
  CashFlowTransaction,
  CashFlowType,
} from "@/features/cash-flow/types/cash-flow.types";
import {
  cashFlowToDraft,
  emptyCashFlowDraft,
  parseAmount,
} from "@/features/cash-flow/utils/cash-flow.utils";
import { CASH_FLOW_TYPE_OPTIONS } from "@/features/cash-flow/utils/operation-type";

type CashFlowFormProps = {
  transaction?: CashFlowTransaction | null;
  categories: CashFlowCategory[];
  objects: CashFlowPickItem[];
  contractors: CashFlowPickItem[];
  contracts: Contract[];
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: CashFlowDraft) => void;
};

type FormErrors = Partial<Record<"date" | "amount", string>>;

/**
 * Форма операции ДДС.
 *
 * Обязательны дата и сумма: операция без статьи допустима — так приходят
 * строки банковской выписки, и статья подставляется при обработке.
 */
export function CashFlowForm({
  transaction,
  categories,
  objects,
  contractors,
  contracts,
  isSaving,
  onCancel,
  onSubmit,
}: CashFlowFormProps) {
  const [draft, setDraft] = useState<CashFlowDraft>(() =>
    transaction ? cashFlowToDraft(transaction) : emptyCashFlowDraft()
  );
  const [errors, setErrors] = useState<FormErrors>({});
  const isNew = !transaction;

  const categoryItems = useMemo(
    () =>
      categories
        .filter((category) => category.type === draft.type)
        .map((category) => ({ value: category.id, label: category.name })),
    [categories, draft.type]
  );

  const objectItems = objects.map((item) => ({
    value: item.id,
    label: item.label,
  }));
  const contractorItems = contractors.map((item) => ({
    value: item.id,
    label: item.label,
  }));

  const filteredContracts = useMemo(
    () =>
      contracts.filter((contract) => {
        if (draft.objectId && contract.objectId !== draft.objectId) {
          return false;
        }
        if (draft.contractorId && contract.contractorId !== draft.contractorId) {
          return false;
        }
        return true;
      }),
    [contracts, draft.objectId, draft.contractorId]
  );
  const contractItems = filteredContracts.map((contract) => ({
    value: contract.id,
    label: `№${contract.number}`,
  }));

  function update<K extends keyof CashFlowDraft>(
    key: K,
    value: CashFlowDraft[K]
  ) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  function selectType(type: CashFlowType) {
    setDraft((current) => {
      const isCategoryOfType = categories.some(
        (category) => category.id === current.categoryId && category.type === type
      );
      return {
        ...current,
        type,
        categoryId: isCategoryOfType ? current.categoryId : "",
      };
    });
  }

  function selectContract(contractId: string | null) {
    const contract = contracts.find((item) => item.id === contractId);
    setDraft((current) =>
      contract
        ? {
            ...current,
            contractId: contract.id,
            objectId: contract.objectId,
            contractorId: contract.contractorId,
          }
        : { ...current, contractId: "" }
    );
  }

  function validate(): FormErrors {
    const nextErrors: FormErrors = {};
    if (!draft.date) {
      nextErrors.date = "Выберите дату платежа";
    }
    const amount = parseAmount(draft.amount);
    if (amount === null || amount <= 0) {
      nextErrors.amount = "Укажите сумму больше нуля";
    }
    return nextErrors;
  }

  function submitDraft() {
    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      return;
    }
    onSubmit(draft);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    submitDraft();
  }

  return (
    <form className="flex flex-col gap-5" onSubmit={handleSubmit}>
      <Field>
        <FieldLabel>Тип операции</FieldLabel>
        <div className="flex gap-2">
          {CASH_FLOW_TYPE_OPTIONS.map((option) => (
            <Button
              key={option.value}
              type="button"
              variant={draft.type === option.value ? "default" : "outline"}
              disabled={isSaving}
              className="flex-1"
              onClick={() => selectType(option.value)}
            >
              {option.label}
            </Button>
          ))}
        </div>
      </Field>

      <FieldGroup className="grid gap-3 sm:grid-cols-2">
        <Field data-invalid={Boolean(errors.date)}>
          <FieldLabel htmlFor="cash-flow-date">Дата платежа</FieldLabel>
          <Input
            id="cash-flow-date"
            type="date"
            value={draft.date}
            disabled={isSaving}
            aria-invalid={Boolean(errors.date)}
            onChange={(event) => update("date", event.target.value)}
          />
          <FieldError>{errors.date}</FieldError>
        </Field>

        <Field data-invalid={Boolean(errors.amount)}>
          <FieldLabel htmlFor="cash-flow-amount">Сумма</FieldLabel>
          <Input
            id="cash-flow-amount"
            inputMode="decimal"
            value={draft.amount}
            disabled={isSaving}
            aria-invalid={Boolean(errors.amount)}
            placeholder="0,00"
            onChange={(event) => update("amount", event.target.value)}
          />
          <FieldError>{errors.amount}</FieldError>
        </Field>
      </FieldGroup>

      <Field>
        <FieldLabel htmlFor="cash-flow-category">Статья ДДС</FieldLabel>
        <Select
          value={draft.categoryId}
          items={categoryItems}
          disabled={isSaving}
          onValueChange={(value) => update("categoryId", value ?? "")}
        >
          <SelectTrigger id="cash-flow-category" className="w-full">
            <SelectValue placeholder="Без статьи" />
          </SelectTrigger>
          <SelectContent>
            <SelectGroup>
              {categoryItems.map((item) => (
                <SelectItem key={item.value} value={item.value}>
                  {item.label}
                </SelectItem>
              ))}
            </SelectGroup>
          </SelectContent>
        </Select>
      </Field>

      <FieldGroup className="grid gap-3 sm:grid-cols-2">
        <Field>
          <FieldLabel htmlFor="cash-flow-object">Объект</FieldLabel>
          <Select
            value={draft.objectId}
            items={objectItems}
            disabled={isSaving}
            onValueChange={(value) => {
              const objectId = value ?? "";
              setDraft((current) => ({
                ...current,
                objectId,
                contractId:
                  current.contractId &&
                  contracts.find((item) => item.id === current.contractId)
                    ?.objectId === objectId
                    ? current.contractId
                    : "",
              }));
            }}
          >
            <SelectTrigger id="cash-flow-object" className="w-full">
              <SelectValue placeholder="Не выбрано" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {objectItems.map((item) => (
                  <SelectItem key={item.value} value={item.value}>
                    {item.label}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </Field>

        <Field>
          <FieldLabel htmlFor="cash-flow-contractor">Контрагент</FieldLabel>
          <Select
            value={draft.contractorId}
            items={contractorItems}
            disabled={isSaving}
            onValueChange={(value) => {
              const contractorId = value ?? "";
              setDraft((current) => ({
                ...current,
                contractorId,
                contractId:
                  current.contractId &&
                  contracts.find((item) => item.id === current.contractId)
                    ?.contractorId === contractorId
                    ? current.contractId
                    : "",
              }));
            }}
          >
            <SelectTrigger id="cash-flow-contractor" className="w-full">
              <SelectValue placeholder="Не выбрано" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {contractorItems.map((item) => (
                  <SelectItem key={item.value} value={item.value}>
                    {item.label}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </Field>
      </FieldGroup>

      <Field>
        <FieldLabel htmlFor="cash-flow-contract">Договор</FieldLabel>
        <Select
          value={draft.contractId}
          items={contractItems}
          disabled={isSaving}
          onValueChange={selectContract}
        >
          <SelectTrigger id="cash-flow-contract" className="w-full">
            <SelectValue placeholder="Не выбрано" />
          </SelectTrigger>
          <SelectContent>
            <SelectGroup>
              {contractItems.map((item) => (
                <SelectItem key={item.value} value={item.value}>
                  {item.label}
                </SelectItem>
              ))}
            </SelectGroup>
          </SelectContent>
        </Select>
      </Field>

      <Field>
        <FieldLabel htmlFor="cash-flow-comment">
          Комментарий / назначение платежа
        </FieldLabel>
        <Textarea
          id="cash-flow-comment"
          value={draft.comment}
          disabled={isSaving}
          rows={3}
          onChange={(event) => update("comment", event.target.value)}
        />
      </Field>

      <div className="flex justify-end gap-3">
        <Button
          type="button"
          variant="outline"
          disabled={isSaving}
          onClick={onCancel}
        >
          Отмена
        </Button>
        <Button type="submit" disabled={isSaving}>
          {isNew ? "Создать" : "Сохранить"}
        </Button>
      </div>
    </form>
  );
}

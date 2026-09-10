"use client";

import { useMemo, useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSet,
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
import { Spinner } from "@/components/ui/spinner";
import { Switch } from "@/components/ui/switch";
import type {
  Contract,
  ContractDraft,
  ContractPickItem,
} from "@/features/contracts/types/contract.types";
import {
  CONTRACT_KIND_OPTIONS,
  isContractKind,
} from "@/features/contracts/utils/contract-kind";
import {
  CONTRACT_STATUS_OPTIONS,
  isContractStatus,
} from "@/features/contracts/utils/contract-status";
import {
  computeVatAmount,
  formatCurrency,
  parseAmount,
  toDraft,
} from "@/features/contracts/utils/contract.utils";

type ContractFormProps = {
  contract?: Contract | null;
  contractors: ContractPickItem[];
  objects: ContractPickItem[];
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: ContractDraft) => void;
};

type FormErrors = Partial<
  Record<
    "number" | "date" | "contractorId" | "objectId" | "amount" | "endDate",
    string
  >
>;

export function ContractForm({
  contract,
  contractors,
  objects,
  isSaving,
  onCancel,
  onSubmit,
}: ContractFormProps) {
  const [draft, setDraft] = useState<ContractDraft>(() => toDraft(contract));
  const [errors, setErrors] = useState<FormErrors>({});
  const isNew = !contract;
  const contractorItems = useMemo(
    () => contractors.map((item) => ({ value: item.id, label: item.label })),
    [contractors]
  );
  const objectItems = useMemo(
    () => objects.map((item) => ({ value: item.id, label: item.label })),
    [objects]
  );

  const amount = parseAmount(draft.amount) ?? 0;
  const vatRate = parseAmount(draft.vatRate) ?? 0;
  const vatAmount = computeVatAmount(amount, vatRate, draft.isVatIncluded);

  function update<K extends keyof ContractDraft>(
    key: K,
    value: ContractDraft[K]
  ) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  function validate(): FormErrors {
    const nextErrors: FormErrors = {};
    if (!draft.number.trim()) {
      nextErrors.number = "Введите номер";
    }
    if (!draft.date) {
      nextErrors.date = "Выберите дату";
    }
    if (draft.endDate && draft.date && draft.endDate < draft.date) {
      nextErrors.endDate = "Дата окончания раньше даты заключения";
    }
    if (!draft.contractorId) {
      nextErrors.contractorId = "Выберите контрагента";
    }
    if (!draft.objectId) {
      nextErrors.objectId = "Выберите объект";
    }
    if (!draft.amount.trim()) {
      nextErrors.amount = "Введите сумму";
    } else if (parseAmount(draft.amount) === null || (parseAmount(draft.amount) ?? 0) < 0) {
      nextErrors.amount = "Некорректная сумма";
    }
    return nextErrors;
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validate();
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) {
      return;
    }
    onSubmit(draft);
  }

  return (
    <form className="flex flex-col gap-6" onSubmit={handleSubmit}>
      <FieldSet>
        <FieldLegend>Данные договора</FieldLegend>
        <FieldGroup>
          <Field data-invalid={Boolean(errors.number)}>
            <FieldLabel htmlFor="contract-number">Номер договора</FieldLabel>
            <Input
              id="contract-number"
              value={draft.number}
              disabled={isSaving}
              aria-invalid={Boolean(errors.number)}
              placeholder="Введите номер"
              onChange={(event) => update("number", event.target.value)}
            />
            <FieldError>{errors.number}</FieldError>
          </Field>
          <Field>
            <FieldLabel htmlFor="contract-kind">Тип договора</FieldLabel>
            <Select
              value={draft.kind}
              items={CONTRACT_KIND_OPTIONS}
              disabled={isSaving}
              onValueChange={(value) => {
                if (isContractKind(value)) {
                  update("kind", value);
                }
              }}
            >
              <SelectTrigger id="contract-kind" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {CONTRACT_KIND_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </Field>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field data-invalid={Boolean(errors.date)}>
              <FieldLabel htmlFor="contract-date">Дата заключения</FieldLabel>
              <Input
                id="contract-date"
                type="date"
                value={draft.date}
                disabled={isSaving}
                aria-invalid={Boolean(errors.date)}
                onChange={(event) => update("date", event.target.value)}
              />
              <FieldError>{errors.date}</FieldError>
            </Field>
            <Field data-invalid={Boolean(errors.endDate)}>
              <FieldLabel htmlFor="contract-end-date">Дата окончания</FieldLabel>
              <Input
                id="contract-end-date"
                type="date"
                value={draft.endDate}
                disabled={isSaving}
                aria-invalid={Boolean(errors.endDate)}
                onChange={(event) => update("endDate", event.target.value)}
              />
              <FieldError>{errors.endDate}</FieldError>
            </Field>
          </FieldGroup>
          <Field data-invalid={Boolean(errors.contractorId)}>
            <FieldLabel htmlFor="contract-contractor">Контрагент</FieldLabel>
            <Select
              value={draft.contractorId || null}
              items={contractorItems}
              disabled={isSaving || contractorItems.length === 0}
              onValueChange={(value) => {
                if (value) {
                  update("contractorId", value);
                }
              }}
            >
              <SelectTrigger id="contract-contractor" className="w-full">
                <SelectValue placeholder="Выберите контрагента" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {contractorItems.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
            {contractorItems.length === 0 ? (
              <FieldDescription>
                Сначала добавьте контрагента в справочник.
              </FieldDescription>
            ) : (
              <FieldError>{errors.contractorId}</FieldError>
            )}
          </Field>
          <Field data-invalid={Boolean(errors.objectId)}>
            <FieldLabel htmlFor="contract-object">Объект</FieldLabel>
            <Select
              value={draft.objectId || null}
              items={objectItems}
              disabled={isSaving || objectItems.length === 0}
              onValueChange={(value) => {
                if (value) {
                  update("objectId", value);
                }
              }}
            >
              <SelectTrigger id="contract-object" className="w-full">
                <SelectValue placeholder="Выберите объект" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {objectItems.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
            {objectItems.length === 0 ? (
              <FieldDescription>
                Сначала добавьте объект в справочник.
              </FieldDescription>
            ) : (
              <FieldError>{errors.objectId}</FieldError>
            )}
          </Field>
          <Field data-invalid={Boolean(errors.amount)}>
            <FieldLabel htmlFor="contract-amount">Сумма договора</FieldLabel>
            <Input
              id="contract-amount"
              inputMode="decimal"
              value={draft.amount}
              disabled={isSaving}
              aria-invalid={Boolean(errors.amount)}
              placeholder="0,00"
              onChange={(event) => update("amount", event.target.value)}
            />
            <FieldError>{errors.amount}</FieldError>
          </Field>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="contract-vat-rate">Ставка НДС (%)</FieldLabel>
              <Input
                id="contract-vat-rate"
                inputMode="decimal"
                value={draft.vatRate}
                disabled={isSaving}
                placeholder="0"
                onChange={(event) => update("vatRate", event.target.value)}
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contract-vat-amount">Сумма НДС</FieldLabel>
              <Input
                id="contract-vat-amount"
                value={formatCurrency(vatAmount)}
                readOnly
                disabled={isSaving}
              />
            </Field>
          </FieldGroup>
          <Field orientation="horizontal">
            <FieldContent>
              <FieldLabel htmlFor="contract-vat-included">
                НДС включён в стоимость
              </FieldLabel>
            </FieldContent>
            <Switch
              id="contract-vat-included"
              checked={draft.isVatIncluded}
              disabled={isSaving}
              onCheckedChange={(checked) => update("isVatIncluded", checked)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="contract-advance">Сумма аванса</FieldLabel>
            <Input
              id="contract-advance"
              inputMode="decimal"
              value={draft.advanceAmount}
              disabled={isSaving}
              placeholder="0,00"
              onChange={(event) => update("advanceAmount", event.target.value)}
            />
          </Field>
          <FieldGroup className="grid sm:grid-cols-3">
            <Field>
              <FieldLabel htmlFor="contract-warranty-rate">
                Удержания (%)
              </FieldLabel>
              <Input
                id="contract-warranty-rate"
                inputMode="decimal"
                value={draft.warrantyRetentionRate}
                disabled={isSaving}
                placeholder="0"
                onChange={(event) =>
                  update("warrantyRetentionRate", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contract-warranty-months">
                Срок (мес.)
              </FieldLabel>
              <Input
                id="contract-warranty-months"
                inputMode="numeric"
                value={draft.warrantyPeriodMonths}
                disabled={isSaving}
                placeholder="0"
                onChange={(event) =>
                  update("warrantyPeriodMonths", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contract-warranty-amount">
                Сумма удержаний
              </FieldLabel>
              <Input
                id="contract-warranty-amount"
                inputMode="decimal"
                value={draft.warrantyRetentionAmount}
                disabled={isSaving}
                placeholder="0,00"
                onChange={(event) =>
                  update("warrantyRetentionAmount", event.target.value)
                }
              />
            </Field>
          </FieldGroup>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="contract-gc-rate">
                Генподрядные (%)
              </FieldLabel>
              <Input
                id="contract-gc-rate"
                inputMode="decimal"
                value={draft.generalContractorFeeRate}
                disabled={isSaving}
                placeholder="0"
                onChange={(event) =>
                  update("generalContractorFeeRate", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contract-gc-amount">
                Сумма генподрядных
              </FieldLabel>
              <Input
                id="contract-gc-amount"
                inputMode="decimal"
                value={draft.generalContractorFeeAmount}
                disabled={isSaving}
                placeholder="0,00"
                onChange={(event) =>
                  update("generalContractorFeeAmount", event.target.value)
                }
              />
            </Field>
          </FieldGroup>
          <Field>
            <FieldLabel htmlFor="contract-status">Статус</FieldLabel>
            <Select
              value={draft.status}
              items={CONTRACT_STATUS_OPTIONS}
              disabled={isSaving}
              onValueChange={(value) => {
                if (isContractStatus(value)) {
                  update("status", value);
                }
              }}
            >
              <SelectTrigger id="contract-status" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {CONTRACT_STATUS_OPTIONS.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </Field>
        </FieldGroup>
      </FieldSet>

      <FieldSet>
        <FieldLegend>Подрядчик (исполнитель)</FieldLegend>
        <FieldGroup>
          <Field>
            <FieldLabel htmlFor="contract-contractor-org">
              Наименование организации
            </FieldLabel>
            <Input
              id="contract-contractor-org"
              value={draft.contractorLegalName}
              disabled={isSaving}
              onChange={(event) =>
                update("contractorLegalName", event.target.value)
              }
            />
          </Field>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="contract-contractor-position">
                Должность
              </FieldLabel>
              <Input
                id="contract-contractor-position"
                value={draft.contractorPosition}
                disabled={isSaving}
                onChange={(event) =>
                  update("contractorPosition", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contract-contractor-signer">
                ФИО подписанта
              </FieldLabel>
              <Input
                id="contract-contractor-signer"
                value={draft.contractorSigner}
                disabled={isSaving}
                onChange={(event) =>
                  update("contractorSigner", event.target.value)
                }
              />
            </Field>
          </FieldGroup>
        </FieldGroup>
      </FieldSet>

      <FieldSet>
        <FieldLegend>Заказчик</FieldLegend>
        <FieldGroup>
          <Field>
            <FieldLabel htmlFor="contract-customer-org">
              Наименование организации
            </FieldLabel>
            <Input
              id="contract-customer-org"
              value={draft.customerLegalName}
              disabled={isSaving}
              onChange={(event) =>
                update("customerLegalName", event.target.value)
              }
            />
          </Field>
          <FieldGroup className="grid sm:grid-cols-2">
            <Field>
              <FieldLabel htmlFor="contract-customer-position">
                Должность
              </FieldLabel>
              <Input
                id="contract-customer-position"
                value={draft.customerPosition}
                disabled={isSaving}
                onChange={(event) =>
                  update("customerPosition", event.target.value)
                }
              />
            </Field>
            <Field>
              <FieldLabel htmlFor="contract-customer-signer">
                ФИО подписанта
              </FieldLabel>
              <Input
                id="contract-customer-signer"
                value={draft.customerSigner}
                disabled={isSaving}
                onChange={(event) =>
                  update("customerSigner", event.target.value)
                }
              />
            </Field>
          </FieldGroup>
        </FieldGroup>
      </FieldSet>

      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" disabled={isSaving} onClick={onCancel}>
          Отмена
        </Button>
        <Button type="submit" disabled={isSaving}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          {isNew ? "Создать" : "Сохранить"}
        </Button>
      </div>
    </form>
  );
}

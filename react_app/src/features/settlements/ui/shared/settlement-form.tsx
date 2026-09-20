"use client";

import { useMemo, useState, type FormEvent } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { ChevronDownIcon } from "lucide-react";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import { Collapsible, CollapsibleContent } from "@/components/ui/collapsible";
import {
  Field,
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
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import type { Contract } from "@/features/contracts/types/contract.types";
import { getNextSettlementInvoiceNumber } from "@/features/settlements/api/get-next-settlement-invoice-number";
import type {
  Settlement,
  SettlementDraft,
  SettlementOperationType,
  SettlementPickItem,
} from "@/features/settlements/types/settlement.types";
import { SETTLEMENT_OPERATION_TYPE_OPTIONS } from "@/features/settlements/utils/operation-type";
import {
  emptySettlementDraft,
  formatCurrency,
  formatQuantity,
  parseAmount,
  settlementToDraft,
} from "@/features/settlements/utils/settlement.utils";
import { computeSettlementVat } from "@/features/settlements/utils/vat";

type SettlementFormProps = {
  layout: "dialog" | "sheet";
  settlement?: Settlement | null;
  presetContract?: Contract | null;
  contractors: SettlementPickItem[];
  objects: SettlementPickItem[];
  contracts: Contract[];
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (draft: SettlementDraft) => void;
};

type FormErrors = Partial<
  Record<
    | "objectId"
    | "contractorId"
    | "contractId"
    | "actNumber"
    | "invoiceNumber"
    | "invoiceDate"
    | "amount"
    | "vatRate",
    string
  >
>;

function draftFromContract(contract: Contract): SettlementDraft {
  const hasVat = contract.vatRate > 0;
  return {
    ...emptySettlementDraft(),
    objectId: contract.objectId,
    contractorId: contract.contractorId,
    contractId: contract.id,
    isVatEnabled: hasVat,
    vatRate: hasVat ? formatQuantity(contract.vatRate) : "22",
    isVatIncluded: contract.isVatIncluded,
  };
}

/**
 * Форма счёта: общая для настольного окна и мобильного окна снизу.
 *
 * В `sheet` поля сгруппированы для телефона: реквизиты свёрнуты в строку-сводку
 * и разворачиваются, пока заполнены не все обязательные поля.
 */
export function SettlementForm({
  layout,
  settlement,
  presetContract,
  contractors,
  objects,
  contracts,
  isSaving,
  onCancel,
  onSubmit,
}: SettlementFormProps) {
  const [draft, setDraft] = useState<SettlementDraft>(() => {
    if (settlement) {
      return settlementToDraft(settlement);
    }
    if (presetContract) {
      return draftFromContract(presetContract);
    }
    return emptySettlementDraft();
  });
  const [errors, setErrors] = useState<FormErrors>({});
  const [editContextOpen, setEditContextOpen] = useState(false);
  const isNew = !settlement;
  const lockedContext = Boolean(presetContract);
  const queryClient = useQueryClient();

  const filteredContracts = useMemo(() => {
    return contracts.filter((contract) => {
      if (draft.objectId && contract.objectId !== draft.objectId) return false;
      if (draft.contractorId && contract.contractorId !== draft.contractorId) {
        return false;
      }
      return true;
    });
  }, [contracts, draft.objectId, draft.contractorId]);

  const isAct = draft.operationType === "act";
  const entered = parseAmount(draft.amount) ?? 0;
  const rate = draft.isVatEnabled ? parseAmount(draft.vatRate) ?? 0 : 0;
  const breakdown = computeSettlementVat(entered, rate, draft.isVatIncluded);
  const hasVat = draft.isVatEnabled && rate > 0;

  function update<K extends keyof SettlementDraft>(
    key: K,
    value: SettlementDraft[K]
  ) {
    setDraft((current) => ({ ...current, [key]: value }));
  }

  async function suggestInvoiceNumber(contractId: string) {
    try {
      const next = await queryClient.fetchQuery({
        queryKey: ["settlement-next-invoice-number", contractId],
        queryFn: () => getNextSettlementInvoiceNumber(contractId),
        staleTime: 0,
        gcTime: 0,
      });
      if (next) {
        setDraft((current) =>
          current.invoiceNumber.trim()
            ? current
            : { ...current, invoiceNumber: next }
        );
      }
    } catch {
      // Подсказка номера не критична — номер можно ввести вручную.
    }
  }

  function selectContract(contractId: string | null) {
    const contract = contracts.find((item) => item.id === contractId);
    if (!contract) {
      update("contractId", "");
      return;
    }
    setDraft((current) => ({
      ...current,
      contractId: contract.id,
      objectId: contract.objectId,
      contractorId: contract.contractorId,
      ...(isNew
        ? {
            isVatEnabled: contract.vatRate > 0,
            vatRate: contract.vatRate > 0 ? formatQuantity(contract.vatRate) : "22",
            isVatIncluded: contract.isVatIncluded,
            invoiceNumber: "",
          }
        : {}),
    }));
    if (isNew) {
      void suggestInvoiceNumber(contract.id);
    }
  }

  function validate(): FormErrors {
    const nextErrors: FormErrors = {};
    if (!draft.objectId) nextErrors.objectId = "Выберите объект";
    if (!draft.contractorId) nextErrors.contractorId = "Выберите контрагента";
    if (!draft.contractId) nextErrors.contractId = "Выберите договор";
    if (isAct && !draft.actNumber.trim()) {
      nextErrors.actNumber = "Укажите номер акта";
    }
    if (!draft.invoiceNumber.trim()) {
      nextErrors.invoiceNumber = "Укажите номер счёта";
    }
    if (!draft.invoiceDate) nextErrors.invoiceDate = "Выберите дату счёта";
    const amountValue = parseAmount(draft.amount);
    if (amountValue === null || amountValue <= 0) {
      nextErrors.amount = "Укажите сумму";
    }
    if (draft.isVatEnabled) {
      const rateValue = parseAmount(draft.vatRate);
      if (rateValue === null || rateValue < 0 || rateValue > 100) {
        nextErrors.vatRate = "Укажите %";
      }
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

  const objectItems = objects.map((item) => ({
    value: item.id,
    label: item.label,
  }));
  const contractorItems = contractors.map((item) => ({
    value: item.id,
    label: item.label,
  }));
  const contractItems = filteredContracts.map((item) => ({
    value: item.id,
    label: item.number,
  }));

  const objectField = (
    <Field data-invalid={Boolean(errors.objectId)}>
      <FieldLabel htmlFor="settlement-object">Объект</FieldLabel>
      <Select
        value={draft.objectId}
        items={objectItems}
        disabled={isSaving || lockedContext}
        onValueChange={(value) => {
          const nextObjectId = value ?? "";
          setDraft((current) => ({
            ...current,
            objectId: nextObjectId,
            contractId:
              current.contractId &&
              contracts.find((c) => c.id === current.contractId)?.objectId ===
                nextObjectId
                ? current.contractId
                : "",
          }));
        }}
      >
        <SelectTrigger id="settlement-object" className="w-full">
          <SelectValue placeholder="Выберите объект" />
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
      <FieldError>{errors.objectId}</FieldError>
    </Field>
  );

  const contractorField = (
    <Field data-invalid={Boolean(errors.contractorId)}>
      <FieldLabel htmlFor="settlement-contractor">Контрагент</FieldLabel>
      <Select
        value={draft.contractorId}
        items={contractorItems}
        disabled={isSaving || lockedContext}
        onValueChange={(value) => {
          const nextContractorId = value ?? "";
          setDraft((current) => ({
            ...current,
            contractorId: nextContractorId,
            contractId:
              current.contractId &&
              contracts.find((c) => c.id === current.contractId)
                ?.contractorId === nextContractorId
                ? current.contractId
                : "",
          }));
        }}
      >
        <SelectTrigger id="settlement-contractor" className="w-full">
          <SelectValue placeholder="Выберите контрагента" />
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
      <FieldError>{errors.contractorId}</FieldError>
    </Field>
  );

  const contractField = (
    <Field data-invalid={Boolean(errors.contractId)}>
      <FieldLabel htmlFor="settlement-contract">Договор</FieldLabel>
      <Select
        value={draft.contractId}
        items={contractItems}
        disabled={isSaving || lockedContext}
        onValueChange={selectContract}
      >
        <SelectTrigger id="settlement-contract" className="w-full">
          <SelectValue placeholder="Выберите договор" />
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
      <FieldError>{errors.contractId}</FieldError>
    </Field>
  );

  const operationTypeField = (
    <Field>
      <FieldLabel>Тип операции</FieldLabel>
      <div className="flex gap-2">
        {SETTLEMENT_OPERATION_TYPE_OPTIONS.map((option) => (
          <Button
            key={option.value}
            type="button"
            variant={draft.operationType === option.value ? "default" : "outline"}
            disabled={isSaving}
            className="flex-1"
            onClick={() => {
              const nextType: SettlementOperationType = option.value;
              setDraft((current) => ({
                ...current,
                operationType: nextType,
                actNumber: nextType === "act" ? current.actNumber : "",
              }));
            }}
          >
            {option.label}
          </Button>
        ))}
      </div>
    </Field>
  );

  const actNumberField = isAct ? (
    <Field data-invalid={Boolean(errors.actNumber)}>
      <FieldLabel htmlFor="settlement-act-number">Номер акта</FieldLabel>
      <Input
        id="settlement-act-number"
        value={draft.actNumber}
        disabled={isSaving}
        aria-invalid={Boolean(errors.actNumber)}
        onChange={(event) => update("actNumber", event.target.value)}
      />
      <FieldError>{errors.actNumber}</FieldError>
    </Field>
  ) : null;

  const invoiceNumberField = (
    <Field data-invalid={Boolean(errors.invoiceNumber)}>
      <FieldLabel htmlFor="settlement-invoice-number">Номер счёта</FieldLabel>
      <Input
        id="settlement-invoice-number"
        value={draft.invoiceNumber}
        disabled={isSaving}
        aria-invalid={Boolean(errors.invoiceNumber)}
        onChange={(event) => update("invoiceNumber", event.target.value)}
      />
      <FieldError>{errors.invoiceNumber}</FieldError>
    </Field>
  );

  const invoiceDateField = (
    <Field data-invalid={Boolean(errors.invoiceDate)}>
      <FieldLabel htmlFor="settlement-invoice-date">Дата счёта</FieldLabel>
      <Input
        id="settlement-invoice-date"
        type="date"
        value={draft.invoiceDate}
        disabled={isSaving}
        aria-invalid={Boolean(errors.invoiceDate)}
        onChange={(event) => update("invoiceDate", event.target.value)}
      />
      <FieldError>{errors.invoiceDate}</FieldError>
    </Field>
  );

  const amountField = (
    <Field data-invalid={Boolean(errors.amount)}>
      <FieldLabel htmlFor="settlement-amount">
        {hasVat
          ? draft.isVatIncluded
            ? "Сумма с НДС"
            : "Сумма без НДС"
          : "Сумма"}
      </FieldLabel>
      <Input
        id="settlement-amount"
        inputMode="decimal"
        value={draft.amount}
        disabled={isSaving}
        aria-invalid={Boolean(errors.amount)}
        placeholder="0,00"
        onChange={(event) => update("amount", event.target.value)}
      />
      <FieldError>{errors.amount}</FieldError>
    </Field>
  );

  const vatRateField = (
    <Field data-invalid={Boolean(errors.vatRate)}>
      <FieldLabel htmlFor="settlement-vat-rate">Ставка НДС, %</FieldLabel>
      <Input
        id="settlement-vat-rate"
        inputMode="decimal"
        value={draft.vatRate}
        disabled={isSaving || !draft.isVatEnabled}
        aria-invalid={Boolean(errors.vatRate)}
        onChange={(event) => update("vatRate", event.target.value)}
      />
      <FieldError>{errors.vatRate}</FieldError>
    </Field>
  );

  const vatSwitchField = (
    <Field>
      <FieldLabel htmlFor="settlement-vat-enabled">НДС</FieldLabel>
      <div className="flex h-9 items-center">
        <Switch
          id="settlement-vat-enabled"
          checked={draft.isVatEnabled}
          disabled={isSaving}
          onCheckedChange={(checked) =>
            setDraft((current) => ({
              ...current,
              isVatEnabled: checked,
              vatRate:
                checked && !(parseAmount(current.vatRate) ?? 0)
                  ? "22"
                  : current.vatRate,
            }))
          }
        />
      </div>
    </Field>
  );

  const vatModeField = hasVat ? (
    <>
      <Field>
        <FieldLabel>Режим НДС</FieldLabel>
        <div className="flex gap-2">
          <Button
            type="button"
            variant={draft.isVatIncluded ? "default" : "outline"}
            className="flex-1"
            disabled={isSaving}
            onClick={() => update("isVatIncluded", true)}
          >
            НДС в сумме
          </Button>
          <Button
            type="button"
            variant={!draft.isVatIncluded ? "default" : "outline"}
            className="flex-1"
            disabled={isSaving}
            onClick={() => update("isVatIncluded", false)}
          >
            НДС сверху
          </Button>
        </div>
      </Field>
      <div className="grid grid-cols-3 gap-3 rounded-lg border p-3 text-sm">
        <div>
          <p className="text-muted-foreground text-xs">Без НДС</p>
          <p className="font-medium tabular-nums">
            {formatCurrency(breakdown.base)}
          </p>
        </div>
        <div>
          <p className="text-muted-foreground text-xs">НДС</p>
          <p className="font-medium tabular-nums">
            {formatCurrency(breakdown.vat)}
          </p>
        </div>
        <div>
          <p className="text-muted-foreground text-xs">Итого с НДС</p>
          <p className="font-semibold tabular-nums">
            {formatCurrency(breakdown.total)}
          </p>
        </div>
      </div>
    </>
  ) : null;

  const noteField = (
    <Field>
      <FieldLabel htmlFor="settlement-note">Примечание</FieldLabel>
      <Textarea
        id="settlement-note"
        value={draft.note}
        disabled={isSaving}
        rows={3}
        onChange={(event) => update("note", event.target.value)}
      />
      <FieldDescription>
        Попадает в PDF счёта как наименование позиции.
      </FieldDescription>
    </Field>
  );

  const dialogFields = (
    <>
      <FieldGroup className="grid gap-3 sm:grid-cols-3">
        {objectField}
        {contractorField}
        {contractField}
      </FieldGroup>

      {operationTypeField}
      {actNumberField}

      <FieldGroup className="grid gap-3 sm:grid-cols-2">
        {invoiceNumberField}
        {invoiceDateField}
      </FieldGroup>

      <FieldGroup className="grid gap-3 sm:grid-cols-[2fr_1fr_auto]">
        {amountField}
        {vatRateField}
        {vatSwitchField}
      </FieldGroup>

      {vatModeField}
      {noteField}
    </>
  );

  const objectLabel = objects.find((item) => item.id === draft.objectId)?.label;
  const contractorLabel = contractors.find(
    (item) => item.id === draft.contractorId
  )?.label;
  const contractLabel = contracts.find(
    (item) => item.id === draft.contractId
  )?.number;
  const contextReady = Boolean(
    draft.objectId && draft.contractorId && draft.contractId
  );
  const contextExpanded = !contextReady || editContextOpen;
  const contextSummary = [objectLabel, contractorLabel, contractLabel]
    .filter(Boolean)
    .join(" · ");

  const sheetFields = (
    <>
      {contextReady ? (
        <Button
          type="button"
          variant="outline"
          className="h-auto min-h-8 w-full shrink-0 justify-between gap-2 whitespace-normal text-left"
          aria-expanded={contextExpanded}
          onClick={() => setEditContextOpen((open) => !open)}
        >
          <span className="min-w-0 flex-1 text-xs">{contextSummary}</span>
          {contextExpanded ? "Скрыть" : "Изменить"}
          <ChevronDownIcon
            data-icon="inline-end"
            className={contextExpanded ? "rotate-180" : undefined}
          />
        </Button>
      ) : null}

      <Collapsible open={contextExpanded} className="shrink-0">
        <CollapsibleContent className="h-[var(--collapsible-panel-height)] overflow-hidden data-ending-style:h-0 data-starting-style:h-0">
          <FieldGroup className="grid gap-3 p-1">
            {objectField}
            {contractorField}
            {contractField}
          </FieldGroup>
        </CollapsibleContent>
      </Collapsible>

      <FieldSet className="gap-3">
        <FieldLegend>Документ</FieldLegend>
        {operationTypeField}
        {actNumberField}
        <FieldGroup className="grid grid-cols-2 gap-3">
          {invoiceNumberField}
          {invoiceDateField}
        </FieldGroup>
      </FieldSet>

      {amountField}

      <FieldGroup className="grid grid-cols-2 gap-3">
        {vatRateField}
        {vatSwitchField}
      </FieldGroup>

      {vatModeField}
      {noteField}
    </>
  );

  if (layout === "sheet") {
    // Кнопка сохранения гаснет, пока не заполнены обязательные поля.
    const isComplete = Object.keys(validate()).length === 0;

    return (
      <>
        <MobileSheetChrome
          title={isNew ? "Новый счёт" : "Редактирование счёта"}
          description="Объект, контрагент, договор, номер и сумма обязательны."
          confirmLabel="Сохранить"
          confirmDisabled={isSaving || !isComplete}
          confirmPending={isSaving}
          onConfirm={submitDraft}
        />
        <MobileSheetBody>{sheetFields}</MobileSheetBody>
      </>
    );
  }

  return (
    <form className="flex flex-col gap-5" onSubmit={handleSubmit}>
      {dialogFields}
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
          Сохранить
        </Button>
      </div>
    </form>
  );
}

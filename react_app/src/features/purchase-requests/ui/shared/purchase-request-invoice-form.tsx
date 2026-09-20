"use client";

import { useMemo, useState } from "react";
import { SparklesIcon } from "lucide-react";
import { toast } from "sonner";

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
import { Field, FieldLabel } from "@/components/ui/field";
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
import { Textarea } from "@/components/ui/textarea";
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import { digitsInn } from "@/features/contractors/utils/contractor.utils";
import { useRecognizePurchaseRequestInvoice } from "@/features/purchase-requests/hooks/use-purchase-requests";
import type { PurchaseRequestInvoiceItemDraft } from "@/features/purchase-requests/types/purchase-request.types";
import {
  formatAmountInput,
  parseAmountInput,
} from "@/features/purchase-requests/utils/amount";
import {
  collectInvoiceItemDrafts,
  invoiceItemRowsFromItems,
  type InvoiceItemRow,
} from "@/features/purchase-requests/utils/invoice-items";
import { INVOICE_FILE_EXTENSIONS } from "@/features/purchase-requests/utils/invoices";
import { PurchaseRequestInvoiceItemsEditor } from "@/features/purchase-requests/ui/shared/purchase-request-invoice-items-editor";

export type PurchaseRequestInvoiceFormInput = {
  supplierId: string;
  amount: number;
  invoiceNumber: string | null;
  invoiceDate: string | null;
  comment: string | null;
  file: File;
  items: PurchaseRequestInvoiceItemDraft[];
};

type PurchaseRequestInvoiceFormProps = {
  /** Оформление: настольное окно или мобильное окно снизу. */
  layout: "dialog" | "sheet";
  requestId: string;
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (input: PurchaseRequestInvoiceFormInput) => void;
};

/**
 * Форма добавления счёта — общая для компьютера и телефона.
 *
 * Поля, проверка и распознавание одинаковы, отличается только оформление.
 * Кнопка «Распознать» заполняет поставщика, номер, дату, сумму и позиции:
 * результат распознавания человек проверяет и правит перед сохранением.
 */
export function PurchaseRequestInvoiceForm({
  layout,
  requestId,
  isSaving,
  onCancel,
  onSubmit,
}: PurchaseRequestInvoiceFormProps) {
  const { data: contractors } = useContractors();
  const recognize = useRecognizePurchaseRequestInvoice();

  const suppliers = useMemo(
    () => (contractors ?? []).filter((item) => item.type === "supplier"),
    [contractors]
  );
  const supplierItems = suppliers.map((item) => ({
    value: item.id,
    label: item.shortName || item.fullName,
  }));

  const [supplierId, setSupplierId] = useState("");
  const [amount, setAmount] = useState("");
  const [number, setNumber] = useState("");
  const [date, setDate] = useState("");
  const [comment, setComment] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [rows, setRows] = useState<InvoiceItemRow[]>([]);

  const isRecognizing = recognize.isPending;

  /** Подбирает поставщика из контрагентов по ИНН из счёта. */
  function matchSupplier(inn: string | null): void {
    if (!inn) {
      return;
    }
    const digits = digitsInn(inn);
    const match = suppliers.find((item) => digitsInn(item.inn) === digits);
    if (match) {
      setSupplierId(match.id);
      return;
    }
    toast.message("Поставщик из счёта не найден среди контрагентов");
  }

  async function handleRecognize() {
    if (!file) {
      toast.error("Сначала выберите файл счёта");
      return;
    }
    try {
      const result = await recognize.mutateAsync({ requestId, file });
      matchSupplier(result.supplierInn);
      if (result.invoiceNumber) {
        setNumber(result.invoiceNumber);
      }
      if (result.invoiceDate) {
        setDate(result.invoiceDate);
      }
      if (result.total !== null) {
        setAmount(String(result.total));
      }
      if (result.items.length > 0) {
        setRows(invoiceItemRowsFromItems(result.items));
      }
      toast.success(
        result.items.length > 0
          ? `Распознано позиций: ${result.items.length}`
          : "Счёт распознан, позиции не найдены"
      );
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось распознать счёт"
      );
    }
  }

  function handleSubmit() {
    if (!supplierId) {
      toast.error("Выберите поставщика");
      return;
    }
    const parsedAmount = parseAmountInput(amount);
    if (parsedAmount === null || parsedAmount <= 0) {
      toast.error("Укажите сумму счёта больше нуля");
      return;
    }
    if (!file) {
      toast.error("Прикрепите файл счёта");
      return;
    }
    onSubmit({
      supplierId,
      amount: parsedAmount,
      invoiceNumber: number.trim() || null,
      invoiceDate: date || null,
      comment: comment.trim() || null,
      file,
      items: collectInvoiceItemDrafts(rows),
    });
  }

  const fields = (
    <>
      <Field>
        <FieldLabel>Поставщик</FieldLabel>
        <Select
          value={supplierId || undefined}
          items={supplierItems}
          onValueChange={(value) => {
            if (value) {
              setSupplierId(value);
            }
          }}
        >
          <SelectTrigger className="w-full">
            <SelectValue placeholder="Выберите поставщика" />
          </SelectTrigger>
          <SelectContent>
            <SelectGroup>
              {supplierItems.map((item) => (
                <SelectItem key={item.value} value={item.value}>
                  {item.label}
                </SelectItem>
              ))}
            </SelectGroup>
          </SelectContent>
        </Select>
      </Field>

      {/* Файл и распознавание — одной строкой: сначала файл, потом разбор */}
      <Field>
        <FieldLabel htmlFor="pr-invoice-file">Файл</FieldLabel>
        <div className="flex items-center gap-2">
          <Input
            id="pr-invoice-file"
            type="file"
            className="min-w-0 flex-1"
            accept={INVOICE_FILE_EXTENSIONS.map((item) => `.${item}`).join(",")}
            onChange={(event) => setFile(event.target.files?.[0] ?? null)}
          />
          <Button
            type="button"
            variant="outline"
            className="shrink-0"
            disabled={!file || isRecognizing || isSaving}
            onClick={handleRecognize}
          >
            {isRecognizing ? (
              <Spinner data-icon="inline-start" />
            ) : (
              <SparklesIcon data-icon="inline-start" />
            )}
            {isRecognizing ? "Распознаём…" : "Распознать счёт"}
          </Button>
        </div>
        <p className="text-xs text-muted-foreground">
          {file ? `${file.name}. ` : ""}
          Распознавание заполнит поставщика, номер, дату, сумму и позиции и
          займёт 10–30 секунд. Проверьте перед сохранением.
        </p>
      </Field>

      <div className="grid gap-3 sm:grid-cols-3">
        <Field>
          <FieldLabel htmlFor="pr-invoice-amount">Сумма</FieldLabel>
          <Input
            id="pr-invoice-amount"
            inputMode="decimal"
            className="text-right tabular-nums"
            value={amount}
            onChange={(event) => setAmount(event.target.value)}
            onBlur={() => setAmount(formatAmountInput(amount))}
          />
        </Field>
        <Field>
          <FieldLabel htmlFor="pr-invoice-number">Номер счёта</FieldLabel>
          <Input
            id="pr-invoice-number"
            value={number}
            onChange={(event) => setNumber(event.target.value)}
          />
        </Field>
        <Field>
          <FieldLabel htmlFor="pr-invoice-date">Дата</FieldLabel>
          <Input
            id="pr-invoice-date"
            type="date"
            value={date}
            onChange={(event) => setDate(event.target.value)}
          />
        </Field>
      </div>

      <PurchaseRequestInvoiceItemsEditor rows={rows} onChange={setRows} />

      <Field>
        <FieldLabel htmlFor="pr-invoice-comment">Комментарий</FieldLabel>
        <Textarea
          id="pr-invoice-comment"
          value={comment}
          onChange={(event) => setComment(event.target.value)}
        />
      </Field>
    </>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title="Добавить счёт"
          description="Поставщик, сумма и файл обязательны. PDF, JPG или PNG."
          confirmLabel="Добавить"
          confirmDisabled={isSaving}
          confirmPending={isSaving}
          confirmShowLabelWhenEnabled
          onConfirm={handleSubmit}
        />
        <MobileSheetBody>{fields}</MobileSheetBody>
      </>
    );
  }

  return (
    <>
      <DialogHeader>
        <DialogTitle>Добавить счёт</DialogTitle>
        <DialogDescription>
          Поставщик, сумма и файл обязательны. PDF, JPG или PNG.
        </DialogDescription>
      </DialogHeader>
      <div className="grid max-h-[min(72vh,46rem)] gap-3 overflow-y-auto pr-1">
        {fields}
      </div>
      <DialogFooter>
        <Button
          type="button"
          variant="outline"
          disabled={isSaving}
          onClick={onCancel}
        >
          Отмена
        </Button>
        <Button type="button" disabled={isSaving} onClick={handleSubmit}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          Добавить
        </Button>
      </DialogFooter>
    </>
  );
}

"use client";

import { useEffect, useRef } from "react";
import { PlusIcon, Trash2Icon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { formatAmountInput } from "@/features/purchase-requests/utils/amount";
import {
  createInvoiceItemRow,
  type InvoiceItemRow,
} from "@/features/purchase-requests/utils/invoice-items";
import { cn } from "@/lib/utils";

/**
 * Сетка строки позиции: одна и та же у заголовков и у полей.
 *
 * Между количеством и ценой стоит «×», между ценой и суммой — «=»: строка
 * читается как арифметика. Под знаки отведены узкие колонки, а зазоры строки
 * на компьютере поджаты — место уходит названию.
 */
const ROW_GRID =
  "sm:grid-cols-[110px_minmax(0,1fr)_64px_58px_10px_102px_10px_124px_32px]";

type PurchaseRequestInvoiceItemsEditorProps = {
  rows: InvoiceItemRow[];
  onChange: (rows: InvoiceItemRow[]) => void;
};

/**
 * Редактор позиций счёта — «как в счёте».
 *
 * Поставщик называет товары по-своему, поэтому строки счёта не связаны
 * с позициями заявки. На компьютере это таблица с заголовками колонок,
 * на телефоне — карточки. Строки не обязательны: счёт можно сохранить без них.
 */
export function PurchaseRequestInvoiceItemsEditor({
  rows,
  onChange,
}: PurchaseRequestInvoiceItemsEditorProps) {
  /** Меняет одно поле строки, не трогая остальные. */
  function updateRow(index: number, patch: Partial<InvoiceItemRow>) {
    onChange(
      rows.map((row, rowIndex) =>
        rowIndex === index ? { ...row, ...patch } : row
      )
    );
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between gap-2">
        <p className="text-sm font-medium">Позиции счёта</p>
        <Button
          type="button"
          size="icon"
          variant="outline"
          aria-label="Добавить строку"
          onClick={() => onChange([...rows, createInvoiceItemRow()])}
        >
          <PlusIcon />
        </Button>
      </div>

      {rows.length === 0 ? (
        <p className="rounded-xl border border-dashed border-border/60 px-3 py-4 text-center text-xs text-muted-foreground">
          Позиции не обязательны. Их можно распознать из счёта или ввести вручную.
        </p>
      ) : (
        <div className="flex flex-col gap-2">
          {/* Заголовки колонок: на телефоне поля подписаны подсказками внутри */}
          <div
            className={cn(
              "hidden gap-2 px-1 sm:grid sm:gap-1.5",
              ROW_GRID
            )}
          >
            <span className="text-center text-xs text-muted-foreground">
              Артикул
            </span>
            <span className="text-center text-xs text-muted-foreground">
              Наименование
            </span>
            <span className="text-center text-xs text-muted-foreground">Ед.</span>
            <span className="text-center text-xs text-muted-foreground">
              Кол-во
            </span>
            <span />
            <span className="text-center text-xs text-muted-foreground">Цена</span>
            <span />
            <span className="text-center text-xs text-muted-foreground">
              Сумма
            </span>
            <span className="sr-only">Действия</span>
          </div>

          {rows.map((row, index) => (
            <div
              key={row.key}
              className={cn(
                "grid grid-cols-2 gap-2 rounded-xl border border-border/60 p-2.5 sm:items-start sm:gap-1.5 sm:border-0 sm:p-0",
                ROW_GRID
              )}
            >
              <Input
                placeholder="Артикул"
                aria-label="Артикул"
                className="col-span-2 sm:col-span-1"
                value={row.article}
                onChange={(event) =>
                  updateRow(index, { article: event.target.value })
                }
              />

              {/* Наименование растёт по строкам: длинное название видно целиком */}
              <GrowingNameField
                value={row.name}
                className="col-span-2 sm:col-span-1"
                onChange={(value) => updateRow(index, { name: value })}
              />

              <Input
                placeholder="Ед."
                aria-label="Единица измерения"
                value={row.unit}
                onChange={(event) => updateRow(index, { unit: event.target.value })}
              />

              <Input
                placeholder="Кол-во"
                aria-label="Количество"
                inputMode="decimal"
                value={row.quantity}
                onChange={(event) =>
                  updateRow(index, { quantity: event.target.value })
                }
              />

              <OperatorMark operator="×" />

              <Input
                placeholder="Цена"
                aria-label="Цена"
                inputMode="decimal"
                className="text-right tabular-nums"
                value={row.price}
                onChange={(event) =>
                  updateRow(index, { price: event.target.value })
                }
                onBlur={() =>
                  updateRow(index, { price: formatAmountInput(row.price) })
                }
              />

              <OperatorMark operator="=" />

              <Input
                placeholder="Сумма"
                aria-label="Сумма"
                inputMode="decimal"
                className="text-right tabular-nums"
                value={row.amount}
                onChange={(event) =>
                  updateRow(index, { amount: event.target.value })
                }
                onBlur={() =>
                  updateRow(index, { amount: formatAmountInput(row.amount) })
                }
              />

              <Button
                type="button"
                size="icon"
                variant="ghost"
                className="text-destructive hover:text-destructive"
                aria-label="Удалить строку"
                onClick={() =>
                  onChange(rows.filter((_, rowIndex) => rowIndex !== index))
                }
              >
                <Trash2Icon />
              </Button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

type GrowingNameFieldProps = {
  value: string;
  className?: string;
  onChange: (value: string) => void;
};

/**
 * Поле наименования, которое растёт по содержимому.
 *
 * Длинные названия из счёта переносятся на строки и видны целиком — их не
 * приходится прокручивать внутри однострочного поля.
 */
function GrowingNameField({ value, className, onChange }: GrowingNameFieldProps) {
  const ref = useRef<HTMLTextAreaElement | null>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) {
      return;
    }
    element.style.height = "auto";
    element.style.height = `${element.scrollHeight}px`;
  }, [value]);

  return (
    <Textarea
      ref={ref}
      rows={1}
      placeholder="Наименование"
      aria-label="Наименование"
      className={cn(
        "min-h-9 resize-none field-sizing-fixed overflow-hidden py-2",
        className
      )}
      value={value}
      onChange={(event) => onChange(event.target.value)}
    />
  );
}

/** Знак арифметики между полями: «×» или «=». На телефоне не показывается. */
function OperatorMark({ operator }: { operator: string }) {
  return (
    <span
      aria-hidden
      className="hidden items-center justify-center pt-2 text-xs text-muted-foreground sm:flex"
    >
      {operator}
    </span>
  );
}

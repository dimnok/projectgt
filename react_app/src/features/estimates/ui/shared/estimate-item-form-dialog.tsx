"use client";

import { useMemo, useState, type FormEvent } from "react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Spinner } from "@/components/ui/spinner";
import type { EstimateItem } from "@/features/estimates/types/estimate.types";
import { formatCurrency, toNumber } from "@/features/estimates/utils/estimate.utils";

export type EstimateItemFormData = {
  estimateTitle: string;
  system: string;
  subsystem: string;
  number: string;
  name: string;
  article: string;
  manufacturer: string;
  unit: string;
  quantity: number;
  price: number;
};

type EstimateItemFormDialogProps = {
  open: boolean;
  item?: EstimateItem | null;
  defaultEstimateTitle?: string;
  availableEstimateTitles?: string[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (formData: EstimateItemFormData) => void;
};

export function EstimateItemFormDialog({
  open,
  item,
  defaultEstimateTitle = "",
  availableEstimateTitles = [],
  isSaving,
  onOpenChange,
  onSubmit,
}: EstimateItemFormDialogProps) {
  const isEditing = Boolean(item);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(90vh,52rem)] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>
            {isEditing ? "Редактирование позиции сметы" : "Новая позиция сметы"}
          </DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Внесите изменения в поля позиции. Все правки сохранятся в истории изменений."
              : "Заполните параметры сметной строки. Сумма рассчитается автоматически."}
          </DialogDescription>
        </DialogHeader>

        {open ? (
          <EstimateItemForm
            key={item?.id ?? "new"}
            item={item}
            defaultEstimateTitle={defaultEstimateTitle}
            availableEstimateTitles={availableEstimateTitles}
            isSaving={isSaving}
            onCancel={() => onOpenChange(false)}
            onSubmit={onSubmit}
          />
        ) : null}
      </DialogContent>
    </Dialog>
  );
}

type EstimateItemFormProps = {
  item?: EstimateItem | null;
  defaultEstimateTitle: string;
  availableEstimateTitles: string[];
  isSaving: boolean;
  onCancel: () => void;
  onSubmit: (formData: EstimateItemFormData) => void;
};

function EstimateItemForm({
  item,
  defaultEstimateTitle,
  availableEstimateTitles,
  isSaving,
  onCancel,
  onSubmit,
}: EstimateItemFormProps) {
  const isEditing = Boolean(item);

  const [estimateTitle, setEstimateTitle] = useState(
    () => item?.estimateTitle || defaultEstimateTitle || ""
  );
  const [system, setSystem] = useState(() => item?.system || "");
  const [subsystem, setSubsystem] = useState(() => item?.subsystem || "");
  const [number, setNumber] = useState(() => item?.number || "");
  const [name, setName] = useState(() => item?.name || "");
  const [article, setArticle] = useState(() => item?.article || "");
  const [manufacturer, setManufacturer] = useState(() => item?.manufacturer || "");
  const [unit, setUnit] = useState(() => item?.unit || "шт");
  const [quantity, setQuantity] = useState(() => String(item?.quantity ?? 1));
  const [price, setPrice] = useState(() => String(item?.price ?? 0));

  const [errors, setErrors] = useState<{ name?: string; estimateTitle?: string }>({});

  const numQuantity = useMemo(() => Math.max(0, toNumber(quantity)), [quantity]);
  const numPrice = useMemo(() => Math.max(0, toNumber(price)), [price]);
  const totalAmount = useMemo(
    () => Math.round(numQuantity * numPrice * 100) / 100,
    [numQuantity, numPrice]
  );

  function handleSubmit(e: FormEvent) {
    e.preventDefault();

    const cleanName = name.trim();
    const cleanTitle = estimateTitle.trim();

    const newErrors: { name?: string; estimateTitle?: string } = {};
    if (!cleanName) {
      newErrors.name = "Наименование обязательно для заполнения";
    }
    if (!cleanTitle) {
      newErrors.estimateTitle = "Укажите название сметы";
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    onSubmit({
      estimateTitle: cleanTitle,
      system: system.trim(),
      subsystem: subsystem.trim(),
      number: number.trim(),
      name: cleanName,
      article: article.trim(),
      manufacturer: manufacturer.trim(),
      unit: unit.trim() || "шт",
      quantity: numQuantity,
      price: numPrice,
    });
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4 py-2">
      {/* Название сметы (при создании, если не задано жестко) */}
      {!isEditing ? (
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-estimate-title" className="text-xs font-semibold">
            Смета <span className="text-destructive">*</span>
          </Label>
          <Input
            id="item-estimate-title"
            value={estimateTitle}
            onChange={(e) => {
              setEstimateTitle(e.target.value);
              if (errors.estimateTitle) {
                setErrors((prev) => ({ ...prev, estimateTitle: undefined }));
              }
            }}
            placeholder="Например: Смета на электромонтаж"
            list="form-estimate-titles"
            disabled={isSaving}
          />
          {availableEstimateTitles.length > 0 ? (
            <datalist id="form-estimate-titles">
              {availableEstimateTitles.map((t) => (
                <option key={t} value={t} />
              ))}
            </datalist>
          ) : null}
          {errors.estimateTitle ? (
            <span className="text-xs text-destructive">{errors.estimateTitle}</span>
          ) : null}
        </div>
      ) : null}

      {/* Система и Подсистема */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-system" className="text-xs font-semibold">
            Система
          </Label>
          <Input
            id="item-system"
            value={system}
            onChange={(e) => setSystem(e.target.value)}
            placeholder="Например: Электроснабжение"
            disabled={isSaving}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-subsystem" className="text-xs font-semibold">
            Подсистема
          </Label>
          <Input
            id="item-subsystem"
            value={subsystem}
            onChange={(e) => setSubsystem(e.target.value)}
            placeholder="Например: Освещение"
            disabled={isSaving}
          />
        </div>
      </div>

      {/* Номер и Наименование */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-4">
        <div className="flex flex-col gap-1.5 sm:col-span-1">
          <Label htmlFor="item-number" className="text-xs font-semibold">
            № в смете
          </Label>
          <Input
            id="item-number"
            value={number}
            onChange={(e) => setNumber(e.target.value)}
            placeholder="1.1"
            disabled={isSaving}
          />
        </div>
        <div className="flex flex-col gap-1.5 sm:col-span-3">
          <Label htmlFor="item-name" className="text-xs font-semibold">
            Наименование <span className="text-destructive">*</span>
          </Label>
          <Textarea
            id="item-name"
            value={name}
            onChange={(e) => {
              setName(e.target.value);
              if (errors.name) {
                setErrors((prev) => ({ ...prev, name: undefined }));
              }
            }}
            rows={2}
            placeholder="Введите наименование работы или материала"
            disabled={isSaving}
          />
          {errors.name ? (
            <span className="text-xs text-destructive">{errors.name}</span>
          ) : null}
        </div>
      </div>

      {/* Артикул и Производитель */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-article" className="text-xs font-semibold">
            Артикул
          </Label>
          <Input
            id="item-article"
            value={article}
            onChange={(e) => setArticle(e.target.value)}
            placeholder="Артикул или код"
            disabled={isSaving}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-manufacturer" className="text-xs font-semibold">
            Производитель
          </Label>
          <Input
            id="item-manufacturer"
            value={manufacturer}
            onChange={(e) => setManufacturer(e.target.value)}
            placeholder="Например: ООО Светотехника"
            disabled={isSaving}
          />
        </div>
      </div>

      {/* Единица, Количество, Цена и Итого */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-unit" className="text-xs font-semibold">
            Ед. изм.
          </Label>
          <Input
            id="item-unit"
            value={unit}
            onChange={(e) => setUnit(e.target.value)}
            placeholder="шт, м, м²"
            disabled={isSaving}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-quantity" className="text-xs font-semibold">
            Количество <span className="text-destructive">*</span>
          </Label>
          <Input
            id="item-quantity"
            type="text"
            inputMode="decimal"
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            disabled={isSaving}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="item-price" className="text-xs font-semibold">
            Цена (₽) <span className="text-destructive">*</span>
          </Label>
          <Input
            id="item-price"
            type="text"
            inputMode="decimal"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            disabled={isSaving}
          />
        </div>
      </div>

      {/* Итоговая сумма плашки */}
      <div className="flex items-center justify-between rounded-lg border border-border/70 bg-muted/30 px-3.5 py-2.5 text-xs">
        <span className="text-muted-foreground">Итоговая стоимость позиции:</span>
        <span className="text-sm font-semibold text-foreground tabular-nums">
          {formatCurrency(totalAmount)}
        </span>
      </div>

      <DialogFooter className="mt-2 sm:justify-between">
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
          {isSaving
            ? "Сохранение..."
            : isEditing
              ? "Сохранить изменения"
              : "Добавить позицию"}
        </Button>
      </DialogFooter>
    </form>
  );
}

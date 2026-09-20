"use client";

import { useMemo, useState } from "react";
import { PlusIcon, Trash2Icon } from "lucide-react";
import { toast } from "sonner";

import { MobileSheet, MobileSheetBody, MobileSheetChrome } from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
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
import { Textarea } from "@/components/ui/textarea";
import type {
  PurchaseRequest,
  PurchaseRequestItem,
  PurchaseRequestItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import type { SiteObject } from "@/features/objects/types/object.types";
import { collectItems, createItemRow, rowsFromItems } from "@/features/purchase-requests/utils/items";

type PurchaseRequestFormSheetProps = {
  open: boolean;
  request?: PurchaseRequest | null;
  items?: PurchaseRequestItem[];
  objects: SiteObject[];
  isSaving: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (input: {
    objectId: string;
    comment: string | null;
    items: PurchaseRequestItemDraft[];
  }) => void;
};

/**
 * Создание и правка черновика заявки (телефон).
 *
 * Содержимое монтируется при открытии, поэтому форма всегда открывается
 * с актуальными данными. Логика общая с настольным окном.
 */
export function PurchaseRequestFormSheet({
  open,
  request,
  items,
  objects,
  isSaving,
  onOpenChange,
  onSubmit,
}: PurchaseRequestFormSheetProps) {
  return (
    <MobileSheet open={open} onOpenChange={onOpenChange}>
      {open ? (
        <FormContent
          request={request}
          items={items}
          objects={objects}
          isSaving={isSaving}
          onSubmit={onSubmit}
        />
      ) : null}
    </MobileSheet>
  );
}

type FormContentProps = {
  request?: PurchaseRequest | null;
  items?: PurchaseRequestItem[];
  objects: SiteObject[];
  isSaving: boolean;
  onSubmit: (input: {
    objectId: string;
    comment: string | null;
    items: PurchaseRequestItemDraft[];
  }) => void;
};

function FormContent({
  request,
  items,
  objects,
  isSaving,
  onSubmit,
}: FormContentProps) {
  const isEdit = Boolean(request);
  const objectItems = useMemo(
    () => objects.map((object) => ({ value: object.id, label: object.name })),
    [objects]
  );
  const [objectId, setObjectId] = useState(request?.objectId ?? "");
  const [comment, setComment] = useState(request?.comment ?? "");
  const [rows, setRows] = useState(() => rowsFromItems(items));

  function handleSubmit() {
    if (!objectId) {
      toast.error("Выберите объект");
      return;
    }
    const pending = collectItems(rows);
    if (pending.length === 0) {
      toast.error("Добавьте хотя бы одну позицию с наименованием");
      return;
    }
    onSubmit({
      objectId,
      comment: comment.trim() || null,
      items: pending,
    });
  }

  return (
    <>
      <MobileSheetChrome
        title={isEdit ? "Редактирование заявки" : "Новая заявка"}
        description="Черновик сохранится в базу сразу. Отправка на согласование — из карточки заявки."
        confirmLabel={isEdit ? "Сохранить" : "Создать"}
        confirmDisabled={isSaving}
        confirmPending={isSaving}
        confirmShowLabelWhenEnabled
        onConfirm={handleSubmit}
      />
      <MobileSheetBody>
        <Field>
          <FieldLabel>Объект</FieldLabel>
          <Select
            value={objectId || undefined}
            items={objectItems}
            onValueChange={(value) => {
              if (value) {
                setObjectId(value);
              }
            }}
          >
            <SelectTrigger className="w-full">
              <SelectValue placeholder="Выберите объект" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {objectItems.map((object) => (
                  <SelectItem key={object.value} value={object.value}>
                    {object.label}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </Field>

        <div className="flex items-center justify-between gap-2">
          <p className="text-sm font-medium">Что нужно закупить</p>
          <Button
            type="button"
            size="icon"
            variant="outline"
            aria-label="Добавить позицию"
            onClick={() => setRows((current) => [...current, createItemRow()])}
          >
            <PlusIcon />
          </Button>
        </div>

        {rows.map((row, index) => (
          <div
            key={row.key}
            className="flex flex-col gap-2 rounded-xl border border-border/60 p-2.5"
          >
            <Input
              placeholder="Наименование"
              value={row.name}
              onChange={(event) =>
                setRows((current) =>
                  current.map((item, itemIndex) =>
                    itemIndex === index
                      ? { ...item, name: event.target.value }
                      : item
                  )
                )
              }
            />
            <div className="grid grid-cols-3 gap-2">
              <Input
                placeholder="кол-во"
                inputMode="decimal"
                value={row.quantity}
                onChange={(event) =>
                  setRows((current) =>
                    current.map((item, itemIndex) =>
                      itemIndex === index
                        ? { ...item, quantity: event.target.value }
                        : item
                    )
                  )
                }
              />
              <Input
                placeholder="ед."
                value={row.unit}
                onChange={(event) =>
                  setRows((current) =>
                    current.map((item, itemIndex) =>
                      itemIndex === index
                        ? { ...item, unit: event.target.value }
                        : item
                    )
                  )
                }
              />
              <Input
                placeholder="артикул"
                value={row.article}
                onChange={(event) =>
                  setRows((current) =>
                    current.map((item, itemIndex) =>
                      itemIndex === index
                        ? { ...item, article: event.target.value }
                        : item
                    )
                  )
                }
              />
            </div>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="self-start text-destructive hover:text-destructive"
              disabled={rows.length === 1}
              aria-label="Удалить позицию"
              onClick={() =>
                setRows((current) =>
                  current.filter((_, itemIndex) => itemIndex !== index)
                )
              }
            >
              <Trash2Icon data-icon="inline-start" />
              Удалить позицию
            </Button>
          </div>
        ))}

        <Field>
          <FieldLabel htmlFor="pr-mobile-comment">Комментарий</FieldLabel>
          <Textarea
            id="pr-mobile-comment"
            value={comment}
            onChange={(event) => setComment(event.target.value)}
          />
        </Field>
      </MobileSheetBody>
    </>
  );
}

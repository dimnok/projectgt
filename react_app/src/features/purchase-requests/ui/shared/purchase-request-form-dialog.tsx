"use client";

import { MinusIcon, PlusIcon } from "lucide-react";
import { useMemo, useState } from "react";
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
import type {
  PurchaseRequest,
  PurchaseRequestItem,
  PurchaseRequestItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import type { SiteObject } from "@/features/objects/types/object.types";
import {
  collectItems,
  createItemRow,
  rowsFromItems,
} from "@/features/purchase-requests/utils/items";

type FormDialogProps = {
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

export function PurchaseRequestFormDialog({
  open,
  request,
  items,
  objects,
  isSaving,
  onOpenChange,
  onSubmit,
}: FormDialogProps) {
  const isEdit = Boolean(request);
  const objectItems = useMemo(
    () => objects.map((object) => ({ value: object.id, label: object.name })),
    [objects]
  );
  const [objectId, setObjectId] = useState(request?.objectId ?? "");
  const [comment, setComment] = useState(request?.comment ?? "");
  const [rows, setRows] = useState(() => rowsFromItems(items));

  function handleOpenChange(next: boolean) {
    if (next) {
      setObjectId(request?.objectId ?? "");
      setComment(request?.comment ?? "");
      setRows(rowsFromItems(items));
    }
    onOpenChange(next);
  }

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
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-h-[min(90vh,52rem)] overflow-y-auto sm:max-w-[980px]">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Редактирование заявки" : "Новая заявка"}
          </DialogTitle>
          <DialogDescription>
            Черновик сохранится в базу сразу. Отправка на согласование — из
            карточки заявки.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4">
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
          <div className="flex items-center justify-between gap-3">
            <p className="text-sm font-medium">Что нужно закупить</p>
            <Button
              type="button"
              size="icon"
              variant="outline"
              aria-label="Добавить позицию"
              onClick={() =>
                setRows((current) => [...current, createItemRow()])
              }
            >
              <PlusIcon />
            </Button>
          </div>
          <div className="flex flex-col gap-2">
            {rows.map((row, index) => (
              <div
                key={row.key}
                className="grid grid-cols-[minmax(0,1fr)_80px_96px_128px_36px] items-center gap-2.5"
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
                  placeholder="кол-во"
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
                <Button
                  type="button"
                  size="icon"
                  variant="ghost"
                  disabled={rows.length === 1}
                  aria-label="Удалить позицию"
                  onClick={() =>
                    setRows((current) =>
                      current.filter((_, itemIndex) => itemIndex !== index)
                    )
                  }
                >
                  <MinusIcon />
                </Button>
              </div>
            ))}
          </div>
          <Field>
            <FieldLabel htmlFor="pr-comment">Комментарий</FieldLabel>
            <Textarea
              id="pr-comment"
              value={comment}
              onChange={(event) => setComment(event.target.value)}
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
            {isEdit ? "Сохранить" : "Создать заявку"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

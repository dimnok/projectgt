"use client";

import { useEffect, useState } from "react";
import { toast } from "sonner";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import { DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field";
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
import type { WorkEstimateOption } from "@/features/works/api/get-work-item-catalog";
import {
  useCreateWorkMaterial,
  useWorkMaterialContext,
} from "@/features/works/hooks/use-work-item-mutations";
import {
  WORK_MATERIAL_UNITS,
  workMaterialSaveErrorMessage,
} from "@/features/works/utils/work-material-number";

type WorkItemNewMaterialFormProps = {
  layout: "dialog" | "sheet";
  objectId: string;
  system: string;
  subsystem: string;
  onCancel: () => void;
  onCreated: (item: WorkEstimateOption) => void;
};

export function WorkItemNewMaterialForm({
  layout,
  objectId,
  system,
  subsystem,
  onCancel,
  onCreated,
}: WorkItemNewMaterialFormProps) {
  const contextQuery = useWorkMaterialContext(
    objectId,
    system,
    subsystem,
    true
  );
  const saveMutation = useCreateWorkMaterial(objectId);
  const titles = contextQuery.data?.titles ?? [];

  const [estimateTitle, setEstimateTitle] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [article, setArticle] = useState("");
  const [manufacturer, setManufacturer] = useState("");
  const [unit, setUnit] = useState<string | null>(null);

  useEffect(() => {
    if (titles.length === 0) {
      return;
    }
    setEstimateTitle((current) =>
      current && titles.some((item) => item.title === current)
        ? current
        : titles[0].title
    );
  }, [titles]);

  const isSaving = saveMutation.isPending;
  const canSave =
    name.trim().length > 0 &&
    Boolean(unit) &&
    !isSaving &&
    !contextQuery.isLoading &&
    !contextQuery.isError &&
    (titles.length > 0
      ? Boolean(estimateTitle)
      : Boolean(contextQuery.data?.fallbackTitle));

  async function handleSave() {
    if (!canSave || !unit) {
      return;
    }
    try {
      const created = await saveMutation.mutateAsync({
        objectId,
        system,
        subsystem,
        estimateTitle,
        name,
        article,
        manufacturer,
        unit,
      });
      toast.success("Материал добавлен");
      onCreated(created);
    } catch (error) {
      toast.error(workMaterialSaveErrorMessage(error));
    }
  }

  const titleItems = titles.map((item) => ({
    value: item.title,
    label: item.title,
  }));
  const unitItems = WORK_MATERIAL_UNITS.map((item) => ({
    value: item,
    label: item,
  }));

  const formBody = (
    <div className="flex min-h-0 flex-col gap-3">
      <FieldDescription>
        {system} · {subsystem}. Позиция попадёт в смету объекта, затем её можно
        выбрать в смене.
      </FieldDescription>
      {contextQuery.isLoading ? (
        <div className="flex justify-center p-6">
          <Spinner />
        </div>
      ) : contextQuery.isError ? (
        <p className="text-sm text-destructive">
          {contextQuery.error instanceof Error
            ? contextQuery.error.message
            : "Не удалось загрузить список смет"}
        </p>
      ) : titles.length === 0 && !contextQuery.data?.fallbackTitle ? (
        <p className="text-sm text-muted-foreground">
          На объекте нет сметы. Сначала загрузите смету в разделе «Сметы».
        </p>
      ) : (
        <>
          {titles.length > 0 ? (
            <Field>
              <FieldLabel htmlFor="material-estimate">Смета</FieldLabel>
              <Select
                value={estimateTitle}
                items={titleItems}
                onValueChange={(next) => {
                  if (typeof next === "string") {
                    setEstimateTitle(next);
                  }
                }}
              >
                <SelectTrigger id="material-estimate" className="w-full">
                  <SelectValue placeholder="Выберите смету" />
                </SelectTrigger>
                <SelectContent
                  align="start"
                  side={layout === "sheet" ? "top" : "bottom"}
                  alignItemWithTrigger={layout !== "sheet"}
                  className={
                    layout === "sheet"
                      ? "max-h-[min(50vh,16rem)] z-[70]"
                      : undefined
                  }
                >
                  <SelectGroup>
                    {titleItems.map((item) => (
                      <SelectItem key={item.value} value={item.value}>
                        {item.label}
                      </SelectItem>
                    ))}
                  </SelectGroup>
                </SelectContent>
              </Select>
            </Field>
          ) : null}
          <Field>
            <FieldLabel htmlFor="material-name">Наименование</FieldLabel>
            <Input
              id="material-name"
              value={name}
              placeholder="Название работы или материала"
              autoComplete="off"
              onChange={(event) => setName(event.target.value)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="material-article">Артикул</FieldLabel>
            <Input
              id="material-article"
              value={article}
              placeholder="Необязательно"
              autoComplete="off"
              onChange={(event) => setArticle(event.target.value)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="material-manufacturer">
              Производитель
            </FieldLabel>
            <Input
              id="material-manufacturer"
              value={manufacturer}
              placeholder="Необязательно"
              autoComplete="off"
              onChange={(event) => setManufacturer(event.target.value)}
            />
          </Field>
          <Field>
            <FieldLabel htmlFor="material-unit">Единица измерения</FieldLabel>
            <Select
              value={unit}
              items={unitItems}
              onValueChange={(next) => {
                if (typeof next === "string") {
                  setUnit(next);
                }
              }}
            >
              <SelectTrigger id="material-unit" className="w-full">
                <SelectValue placeholder="Выберите единицу" />
              </SelectTrigger>
              <SelectContent
                align="start"
                side={layout === "sheet" ? "top" : "bottom"}
                alignItemWithTrigger={layout !== "sheet"}
                className={
                  layout === "sheet"
                    ? "max-h-[min(50vh,16rem)] z-[70]"
                    : undefined
                }
              >
                <SelectGroup>
                  {unitItems.map((item) => (
                    <SelectItem key={item.value} value={item.value}>
                      {item.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </Field>
        </>
      )}
    </div>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title="Новый материал"
          description="Добавить позицию в смету объекта"
          confirmLabel="Сохранить"
          confirmDisabled={!canSave}
          confirmPending={isSaving}
          onConfirm={() => void handleSave()}
          onClose={onCancel}
        />
        <MobileSheetBody>{formBody}</MobileSheetBody>
      </>
    );
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col gap-3 overflow-hidden">
      <DialogHeader className="shrink-0">
        <DialogTitle>Новый материал</DialogTitle>
        <DialogDescription>
          Позиция сохранится в смете объекта. После этого её можно отметить в
          списке и указать количество.
        </DialogDescription>
      </DialogHeader>
      <div className="min-h-0 flex-1 overflow-y-auto">{formBody}</div>
      <DialogFooter className="-mx-0 -mb-0 shrink-0 rounded-none border-t-0 bg-transparent p-0">
        <Button type="button" variant="outline" disabled={isSaving} onClick={onCancel}>
          Отмена
        </Button>
        <Button type="button" disabled={!canSave} onClick={() => void handleSave()}>
          {isSaving ? <Spinner data-icon="inline-start" /> : null}
          Сохранить
        </Button>
      </DialogFooter>
    </div>
  );
}

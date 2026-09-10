"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { ImagePlusIcon, Trash2Icon, XIcon } from "lucide-react";

import {
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogTitle,
} from "@/components/ui/dialog";
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Spinner } from "@/components/ui/spinner";
import { useEmployees } from "@/features/employees/hooks/use-employees";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import { useObjects } from "@/features/objects/hooks/use-objects";
import {
  useOccupiedEmployeeIdsToday,
  useOpenWork,
  useProfileObjectIds,
} from "@/features/works/hooks/use-open-work";
import type { Work } from "@/features/works/types/work.types";
import { MAX_MORNING_PHOTOS } from "@/features/works/utils/compose-work-photo-collage";
import { formatRuDate, toDateKey } from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorkOpenFormProps = {
  onCancel: () => void;
  onOpened: (work: Work) => void;
  layout: "dialog" | "sheet";
};

export function WorkOpenForm({
  onCancel,
  onOpened,
  layout,
}: WorkOpenFormProps) {
  const objectsQuery = useObjects();
  const profileObjectsQuery = useProfileObjectIds();
  const employeesQuery = useEmployees();
  const occupiedQuery = useOccupiedEmployeeIdsToday();
  const openMutation = useOpenWork();
  const fileRef = useRef<HTMLInputElement>(null);

  const [objectId, setObjectId] = useState<string | null>(null);
  const [employeeIds, setEmployeeIds] = useState<string[]>([]);
  const [photos, setPhotos] = useState<File[]>([]);
  const [previewUrls, setPreviewUrls] = useState<string[]>([]);
  const [previewIndex, setPreviewIndex] = useState<number | null>(null);

  const availableObjects = useMemo(() => {
    const allowed = new Set(profileObjectsQuery.data ?? []);
    return (objectsQuery.data ?? []).filter(
      (item) => item.status === "active" && allowed.has(item.id)
    );
  }, [objectsQuery.data, profileObjectsQuery.data]);

  useEffect(() => {
    if (availableObjects.length === 1 && !objectId) {
      setObjectId(availableObjects[0].id);
    }
  }, [availableObjects, objectId]);

  useEffect(() => {
    const urls = photos.map((file) => URL.createObjectURL(file));
    setPreviewUrls(urls);
    return () => {
      urls.forEach((url) => URL.revokeObjectURL(url));
    };
  }, [photos]);

  const occupied = useMemo(
    () => new Set(occupiedQuery.data ?? []),
    [occupiedQuery.data]
  );

  const availableEmployees = useMemo(() => {
    if (!objectId) {
      return [];
    }
    return (employeesQuery.data ?? [])
      .filter(
        (employee) =>
          employee.status === "working" &&
          employee.objectIds.includes(objectId) &&
          !occupied.has(employee.id)
      )
      .sort((a, b) =>
        employeeFullName(a).localeCompare(employeeFullName(b), "ru")
      );
  }, [employeesQuery.data, objectId, occupied]);

  const objectItems = availableObjects.map((item) => ({
    value: item.id,
    label: item.name,
  }));

  const isSaving = openMutation.isPending;
  const canSave =
    Boolean(objectId && photos.length > 0 && employeeIds.length > 0) &&
    !isSaving;

  function toggleEmployee(id: string) {
    setEmployeeIds((current) =>
      current.includes(id)
        ? current.filter((item) => item !== id)
        : [...current, id]
    );
  }

  function addPhotos(files: File[]) {
    const images = files.filter((file) => file.type.startsWith("image/"));
    if (images.length === 0) {
      toast.error("Выберите изображение");
      return;
    }
    setPhotos((current) => {
      const room = MAX_MORNING_PHOTOS - current.length;
      if (room <= 0) {
        toast.error("Можно приложить не больше 4 фото");
        return current;
      }
      if (images.length > room) {
        toast.error(`Добавлены только ${room} из выбранных. Максимум 4 фото.`);
      }
      return [...current, ...images.slice(0, room)];
    });
  }

  function replacePhoto(index: number, file: File | null) {
    if (!file) {
      return;
    }
    if (!file.type.startsWith("image/")) {
      toast.error("Выберите изображение");
      return;
    }
    setPhotos((current) =>
      current.map((item, itemIndex) => (itemIndex === index ? file : item))
    );
  }

  function removePhoto(index: number) {
    setPhotos((current) => current.filter((_, itemIndex) => itemIndex !== index));
    setPreviewIndex(null);
  }

  async function handleSave() {
    if (!objectId || photos.length === 0) {
      return;
    }
    if (employeeIds.length === 0) {
      toast.error("Выберите хотя бы одного сотрудника");
      return;
    }
    try {
      const work = await openMutation.mutateAsync({
        objectId,
        employeeIds,
        photos,
        employees: employeesQuery.data ?? [],
      });
      toast.success("Смена открыта");
      onOpened(work);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось открыть смену"
      );
    }
  }

  const actions = (
    <>
      <Button type="button" variant="outline" onClick={onCancel}>
        Отмена
      </Button>
      <Button type="button" disabled={!canSave} onClick={() => void handleSave()}>
        {isSaving ? <Spinner data-icon="inline-start" /> : null}
        Открыть
      </Button>
    </>
  );

  const fields = (
    <>
        <Field>
          <FieldLabel htmlFor="open-object">Объект</FieldLabel>
          <Select
            value={objectId}
            items={objectItems}
            disabled={
              objectsQuery.isLoading ||
              profileObjectsQuery.isLoading ||
              objectItems.length === 0
            }
            onValueChange={(next) => {
              if (typeof next !== "string") {
                return;
              }
              setObjectId(next);
              setEmployeeIds([]);
            }}
          >
            <SelectTrigger id="open-object" className="w-full">
              <SelectValue
                placeholder={
                  objectItems.length === 0
                    ? "Нет доступных объектов"
                    : "Выберите объект"
                }
              />
            </SelectTrigger>
            <SelectContent align="start">
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

        <div className="flex flex-col gap-2">
          <p className="text-sm font-medium">Сотрудники</p>
          <FieldDescription>
            Только работающие на выбранном объекте, кого ещё нет в открытой смене сегодня.
          </FieldDescription>
          {!objectId ? (
            <p className="rounded-lg border p-4 text-sm text-muted-foreground">
              Сначала выберите объект.
            </p>
          ) : occupiedQuery.isLoading || employeesQuery.isLoading ? (
            <div className="flex justify-center p-6">
              <Spinner />
            </div>
          ) : availableEmployees.length === 0 ? (
            <p className="rounded-lg border p-4 text-sm text-muted-foreground">
              Нет свободных сотрудников на этом объекте.
            </p>
          ) : (
            <ul
              className={
                layout === "sheet"
                  ? "max-h-[calc(10*2.5rem)] divide-y overflow-y-auto overscroll-contain rounded-lg border"
                  : "max-h-56 divide-y overflow-y-auto rounded-lg border"
              }
            >
              {availableEmployees.map((employee) => {
                const checked = employeeIds.includes(employee.id);
                return (
                  <li key={employee.id}>
                    <label
                      className={
                        layout === "sheet"
                          ? "flex min-h-10 cursor-pointer items-center gap-2 px-3 text-sm"
                          : "flex cursor-pointer items-center gap-2 px-3 py-2 text-sm"
                      }
                    >
                      <input
                        type="checkbox"
                        className="size-4 accent-foreground"
                        checked={checked}
                        onChange={() => toggleEmployee(employee.id)}
                      />
                      <span className="min-w-0 flex-1">
                        <span className="block font-medium">
                          {employeeFullName(employee)}
                        </span>
                        {layout === "sheet" ? null : (
                          <span className="block text-xs text-muted-foreground">
                            {employee.position.trim() || "Должность не указана"}
                          </span>
                        )}
                      </span>
                    </label>
                  </li>
                );
              })}
            </ul>
          )}
        </div>

        <Field>
          <FieldLabel>Фото смены</FieldLabel>
          <FieldDescription>
            До 4 снимков. Несколько фото сохранятся одним коллажем.
          </FieldDescription>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            multiple
            className="sr-only"
            onChange={(event) => {
              const files = Array.from(event.target.files ?? []);
              event.target.value = "";
              if (previewIndex !== null) {
                replacePhoto(previewIndex, files[0] ?? null);
                return;
              }
              addPhotos(files);
            }}
          />
          {previewUrls.length === 0 ? (
            <Button
              type="button"
              variant="outline"
              className="w-full"
              disabled={!objectId}
              onClick={() => fileRef.current?.click()}
            >
              <ImagePlusIcon data-icon="inline-start" />
              {objectId ? "Добавить фото" : "Сначала выберите объект"}
            </Button>
          ) : (
            <div className="flex flex-col gap-2">
              <div
                className={cn(
                  "grid overflow-hidden rounded-lg border bg-neutral-950 gap-px",
                  previewUrls.length === 1 && "grid-cols-1",
                  previewUrls.length >= 2 && "grid-cols-2",
                  previewUrls.length === 3 && "min-h-52 grid-rows-2"
                )}
              >
                {previewUrls.map((url, index) => (
                  <button
                    key={`${url}-${index}`}
                    type="button"
                    aria-label={`Открыть фото ${index + 1}`}
                    className={cn(
                      "overflow-hidden",
                      previewUrls.length === 1 && "max-h-52",
                      previewUrls.length === 2 && "aspect-[1/1]",
                      previewUrls.length === 3 &&
                        (index === 0 ? "row-span-2 min-h-0" : "aspect-square"),
                      previewUrls.length === 4 && "aspect-square"
                    )}
                    onClick={() => setPreviewIndex(index)}
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={url}
                      alt={`Утреннее фото ${index + 1}`}
                      className="size-full object-cover"
                    />
                  </button>
                ))}
              </div>
              {photos.length < MAX_MORNING_PHOTOS ? (
                <Button
                  type="button"
                  variant="outline"
                  className="w-full"
                  onClick={() => fileRef.current?.click()}
                >
                  <ImagePlusIcon data-icon="inline-start" />
                  Добавить ещё
                </Button>
              ) : null}
            </div>
          )}
          <Dialog
            open={previewIndex !== null}
            onOpenChange={(open) => {
              if (!open) {
                setPreviewIndex(null);
              }
            }}
          >
            <DialogContent
              showCloseButton={false}
              className="flex max-h-[92vh] max-w-lg flex-col gap-0 overflow-hidden p-0"
            >
              <DialogTitle className="sr-only">Утреннее фото</DialogTitle>
              <DialogDescription className="sr-only">
                Просмотр фото. Можно заменить или удалить.
              </DialogDescription>
              <div className="relative bg-black">
                <button
                  type="button"
                  className="absolute top-3 right-3 z-10 flex size-8 items-center justify-center rounded-full bg-black/60 text-white hover:bg-black/80"
                  aria-label="Закрыть"
                  onClick={() => setPreviewIndex(null)}
                >
                  <XIcon className="size-4" />
                </button>
                {previewIndex !== null && previewUrls[previewIndex] ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={previewUrls[previewIndex]}
                    alt={`Утреннее фото ${previewIndex + 1}`}
                    className="max-h-[70vh] w-full object-contain"
                  />
                ) : null}
              </div>
              <DialogFooter className="mx-0 mb-0">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => fileRef.current?.click()}
                >
                  <ImagePlusIcon data-icon="inline-start" />
                  Заменить
                </Button>
                <Button
                  type="button"
                  variant="destructive"
                  onClick={() => {
                    if (previewIndex !== null) {
                      removePhoto(previewIndex);
                    }
                  }}
                >
                  <Trash2Icon data-icon="inline-start" />
                  Удалить
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </Field>
    </>
  );

  if (layout === "sheet") {
    return (
      <>
        <MobileSheetChrome
          title="Открытие смены"
          description={`Смена на ${formatRuDate(toDateKey(new Date()))}. Выберите объект, сотрудников и утреннее фото.`}
          confirmLabel="Открыть"
          confirmDisabled={!canSave}
          confirmPending={isSaving}
          confirmShowLabelWhenEnabled
          onConfirm={() => void handleSave()}
        />
        <MobileSheetBody>{fields}</MobileSheetBody>
      </>
    );
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col gap-3 overflow-hidden">
      <div className="flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto">
        {fields}
      </div>
      <DialogFooter className="shrink-0 border-0 bg-transparent">
        {actions}
      </DialogFooter>
    </div>
  );
}

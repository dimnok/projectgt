"use client";

import { useState } from "react";
import { toast } from "sonner";
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  ImagePlusIcon,
  RefreshCwIcon,
  Trash2Icon,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { WorkPhotoKind } from "@/features/works/api/upload-work-photo";
import {
  useAddWorkShiftPhotos,
  useDeleteWorkShiftPhotoAt,
  useReplaceWorkShiftPhotoAt,
} from "@/features/works/hooks/use-open-work";
import { WorkPhotoDeleteDialog } from "@/features/works/ui/shared/work-photo-delete-dialog";
import { WorkPhotoSourceButton } from "@/features/works/ui/shared/work-photo-source-button";
import type { Work } from "@/features/works/types/work.types";
import {
  MAX_WORK_PHOTOS_PER_KIND,
  extractPhotoTime,
} from "@/features/works/utils/work.utils";
import { cn } from "@/lib/utils";

type WorkPhotoGalleryProps = {
  work: Work;
  kind: WorkPhotoKind;
  canModify: boolean;
  /** Компактный режим: маленькие превью в строку — для блока закрытия смены. */
  compact?: boolean;
  className?: string;
};

const KIND_TITLE: Record<WorkPhotoKind, string> = {
  morning: "Утро",
  evening: "Вечер",
};

const KIND_LABEL: Record<WorkPhotoKind, string> = {
  morning: "утреннее",
  evening: "вечернее",
};

/**
 * Список фото смены одного вида (утро или вечер): до 4 штук,
 * с заменой и удалением каждого фото, пока смена открыта.
 */
export function WorkPhotoGallery({
  work,
  kind,
  canModify,
  compact = false,
  className,
}: WorkPhotoGalleryProps) {
  const photos = kind === "morning" ? work.photoUrls : work.eveningPhotoUrls;
  const addMutation = useAddWorkShiftPhotos();
  const replaceMutation = useReplaceWorkShiftPhotoAt();
  const deleteMutation = useDeleteWorkShiftPhotoAt();
  const [previewIndex, setPreviewIndex] = useState<number | null>(null);
  const [deleteIndex, setDeleteIndex] = useState<number | null>(null);

  const isBusy =
    addMutation.isPending ||
    replaceMutation.isPending ||
    deleteMutation.isPending;
  const canAdd = canModify && photos.length < MAX_WORK_PHOTOS_PER_KIND;
  const label = KIND_LABEL[kind];
  const activeIndex =
    previewIndex !== null && previewIndex < photos.length ? previewIndex : null;
  const activeUrl = activeIndex !== null ? photos[activeIndex] : null;

  if (photos.length === 0 && !canAdd) {
    return null;
  }

  async function handleAdd(files: File[]) {
    try {
      await addMutation.mutateAsync({ work, files, kind });
      toast.success(
        files.length > 1 ? "Фото добавлены" : `${label} фото сохранено`
      );
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось загрузить фото"
      );
    }
  }

  async function handleReplace(index: number, file: File) {
    try {
      await replaceMutation.mutateAsync({ work, file, kind, index });
      toast.success(`${label} фото заменено`);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось заменить фото"
      );
    }
  }

  async function handleDelete() {
    if (deleteIndex === null) {
      return;
    }
    try {
      await deleteMutation.mutateAsync({ work, kind, index: deleteIndex });
      toast.success("Фото удалено");
      setDeleteIndex(null);
      setPreviewIndex(null);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось удалить фото"
      );
    }
  }

  function shiftPreview(delta: number) {
    if (activeIndex === null || photos.length < 2) {
      return;
    }
    setPreviewIndex((activeIndex + delta + photos.length) % photos.length);
  }

  const deleteDescription =
    kind === "evening" && photos.length === 1
      ? "Это последнее вечернее фото. Без него смену нельзя закрыть."
      : "Фото будет удалено из смены без возможности восстановления.";

  return (
    <>
      <div className={cn("flex flex-col gap-2", className)}>
        {photos.length > 0 ? (
          <div
            className={cn(
              compact
                ? "flex flex-wrap items-center gap-2"
                : "grid grid-cols-2 gap-2 sm:grid-cols-4"
            )}
          >
            {photos.map((url, index) => (
              <div
                key={`${url}-${index}`}
                className={cn(
                  "relative overflow-hidden border border-border/70 bg-muted",
                  compact ? "size-20 shrink-0 rounded-lg" : "rounded-lg"
                )}
              >
                <button
                  type="button"
                  aria-label={`Открыть ${label} фото ${index + 1}`}
                  className="block w-full outline-none focus-visible:ring-1 focus-visible:ring-ring"
                  onClick={() => setPreviewIndex(index)}
                >
                  {/* Публичная ссылка из bucket `works`, как в приложении. */}
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={url}
                    alt={`${KIND_TITLE[kind]} · фото ${index + 1}`}
                    className={cn(
                      "w-full object-cover",
                      compact ? "size-20" : "aspect-square"
                    )}
                  />
                </button>
                {compact ? null : (
                  <span className="pointer-events-none absolute top-1 left-1 rounded bg-black/55 px-1.5 py-0.5 text-[10px] font-medium text-white tabular-nums">
                    {index + 1}
                  </span>
                )}
                {canModify ? (
                  <div
                    className={cn(
                      "absolute flex items-center gap-1",
                      compact ? "right-0.5 bottom-0.5" : "right-1 bottom-1"
                    )}
                  >
                    <WorkPhotoSourceButton
                      label={`Заменить ${label} фото`}
                      icon={RefreshCwIcon}
                      variant="secondary"
                      size="icon-xs"
                      iconOnly
                      isBusy={isBusy}
                      onPick={(files) => {
                        const file = files[0];
                        if (file) {
                          void handleReplace(index, file);
                        }
                      }}
                    />
                    <Button
                      type="button"
                      variant="secondary"
                      size="icon-xs"
                      className="text-destructive hover:text-destructive"
                      aria-label={`Удалить ${label} фото`}
                      title={`Удалить ${label} фото`}
                      disabled={isBusy}
                      onClick={() => setDeleteIndex(index)}
                    >
                      <Trash2Icon />
                    </Button>
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        ) : null}
        {canAdd ? (
          <WorkPhotoSourceButton
            label={photos.length === 0 ? `Добавить ${label} фото` : "Добавить фото"}
            icon={ImagePlusIcon}
            variant="outline"
            size={photos.length === 0 ? "default" : "sm"}
            multiple
            isBusy={isBusy}
            className={photos.length === 0 ? "w-full" : "self-start"}
            onPick={(files) => void handleAdd(files)}
          />
        ) : null}
        {photos.length >= MAX_WORK_PHOTOS_PER_KIND ? (
          <p className="text-xs text-muted-foreground">
            Загружено максимум — {MAX_WORK_PHOTOS_PER_KIND} фото. Можно заменить
            или удалить любое.
          </p>
        ) : null}
      </div>

      <Dialog
        open={activeIndex !== null}
        onOpenChange={(open) => {
          if (!open) {
            setPreviewIndex(null);
          }
        }}
      >
        <DialogContent className="max-w-3xl p-0 sm:max-w-3xl">
          <DialogHeader className="px-4 pt-4">
            <DialogTitle>
              {KIND_TITLE[kind]}
              {activeUrl ? ` · ${extractPhotoTime(activeUrl) ?? ""}` : ""}
              {photos.length > 1 && activeIndex !== null
                ? ` · ${activeIndex + 1} из ${photos.length}`
                : ""}
            </DialogTitle>
            <DialogDescription className="sr-only">
              Фото смены
            </DialogDescription>
          </DialogHeader>
          {activeUrl ? (
            <div className="relative bg-muted">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={activeUrl}
                alt={`${KIND_TITLE[kind]} · фото ${(activeIndex ?? 0) + 1}`}
                className="max-h-[80vh] w-full object-contain"
              />
              {photos.length > 1 ? (
                <>
                  <Button
                    type="button"
                    variant="secondary"
                    size="icon-sm"
                    className="absolute top-1/2 left-2 -translate-y-1/2 rounded-full"
                    aria-label="Предыдущее фото"
                    onClick={() => shiftPreview(-1)}
                  >
                    <ChevronLeftIcon />
                  </Button>
                  <Button
                    type="button"
                    variant="secondary"
                    size="icon-sm"
                    className="absolute top-1/2 right-2 -translate-y-1/2 rounded-full"
                    aria-label="Следующее фото"
                    onClick={() => shiftPreview(1)}
                  >
                    <ChevronRightIcon />
                  </Button>
                </>
              ) : null}
            </div>
          ) : null}
          {canModify && activeIndex !== null ? (
            <DialogFooter className="mx-0 mb-0 rounded-b-xl px-4 py-3">
              <WorkPhotoSourceButton
                label="Заменить фото"
                icon={RefreshCwIcon}
                variant="outline"
                size="sm"
                isBusy={isBusy}
                onPick={(files) => {
                  const file = files[0];
                  if (file) {
                    void handleReplace(activeIndex, file);
                  }
                }}
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="text-destructive hover:text-destructive"
                disabled={isBusy}
                onClick={() => setDeleteIndex(activeIndex)}
              >
                <Trash2Icon data-icon="inline-start" />
                Удалить фото
              </Button>
            </DialogFooter>
          ) : null}
        </DialogContent>
      </Dialog>

      <WorkPhotoDeleteDialog
        open={deleteIndex !== null}
        isDeleting={deleteMutation.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setDeleteIndex(null);
          }
        }}
        onConfirm={() => void handleDelete()}
        title={`Удалить ${label} фото?`}
        description={deleteDescription}
      />
    </>
  );
}

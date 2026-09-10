"use client";

import { useRef, useState } from "react";
import {
  DownloadIcon,
  EyeIcon,
  PlusIcon,
  Trash2Icon,
  UploadIcon,
  XIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { downloadEmployeePhoto } from "@/features/employees/api/manage-employee-photo";
import {
  useDeleteEmployeePhoto,
  useUploadEmployeePhoto,
} from "@/features/employees/hooks/use-employee-photo";
import type { Employee } from "@/features/employees/types/employee.types";
import {
  employeeFullName,
  employeeInitials,
} from "@/features/employees/utils/employee.utils";
import { cn } from "@/lib/utils";

type EmployeeAvatarManagerProps = {
  employee: Employee;
  canUpdate: boolean;
  onPhotoChanged?: (newPhotoUrl: string | null) => void;
  className?: string;
};

export function EmployeeAvatarManager({
  employee,
  canUpdate,
  onPhotoChanged,
  className,
}: EmployeeAvatarManagerProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isPreviewOpen, setIsPreviewOpen] = useState(false);
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false);

  const uploadPhotoMutation = useUploadEmployeePhoto();
  const deletePhotoMutation = useDeleteEmployeePhoto();

  const isBusy =
    uploadPhotoMutation.isPending || deletePhotoMutation.isPending;
  const fullName = employeeFullName(employee);
  const hasPhoto = Boolean(employee.photoUrl);

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Сброс значения, чтобы выбор того же файла снова срабатывал
    e.target.value = "";

    if (!file.type.startsWith("image/")) {
      toast.error("Пожалуйста, выберите файл изображения (JPG, PNG, WebP)");
      return;
    }

    if (file.size > 20 * 1024 * 1024) {
      toast.error("Размер файла не должен превышать 20 МБ");
      return;
    }

    uploadPhotoMutation.mutate(
      { employee, file },
      {
        onSuccess: (url) => {
          toast.success("Фотография успешно обновлена");
          onPhotoChanged?.(url);
        },
        onError: (err) => {
          toast.error(
            err instanceof Error
              ? err.message
              : "Не удалось загрузить фотографию"
          );
        },
      }
    );
  };

  const handleTriggerUpload = () => {
    if (!canUpdate || isBusy) return;
    fileInputRef.current?.click();
  };

  const handleDownload = async (e?: React.MouseEvent) => {
    e?.stopPropagation();
    if (!employee.photoUrl) return;
    try {
      await downloadEmployeePhoto(employee.photoUrl, employee);
    } catch {
      toast.error("Не удалось скачать фотографию");
    }
  };

  const handleDelete = () => {
    deletePhotoMutation.mutate(employee, {
      onSuccess: () => {
        setIsDeleteConfirmOpen(false);
        toast.success("Фотография удалена");
        onPhotoChanged?.(null);
      },
      onError: (err) => {
        toast.error(
          err instanceof Error ? err.message : "Не удалось удалить фотографию"
        );
      },
    });
  };

  const handlePhotoClick = () => {
    if (isBusy) return;
    if (hasPhoto) {
      setIsPreviewOpen(true);
    } else if (canUpdate) {
      handleTriggerUpload();
    }
  };

  return (
    <div className={cn("flex flex-col items-center gap-2.5 sm:items-start", className)}>
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        disabled={!canUpdate || isBusy}
        onChange={handleFileSelect}
      />

      {/* Фото-карточка сотрудника */}
      <div
        role={hasPhoto || canUpdate ? "button" : undefined}
        tabIndex={hasPhoto || canUpdate ? 0 : undefined}
        onClick={handlePhotoClick}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            handlePhotoClick();
          }
        }}
        className={cn(
          "relative size-28 sm:size-32 shrink-0 overflow-hidden rounded-2xl border border-border/80 bg-muted/40 shadow-xs select-none transition-all",
          hasPhoto &&
            "cursor-pointer hover:border-primary/50 hover:shadow-sm",
          !hasPhoto &&
            canUpdate &&
            "cursor-pointer hover:border-primary/50 hover:bg-muted/70",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        )}
        title={hasPhoto ? "Нажмите для просмотра в полном размере" : canUpdate ? "Нажмите для загрузки фото" : undefined}
      >
        {hasPhoto && employee.photoUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={employee.photoUrl}
            alt={fullName}
            className="block size-full rounded-2xl object-cover"
          />
        ) : (
          <div className="flex size-full flex-col items-center justify-center gap-1 rounded-2xl bg-gradient-to-br from-muted/80 to-muted text-foreground p-2 text-center">
            <span className="text-2xl font-bold tracking-tight text-foreground sm:text-3xl">
              {employeeInitials(employee)}
            </span>
            {canUpdate ? (
              <span className="text-[10px] font-medium text-muted-foreground leading-tight">
                Загрузить фото
              </span>
            ) : null}
          </div>
        )}

        {/* Индикатор загрузки / удаления */}
        {isBusy ? (
          <div className="absolute inset-0 z-10 flex flex-col items-center justify-center gap-1.5 rounded-2xl bg-background/85 backdrop-blur-xs">
            <Spinner className="size-6 text-primary" />
            <span className="text-[11px] font-medium text-foreground">
              {uploadPhotoMutation.isPending ? "Загрузка…" : "Удаление…"}
            </span>
          </div>
        ) : null}
      </div>

      {/* Панель управляющих кнопок под фото */}
      <div className="flex items-center gap-1">
        {hasPhoto ? (
          <>
            <Tooltip>
              <TooltipTrigger
                render={
                  <Button
                    type="button"
                    variant="outline"
                    size="icon-xs"
                    className="size-7 rounded-lg"
                    aria-label="Просмотреть фото"
                    onClick={() => setIsPreviewOpen(true)}
                  />
                }
              >
                <EyeIcon className="size-3.5" />
              </TooltipTrigger>
              <TooltipContent side="bottom">Просмотреть</TooltipContent>
            </Tooltip>

            <Tooltip>
              <TooltipTrigger
                render={
                  <Button
                    type="button"
                    variant="outline"
                    size="icon-xs"
                    className="size-7 rounded-lg"
                    aria-label="Скачать фото"
                    onClick={handleDownload}
                  />
                }
              >
                <DownloadIcon className="size-3.5" />
              </TooltipTrigger>
              <TooltipContent side="bottom">Скачать оригинал</TooltipContent>
            </Tooltip>

            {canUpdate ? (
              <>
                <Tooltip>
                  <TooltipTrigger
                    render={
                      <Button
                        type="button"
                        variant="outline"
                        size="icon-xs"
                        className="size-7 rounded-lg"
                        aria-label="Заменить фото"
                        disabled={isBusy}
                        onClick={handleTriggerUpload}
                      />
                    }
                  >
                    <UploadIcon className="size-3.5" />
                  </TooltipTrigger>
                  <TooltipContent side="bottom">Заменить фото</TooltipContent>
                </Tooltip>

                <Tooltip>
                  <TooltipTrigger
                    render={
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon-xs"
                        className="size-7 rounded-lg text-destructive hover:bg-destructive/10 hover:text-destructive"
                        aria-label="Удалить фото"
                        disabled={isBusy}
                        onClick={() => setIsDeleteConfirmOpen(true)}
                      />
                    }
                  >
                    <Trash2Icon className="size-3.5" />
                  </TooltipTrigger>
                  <TooltipContent side="bottom">Удалить фото</TooltipContent>
                </Tooltip>
              </>
            ) : null}
          </>
        ) : canUpdate ? (
          <Button
            type="button"
            variant="outline"
            size="xs"
            className="h-6.5 gap-1.5 rounded-lg px-2.5 text-xs font-normal"
            disabled={isBusy}
            onClick={handleTriggerUpload}
          >
            <PlusIcon className="size-3" />
            <span>Добавить фото</span>
          </Button>
        ) : null}
      </div>

      {/* Модальное окно полноразмерного просмотра фото */}
      <Dialog open={isPreviewOpen} onOpenChange={setIsPreviewOpen}>
        <DialogContent
          className="flex max-h-[92vh] max-w-2xl flex-col gap-0 overflow-hidden rounded-2xl border border-border/80 p-0 shadow-2xl"
          showCloseButton={false}
        >
          <div className="relative flex max-h-[75vh] items-center justify-center overflow-hidden bg-black/90 p-4">
            <button
              type="button"
              onClick={() => setIsPreviewOpen(false)}
              className="absolute top-3 right-3 z-10 flex size-8 items-center justify-center rounded-full bg-black/60 text-white transition-colors hover:bg-black/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white"
              aria-label="Закрыть просмотр"
            >
              <XIcon className="size-4" />
            </button>
            {employee.photoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={employee.photoUrl}
                alt={fullName}
                className="max-h-[70vh] w-auto max-w-full rounded-xl object-contain shadow-lg"
              />
            ) : null}
          </div>
          <div className="flex items-center justify-between border-t border-border/60 bg-card px-5 py-3">
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold text-foreground">
                {fullName}
              </p>
              <p className="truncate text-xs text-muted-foreground">
                {employee.position || "Сотрудник"}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="gap-1.5"
                onClick={handleDownload}
              >
                <DownloadIcon className="size-3.5" />
                <span>Скачать</span>
              </Button>
              <DialogClose render={<Button type="button" variant="secondary" size="sm" />}>
                Закрыть
              </DialogClose>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Диалог подтверждения удаления фото */}
      <Dialog
        open={isDeleteConfirmOpen}
        onOpenChange={setIsDeleteConfirmOpen}
      >
        <DialogContent className="max-w-md rounded-2xl p-5">
          <DialogHeader>
            <DialogTitle>Удалить фотографию?</DialogTitle>
            <DialogDescription>
              Фотография сотрудника {fullName} будет безвозвратно удалена.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              type="button"
              variant="outline"
              disabled={deletePhotoMutation.isPending}
              onClick={() => setIsDeleteConfirmOpen(false)}
            >
              Отмена
            </Button>
            <Button
              type="button"
              variant="destructive"
              disabled={deletePhotoMutation.isPending}
              onClick={handleDelete}
              className="gap-1.5"
            >
              {deletePhotoMutation.isPending ? (
                <Spinner className="size-3.5" />
              ) : (
                <Trash2Icon className="size-3.5" />
              )}
              Удалить
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

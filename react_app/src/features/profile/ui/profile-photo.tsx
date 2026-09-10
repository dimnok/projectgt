"use client";

import { useRef, useState } from "react";
import { CameraIcon, Trash2Icon, XIcon } from "lucide-react";
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
import { Spinner } from "@/components/ui/spinner";
import {
  useDeleteProfilePhoto,
  useUploadProfilePhoto,
} from "@/features/profile/hooks/use-current-profile";
import type { CurrentProfile } from "@/features/profile/types/profile.types";
import {
  profileDisplayName,
  profileInitials,
} from "@/features/profile/utils/profile.utils";
import { cn } from "@/lib/utils";

type ProfilePhotoProps = {
  profile: CurrentProfile;
};

export function ProfilePhoto({ profile }: ProfilePhotoProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isPreviewOpen, setIsPreviewOpen] = useState(false);
  const [isDeleteOpen, setIsDeleteOpen] = useState(false);
  const uploadPhoto = useUploadProfilePhoto();
  const deletePhoto = useDeleteProfilePhoto();
  const isBusy = uploadPhoto.isPending || deletePhoto.isPending;
  const name = profileDisplayName(profile);
  const hasPhoto = Boolean(profile.photoUrl);

  async function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) {
      return;
    }

    if (!file.type.startsWith("image/")) {
      toast.error("Выберите изображение: JPG, PNG или WebP");
      return;
    }

    if (file.size > 20 * 1024 * 1024) {
      toast.error("Файл не должен быть больше 20 МБ");
      return;
    }

    try {
      await uploadPhoto.mutateAsync(file);
      toast.success("Фото обновлено");
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось загрузить фото"
      );
    }
  }

  async function handleDelete() {
    try {
      await deletePhoto.mutateAsync();
      setIsDeleteOpen(false);
      toast.success("Фото удалено");
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось удалить фото"
      );
    }
  }

  return (
    <div className="flex flex-col items-start gap-3">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/heic"
        className="sr-only"
        onChange={handleFileChange}
      />
      <div
        className={cn(
          "group relative size-32 shrink-0 overflow-hidden rounded-2xl bg-muted ring-1 ring-foreground/10 sm:size-36"
        )}
      >
        {hasPhoto ? (
          <button
            type="button"
            className="size-full"
            onClick={() => setIsPreviewOpen(true)}
            aria-label="Открыть фото"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={profile.photoUrl ?? ""}
              alt={name}
              className="size-full object-cover"
            />
          </button>
        ) : (
          <div className="flex size-full items-center justify-center bg-gradient-to-br from-muted to-muted/60">
            <span className="text-3xl font-semibold tracking-tight text-muted-foreground">
              {profileInitials(name)}
            </span>
          </div>
        )}

        {isBusy ? (
          <div className="absolute inset-0 z-10 flex items-center justify-center bg-background/80">
            <Spinner className="size-6" />
          </div>
        ) : (
          <button
            type="button"
            className="absolute right-2 bottom-2 flex size-8 items-center justify-center rounded-full bg-background/90 text-foreground shadow-sm ring-1 ring-foreground/10 transition-opacity hover:bg-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring sm:opacity-0 sm:group-hover:opacity-100"
            aria-label={hasPhoto ? "Заменить фото" : "Загрузить фото"}
            onClick={() => fileInputRef.current?.click()}
          >
            <CameraIcon className="size-4" />
          </button>
        )}
      </div>

      {hasPhoto ? (
        <Button
          type="button"
          variant="ghost"
          size="xs"
          className="text-destructive hover:bg-destructive/10 hover:text-destructive"
          disabled={isBusy}
          onClick={() => setIsDeleteOpen(true)}
        >
          <Trash2Icon />
          Удалить фото
        </Button>
      ) : (
        <Button
          type="button"
          variant="outline"
          size="xs"
          disabled={isBusy}
          onClick={() => fileInputRef.current?.click()}
        >
          <CameraIcon />
          Добавить фото
        </Button>
      )}

      <Dialog open={isPreviewOpen} onOpenChange={setIsPreviewOpen}>
        <DialogContent
          className="flex max-h-[92vh] max-w-lg flex-col gap-0 overflow-hidden p-0"
          showCloseButton={false}
        >
          <div className="relative bg-black">
            <button
              type="button"
              className="absolute top-3 right-3 z-10 flex size-8 items-center justify-center rounded-full bg-black/60 text-white hover:bg-black/80"
              aria-label="Закрыть"
              onClick={() => setIsPreviewOpen(false)}
            >
              <XIcon className="size-4" />
            </button>
            {profile.photoUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={profile.photoUrl}
                alt={name}
                className="max-h-[80vh] w-full object-contain"
              />
            ) : null}
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={isDeleteOpen} onOpenChange={setIsDeleteOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Удалить фото?</DialogTitle>
            <DialogDescription>
              Фотография будет удалена из профиля.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsDeleteOpen(false)}
            >
              Отмена
            </Button>
            <Button
              type="button"
              variant="destructive"
              disabled={deletePhoto.isPending}
              onClick={() => void handleDelete()}
            >
              {deletePhoto.isPending ? <Spinner /> : <Trash2Icon />}
              Удалить
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

"use client";

import { useRef, useState } from "react";
import { CameraIcon, Trash2Icon, XIcon } from "lucide-react";
import { toast } from "sonner";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
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

type ProfilePhotoMobileProps = {
  profile: CurrentProfile;
};

export function ProfilePhotoMobile({ profile }: ProfilePhotoMobileProps) {
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
    <div className="flex flex-col items-center gap-3">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp,image/heic"
        className="sr-only"
        onChange={handleFileChange}
      />

      <div className="relative">
        <button
          type="button"
          className="rounded-full"
          aria-label={hasPhoto ? "Открыть фото" : "Добавить фото"}
          onClick={() => {
            if (hasPhoto) {
              setIsPreviewOpen(true);
              return;
            }
            fileInputRef.current?.click();
          }}
        >
          <Avatar className="size-24 after:rounded-full">
            {hasPhoto ? (
              <AvatarImage src={profile.photoUrl ?? ""} alt={name} />
            ) : null}
            <AvatarFallback className="text-2xl font-semibold">
              {profileInitials(name)}
            </AvatarFallback>
          </Avatar>
        </button>

        {isBusy ? (
          <div className="absolute inset-0 z-10 flex items-center justify-center rounded-full bg-background/80">
            <Spinner />
          </div>
        ) : (
          <Button
            type="button"
            variant="secondary"
            size="icon"
            className="absolute right-0 bottom-0 size-9 rounded-full shadow-sm"
            aria-label={hasPhoto ? "Заменить фото" : "Загрузить фото"}
            onClick={() => fileInputRef.current?.click()}
          >
            <CameraIcon />
          </Button>
        )}
      </div>

      {hasPhoto ? (
        <Button
          type="button"
          variant="ghost"
          size="sm"
          className="text-destructive hover:bg-destructive/10 hover:text-destructive"
          disabled={isBusy}
          onClick={() => setIsDeleteOpen(true)}
        >
          <Trash2Icon data-icon="inline-start" />
          Удалить фото
        </Button>
      ) : (
        <p className="text-xs text-muted-foreground">Нажмите, чтобы добавить фото</p>
      )}

      <Dialog open={isPreviewOpen} onOpenChange={setIsPreviewOpen}>
        <DialogContent
          className="flex max-h-[92vh] max-w-lg flex-col gap-0 overflow-hidden p-0"
          showCloseButton={false}
        >
          <DialogTitle className="sr-only">Фото профиля</DialogTitle>
          <DialogDescription className="sr-only">
            Просмотр фотографии профиля
          </DialogDescription>
          <div className="relative bg-black">
            <button
              type="button"
              className="absolute top-3 right-3 z-10 flex size-11 items-center justify-center rounded-full bg-black/60 text-white"
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
              {deletePhoto.isPending ? <Spinner /> : <Trash2Icon data-icon="inline-start" />}
              Удалить
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

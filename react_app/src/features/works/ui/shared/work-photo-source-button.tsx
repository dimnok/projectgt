"use client";

import { useRef, useState } from "react";
import type { ComponentProps } from "react";
import type { LucideIcon } from "lucide-react";
import { CameraIcon, ImageIcon } from "lucide-react";

import {
  MobileSheet,
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { useIsMobile } from "@/hooks/use-mobile";

type WorkPhotoSourceButtonProps = {
  /** Текст кнопки; в режиме только иконки уходит в `aria-label`. */
  label: string;
  icon: LucideIcon;
  onPick: (files: File[]) => void;
  variant?: ComponentProps<typeof Button>["variant"];
  size?: ComponentProps<typeof Button>["size"];
  className?: string;
  disabled?: boolean;
  isBusy?: boolean;
  /** Только иконка — для компактных мест вроде плитки фото. */
  iconOnly?: boolean;
  /** Разрешить выбрать сразу несколько файлов из галереи. */
  multiple?: boolean;
};

/**
 * Кнопка выбора фото смены. На телефоне сначала спрашивает источник
 * («Сделать фото» / «Выбрать из галереи»), на компьютере сразу открывает выбор файла.
 */
export function WorkPhotoSourceButton({
  label,
  icon: Icon,
  onPick,
  variant,
  size,
  className,
  disabled = false,
  isBusy = false,
  iconOnly = false,
  multiple = false,
}: WorkPhotoSourceButtonProps) {
  const isMobile = useIsMobile();
  const galleryRef = useRef<HTMLInputElement>(null);
  const cameraRef = useRef<HTMLInputElement>(null);
  const [isSourceOpen, setIsSourceOpen] = useState(false);
  const isDisabled = disabled || isBusy;

  function handleFiles(event: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(event.target.files ?? []);
    event.target.value = "";
    if (files.length > 0) {
      onPick(files);
    }
  }

  function handleClick() {
    if (isDisabled) {
      return;
    }
    if (isMobile) {
      setIsSourceOpen(true);
      return;
    }
    galleryRef.current?.click();
  }

  return (
    <>
      <input
        ref={galleryRef}
        type="file"
        accept="image/*"
        multiple={multiple}
        className="sr-only"
        onChange={handleFiles}
      />
      {isMobile ? (
        <input
          ref={cameraRef}
          type="file"
          accept="image/*"
          capture="environment"
          className="sr-only"
          onChange={handleFiles}
        />
      ) : null}
      <Button
        type="button"
        variant={variant}
        size={size}
        className={className}
        disabled={isDisabled}
        aria-label={iconOnly ? label : undefined}
        title={iconOnly ? label : undefined}
        onClick={handleClick}
      >
        {isBusy ? (
          <Spinner data-icon="inline-start" />
        ) : (
          <Icon data-icon="inline-start" />
        )}
        {iconOnly ? null : label}
      </Button>
      {isMobile ? (
        <MobileSheet open={isSourceOpen} onOpenChange={setIsSourceOpen}>
          <MobileSheetChrome
            title={label}
            description="Источник фотографии"
            confirmLabel="Готово"
            confirmShowLabelWhenEnabled
            onConfirm={() => setIsSourceOpen(false)}
          />
          <MobileSheetBody>
            <Button
              type="button"
              variant="ghost"
              className="h-11 w-full justify-start"
              onClick={() => {
                setIsSourceOpen(false);
                cameraRef.current?.click();
              }}
            >
              <CameraIcon data-icon="inline-start" />
              Сделать фото
            </Button>
            <Button
              type="button"
              variant="ghost"
              className="h-11 w-full justify-start"
              onClick={() => {
                setIsSourceOpen(false);
                galleryRef.current?.click();
              }}
            >
              <ImageIcon data-icon="inline-start" />
              Выбрать из галереи
            </Button>
          </MobileSheetBody>
        </MobileSheet>
      ) : null}
    </>
  );
}

"use client";

import { DownloadIcon, Maximize2Icon, Minimize2Icon, XIcon } from "lucide-react";
import { useState } from "react";

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
import type { PurchaseRequestFile } from "@/features/purchase-requests/types/purchase-request.types";
import { PurchaseRequestFilePreviewContent } from "@/features/purchase-requests/ui/shared/purchase-request-file-preview-content";
import { cn } from "@/lib/utils";

type PurchaseRequestFilePreviewDialogProps = {
  /** Файл счёта. `null` — окно закрыто. */
  file: PurchaseRequestFile | null;
  /** Адрес уже загруженного файла (blob). */
  url: string | null;
  /** Скачивание файла на устройство. */
  onDownload: () => void;
  /** Закрытие окна. */
  onOpenChange: (open: boolean) => void;
};

/**
 * Просмотр счёта прямо в приложении.
 *
 * PDF показываем встроенным просмотрщиком браузера, картинку — целиком в окне.
 * Раньше файл открывался в новой вкладке: на телефоне это выглядело как выход
 * из приложения в браузер.
 */
export function PurchaseRequestFilePreviewDialog({
  file,
  url,
  onDownload,
  onOpenChange,
}: PurchaseRequestFilePreviewDialogProps) {
  const [isMaximized, setIsMaximized] = useState(false);
  const isOpen = Boolean(file && url);

  // Для другого файла окно открывается в обычном размере.
  const [lastFileId, setLastFileId] = useState(file?.id ?? null);
  if ((file?.id ?? null) !== lastFileId) {
    setLastFileId(file?.id ?? null);
    setIsMaximized(false);
  }

  /** Сброс разворота окна при закрытии. */
  function handleOpenChange(open: boolean) {
    if (!open) {
      setIsMaximized(false);
    }
    onOpenChange(open);
  }

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogContent
        showCloseButton={false}
        className={cn(
          "flex flex-col overflow-hidden",
          isMaximized
            ? "!h-[97vh] !max-h-[97vh] !w-[98vw] !max-w-[98vw] sm:!max-w-[98vw]"
            : "h-[min(88vh,58rem)] w-[min(94vw,60rem)] sm:max-w-[min(94vw,60rem)]"
        )}
      >
        {/* Кнопки управления окном: Развернуть / Восстановить + Закрыть */}
        <div className="absolute top-2.5 right-2.5 z-20 flex items-center gap-1">
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            onClick={() => setIsMaximized((previous) => !previous)}
            className="text-muted-foreground hover:text-foreground cursor-pointer"
            title={isMaximized ? "Восстановить размер" : "Развернуть на весь экран"}
            aria-label={isMaximized ? "Восстановить размер" : "Развернуть на весь экран"}
          >
            {isMaximized ? (
              <Minimize2Icon className="size-4" />
            ) : (
              <Maximize2Icon className="size-4" />
            )}
          </Button>
          <DialogClose
            render={
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                className="text-muted-foreground hover:text-foreground cursor-pointer"
                title="Закрыть"
                aria-label="Закрыть"
              />
            }
          >
            <XIcon className="size-4" />
          </DialogClose>
        </div>

        <DialogHeader className="shrink-0 pr-20">
          <DialogTitle className="truncate">
            {file?.fileName ?? "Счёт"}
          </DialogTitle>
          <DialogDescription>Просмотр счёта</DialogDescription>
        </DialogHeader>

        {file && url ? (
          <PurchaseRequestFilePreviewContent
            file={file}
            url={url}
            className="rounded-xl"
          />
        ) : null}

        <DialogFooter className="shrink-0">
          <Button type="button" variant="outline" onClick={onDownload}>
            <DownloadIcon />
            Скачать
          </Button>
          <DialogClose render={<Button type="button" />}>Закрыть</DialogClose>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

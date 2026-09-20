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
import { cn } from "@/lib/utils";

export type SettlementPreviewFile = {
  /** Отображаемое имя документа. */
  title: string;
  /** Адрес загруженного файла (blob-URL). */
  url: string;
  /** PDF — листается встроенным просмотрщиком, иначе показывается картинкой. */
  isPdf: boolean;
};

type SettlementFilePreviewDialogProps = {
  /** Файл для просмотра. `null` — окно закрыто. */
  file: SettlementPreviewFile | null;
  onDownload: () => void;
  onOpenChange: (open: boolean) => void;
};

/**
 * Просмотр документа прямо в приложении.
 *
 * PDF листается встроенным просмотрщиком браузера, картинка показывается
 * целиком. Файл не открывается в новой вкладке — на телефоне это выглядело
 * как выход из приложения.
 */
export function SettlementFilePreviewDialog({
  file,
  onDownload,
  onOpenChange,
}: SettlementFilePreviewDialogProps) {
  const [isMaximized, setIsMaximized] = useState(false);

  const [lastUrl, setLastUrl] = useState(file?.url ?? null);
  if ((file?.url ?? null) !== lastUrl) {
    setLastUrl(file?.url ?? null);
    setIsMaximized(false);
  }

  function handleOpenChange(open: boolean) {
    if (!open) {
      setIsMaximized(false);
    }
    onOpenChange(open);
  }

  return (
    <Dialog open={Boolean(file)} onOpenChange={handleOpenChange}>
      <DialogContent
        showCloseButton={false}
        className={cn(
          "flex flex-col overflow-hidden",
          isMaximized
            ? "!h-[97vh] !max-h-[97vh] !w-[98vw] !max-w-[98vw] sm:!max-w-[98vw]"
            : "h-[min(88vh,58rem)] w-[min(94vw,60rem)] sm:max-w-[min(94vw,60rem)]"
        )}
      >
        <div className="absolute top-2.5 right-2.5 z-20 flex items-center gap-1">
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            onClick={() => setIsMaximized((previous) => !previous)}
            className="text-muted-foreground hover:text-foreground cursor-pointer"
            title={isMaximized ? "Восстановить размер" : "Развернуть на весь экран"}
            aria-label={
              isMaximized ? "Восстановить размер" : "Развернуть на весь экран"
            }
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
            {file?.title ?? "Документ"}
          </DialogTitle>
          <DialogDescription>Просмотр документа</DialogDescription>
        </DialogHeader>

        <div className="flex min-h-0 flex-1 items-center justify-center overflow-auto rounded-xl bg-muted/40">
          {file ? (
            file.isPdf ? (
              <iframe
                src={file.url}
                title={file.title}
                className="h-full w-full border-0 bg-white"
              />
            ) : (
              // Blob-адрес загруженного файла: next/image здесь не нужен.
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={file.url}
                alt={file.title}
                className="max-h-full max-w-full object-contain"
              />
            )
          ) : null}
        </div>

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

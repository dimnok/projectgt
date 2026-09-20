"use client";

import { MobileSheetChrome } from "@/components/shared/mobile-sheet-chrome";
import { Sheet, SheetContent } from "@/components/ui/sheet";
import type { SettlementPreviewFile } from "@/features/settlements/ui/shared/settlement-file-preview-dialog";

type SettlementFilePreviewSheetProps = {
  /** Файл для просмотра. `null` — окно закрыто. */
  file: SettlementPreviewFile | null;
  /** Скачивание файла на устройство. */
  onDownload: () => void;
  /** Закрытие окна. */
  onOpenChange: (open: boolean) => void;
};

/**
 * Просмотр документа на весь экран (телефон).
 *
 * PDF листается встроенным просмотрщиком, картинка показывается целиком.
 * Высоту задаём тем же вариантом `data-[side=bottom]`, что и у базового окна,
 * иначе оно схлопывается по содержимому. Файл не покидает приложение.
 */
export function SettlementFilePreviewSheet({
  file,
  onDownload,
  onOpenChange,
}: SettlementFilePreviewSheetProps) {
  return (
    <Sheet open={Boolean(file)} onOpenChange={onOpenChange}>
      <SheetContent
        side="bottom"
        showCloseButton={false}
        overlayClassName="bg-black/60"
        className="data-[side=bottom]:h-[100dvh] data-[side=bottom]:max-h-[100dvh] w-full gap-0 overflow-hidden rounded-t-[28px] border-0 bg-background p-0 pt-[env(safe-area-inset-top)] pb-[env(safe-area-inset-bottom)] shadow-[0_-8px_40px_rgba(0,0,0,0.18)]"
      >
        <MobileSheetChrome
          title={file?.title ?? "Документ"}
          description="Просмотр документа"
          confirmLabel="Скачать"
          confirmShowLabelWhenEnabled
          onConfirm={onDownload}
        />

        <div className="flex min-h-0 flex-1 items-center justify-center overflow-auto bg-muted/40">
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
      </SheetContent>
    </Sheet>
  );
}

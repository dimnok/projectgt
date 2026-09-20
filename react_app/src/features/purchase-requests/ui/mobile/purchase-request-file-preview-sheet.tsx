"use client";

import { MobileSheetChrome } from "@/components/shared/mobile-sheet-chrome";
import { Sheet, SheetContent } from "@/components/ui/sheet";
import type { PurchaseRequestFile } from "@/features/purchase-requests/types/purchase-request.types";
import { PurchaseRequestFilePreviewContent } from "@/features/purchase-requests/ui/shared/purchase-request-file-preview-content";

type PurchaseRequestFilePreviewSheetProps = {
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
 * Просмотр счёта на весь экран (телефон).
 *
 * PDF листается встроенным просмотрщиком, картинка показывается целиком.
 * Высоту задаём тем же вариантом `data-[side=bottom]`, что и у базового окна,
 * иначе оно схлопывается по содержимому. Файл не покидает приложение.
 */
export function PurchaseRequestFilePreviewSheet({
  file,
  url,
  onDownload,
  onOpenChange,
}: PurchaseRequestFilePreviewSheetProps) {
  const isOpen = Boolean(file && url);

  return (
    <Sheet open={isOpen} onOpenChange={onOpenChange}>
      <SheetContent
        side="bottom"
        showCloseButton={false}
        overlayClassName="bg-black/60"
        className="data-[side=bottom]:h-[100dvh] data-[side=bottom]:max-h-[100dvh] w-full gap-0 overflow-hidden rounded-t-[28px] border-0 bg-background p-0 pt-[env(safe-area-inset-top)] pb-[env(safe-area-inset-bottom)] shadow-[0_-8px_40px_rgba(0,0,0,0.18)]"
      >
        <MobileSheetChrome
          title={file?.fileName ?? "Счёт"}
          description="Просмотр счёта"
          confirmLabel="Скачать"
          confirmShowLabelWhenEnabled
          onConfirm={onDownload}
        />

        <div className="flex min-h-0 flex-1 flex-col">
          {file && url ? (
            <PurchaseRequestFilePreviewContent file={file} url={url} />
          ) : null}
        </div>
      </SheetContent>
    </Sheet>
  );
}

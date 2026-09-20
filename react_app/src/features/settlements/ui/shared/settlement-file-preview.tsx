"use client";

import {
  SettlementFilePreviewDialog,
  type SettlementPreviewFile,
} from "@/features/settlements/ui/shared/settlement-file-preview-dialog";
import { SettlementFilePreviewSheet } from "@/features/settlements/ui/mobile/settlement-file-preview-sheet";
import { useIsMobile } from "@/hooks/use-mobile";

type SettlementFilePreviewProps = {
  /** Файл для просмотра. `null` — окно закрыто. */
  file: SettlementPreviewFile | null;
  /** Скачивание файла на устройство. */
  onDownload: () => void;
  /** Закрытие окна. */
  onOpenChange: (open: boolean) => void;
};

/**
 * Просмотр документа: на телефоне — окно снизу во весь экран,
 * на компьютере — обычное окно.
 */
export function SettlementFilePreview({
  file,
  onDownload,
  onOpenChange,
}: SettlementFilePreviewProps) {
  const isMobile = useIsMobile();

  if (isMobile) {
    return (
      <SettlementFilePreviewSheet
        file={file}
        onDownload={onDownload}
        onOpenChange={onOpenChange}
      />
    );
  }

  return (
    <SettlementFilePreviewDialog
      file={file}
      onDownload={onDownload}
      onOpenChange={onOpenChange}
    />
  );
}

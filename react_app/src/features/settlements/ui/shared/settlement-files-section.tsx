"use client";

import { useRef, useState } from "react";
import { DownloadIcon, EyeIcon, PaperclipIcon, Trash2Icon } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import {
  downloadSettlementFileForUser,
  useDeleteSettlementFile,
  useSettlementFiles,
  useUploadSettlementFile,
} from "@/features/settlements/hooks/use-settlement-files";
import {
  downloadSettlementFile,
  SETTLEMENT_FILE_ACCEPT,
} from "@/features/settlements/api/settlement-files";
import type { SettlementFile } from "@/features/settlements/types/settlement.types";
import { SettlementDeleteDialog } from "@/features/settlements/ui/shared/settlement-delete-dialog";
import {
  type SettlementPreviewFile,
} from "@/features/settlements/ui/shared/settlement-file-preview-dialog";
import { SettlementFilePreview } from "@/features/settlements/ui/shared/settlement-file-preview";
import { SettlementFilesSkeleton } from "@/features/settlements/ui/shared/settlement-skeletons";
import { formatRuDate } from "@/features/settlements/utils/settlement.utils";

/** Размер файла по-русски: Б, КБ или МБ. */
function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} Б`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} КБ`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} МБ`;
}

/** PDF показывается встроенным просмотрщиком, остальное — картинкой. */
function isPdfFile(file: SettlementFile): boolean {
  return (
    file.type === "application/pdf" ||
    file.name.toLowerCase().endsWith(".pdf")
  );
}

type SettlementFilesSectionProps = {
  settlementOperationId: string;
  canUpdate: boolean;
};

/**
 * Документы счёта: список с открытием, скачиванием и удалением.
 *
 * Общий блок для компьютера и телефона; просмотр открывается окном,
 * подходящим для устройства.
 */
export function SettlementFilesSection({
  settlementOperationId,
  canUpdate,
}: SettlementFilesSectionProps) {
  const filesQuery = useSettlementFiles(settlementOperationId);
  const uploadFile = useUploadSettlementFile(settlementOperationId);
  const deleteFile = useDeleteSettlementFile(settlementOperationId);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [fileToDelete, setFileToDelete] = useState<SettlementFile | null>(null);
  const [downloadingId, setDownloadingId] = useState<string | null>(null);
  const [previewingId, setPreviewingId] = useState<string | null>(null);
  const [previewFile, setPreviewFile] = useState<SettlementFile | null>(null);
  const [preview, setPreview] = useState<SettlementPreviewFile | null>(null);

  const files = filesQuery.data ?? [];

  function closePreview() {
    if (preview) URL.revokeObjectURL(preview.url);
    setPreview(null);
    setPreviewFile(null);
  }

  async function handlePreview(file: SettlementFile) {
    setPreviewingId(file.id);
    try {
      const blob = await downloadSettlementFile(file.filePath);
      setPreviewFile(file);
      setPreview({
        title: file.name,
        url: URL.createObjectURL(blob),
        isPdf: isPdfFile(file),
      });
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось открыть файл"
      );
    } finally {
      setPreviewingId(null);
    }
  }

  function handlePick(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    uploadFile.mutate(
      { file, name: file.name, description: null },
      {
        onSuccess: () => toast.success("Файл прикреплён"),
        onError: (error) =>
          toast.error(
            error instanceof Error ? error.message : "Не удалось загрузить файл"
          ),
      }
    );
  }

  async function handleDownload(file: SettlementFile) {
    setDownloadingId(file.id);
    try {
      await downloadSettlementFileForUser(file);
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось скачать файл"
      );
    } finally {
      setDownloadingId(null);
    }
  }

  function handleDelete() {
    if (!fileToDelete) return;
    deleteFile.mutate(fileToDelete, {
      onSuccess: () => {
        setFileToDelete(null);
        toast.success("Файл удалён");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось удалить файл"
        ),
    });
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <p className="font-medium">Документы</p>
        {canUpdate ? (
          <>
            <input
              ref={inputRef}
              type="file"
              accept={SETTLEMENT_FILE_ACCEPT}
              className="hidden"
              onChange={handlePick}
            />
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={uploadFile.isPending}
              onClick={() => inputRef.current?.click()}
            >
              {uploadFile.isPending ? (
                <Spinner data-icon="inline-start" />
              ) : (
                <PaperclipIcon />
              )}
              Прикрепить
            </Button>
          </>
        ) : null}
      </div>

      {filesQuery.isLoading ? (
        <SettlementFilesSkeleton />
      ) : files.length === 0 ? (
        <p className="text-muted-foreground text-sm">
          К счёту пока ничего не прикреплено
        </p>
      ) : (
        <ul className="flex flex-col divide-y rounded-lg border">
          {files.map((file) => (
            <li
              key={file.id}
              className="flex items-center gap-2 px-3 py-2 text-sm"
            >
              <button
                type="button"
                className="min-w-0 flex-1 text-left"
                disabled={previewingId === file.id}
                onClick={() => handlePreview(file)}
                title="Открыть документ"
              >
                <p className="truncate font-medium hover:underline">
                  {file.name}
                </p>
                <p className="text-muted-foreground text-xs">
                  {formatFileSize(file.size)} · {formatRuDate(file.createdAt)}
                  {file.description ? ` · ${file.description}` : ""}
                </p>
              </button>
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                aria-label="Открыть"
                disabled={previewingId === file.id}
                onClick={() => handlePreview(file)}
              >
                {previewingId === file.id ? <Spinner /> : <EyeIcon />}
              </Button>
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                aria-label="Скачать"
                disabled={downloadingId === file.id}
                onClick={() => handleDownload(file)}
              >
                {downloadingId === file.id ? (
                  <Spinner />
                ) : (
                  <DownloadIcon />
                )}
              </Button>
              {canUpdate ? (
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  aria-label="Удалить"
                  onClick={() => setFileToDelete(file)}
                >
                  <Trash2Icon />
                </Button>
              ) : null}
            </li>
          ))}
        </ul>
      )}

      <SettlementFilePreview
        file={preview}
        onDownload={() => {
          if (previewFile) void handleDownload(previewFile);
        }}
        onOpenChange={(open) => {
          if (!open) closePreview();
        }}
      />

      <SettlementDeleteDialog
        open={Boolean(fileToDelete)}
        title="Удалить файл?"
        description={
          fileToDelete
            ? `Файл «${fileToDelete.name}» будет удалён без возможности восстановления.`
            : ""
        }
        isDeleting={deleteFile.isPending}
        onOpenChange={(open) => {
          if (!open) setFileToDelete(null);
        }}
        onConfirm={handleDelete}
      />
    </div>
  );
}

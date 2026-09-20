"use client";

import { DownloadIcon, Loader2Icon } from "lucide-react";

import { Button } from "@/components/ui/button";

type PayrollExportButtonProps = {
  canExport: boolean;
  isExporting: boolean;
  disabled?: boolean;
  onExport: () => void;
};

/** Выгрузка активной вкладки в Excel. Файл собирается в браузере. */
export function PayrollExportButton({
  canExport,
  isExporting,
  disabled = false,
  onExport,
}: PayrollExportButtonProps) {
  if (!canExport) {
    return null;
  }

  return (
    <Button
      type="button"
      size="sm"
      onClick={onExport}
      disabled={disabled || isExporting}
      title={isExporting ? "Формирование файла..." : "Выгрузить в Excel"}
      className="h-9 shrink-0 gap-1.5 rounded-lg border-emerald-600/30 bg-emerald-600 px-3 text-xs font-medium text-white hover:bg-emerald-700 active:bg-emerald-800 disabled:pointer-events-none disabled:opacity-50 dark:border-emerald-500/30 dark:bg-emerald-600 dark:hover:bg-emerald-500 sm:text-sm"
    >
      {isExporting ? (
        <Loader2Icon className="size-3.5 shrink-0 animate-spin" />
      ) : (
        <DownloadIcon className="size-3.5 shrink-0" />
      )}
      <span>{isExporting ? "Формирование..." : "Excel"}</span>
    </Button>
  );
}

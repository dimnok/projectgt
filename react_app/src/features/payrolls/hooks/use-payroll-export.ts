"use client";

import { useState } from "react";
import { toast } from "sonner";

type PayrollExportRequest = {
  /** Сколько строк выгружаем: пустой список не выгружаем. */
  rowsCount: number;
  /** Что показать при успехе. */
  successMessage: string;
  /** Сборка и скачивание файла. */
  run: () => Promise<void>;
};

/** Выгрузка вкладки в Excel: состояние кнопки, предупреждение и ошибки. */
export function usePayrollExport() {
  const [isExporting, setIsExporting] = useState(false);

  const exportToExcel = async ({
    rowsCount,
    successMessage,
    run,
  }: PayrollExportRequest) => {
    if (rowsCount === 0) {
      toast.warning("Нет строк для выгрузки");
      return;
    }

    try {
      setIsExporting(true);
      await run();
      toast.success(successMessage);
    } catch (error) {
      toast.error(
        error instanceof Error
          ? error.message
          : "Не удалось сформировать Excel"
      );
    } finally {
      setIsExporting(false);
    }
  };

  return { isExporting, exportToExcel };
}

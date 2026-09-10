"use client";

import { useRef, useState } from "react";
import { toast } from "sonner";
import {
  FileSpreadsheetIcon,
  UploadCloudIcon,
  DownloadIcon,
  CheckCircle2Icon,
  AlertCircleIcon,
  Loader2Icon,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Spinner } from "@/components/ui/spinner";
import {
  parseEstimateExcel,
  downloadEstimateTemplate,
  type ExcelEstimateValidationResult,
} from "@/features/estimates/utils/import-estimate-excel";
import { importEstimate } from "@/features/estimates/api/import-estimate";
import { formatCurrency, formatQuantity } from "@/features/estimates/utils/estimate.utils";

type ImportEstimateDialogProps = {
  open: boolean;
  contractId: string;
  contractNumber?: string;
  objectId?: string | null;
  existingTitles?: string[];
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
};

export function ImportEstimateDialog({
  open,
  contractId,
  contractNumber,
  objectId,
  existingTitles = [],
  onOpenChange,
  onSuccess,
}: ImportEstimateDialogProps) {
  const [file, setFile] = useState<File | null>(null);
  const [isParsing, setIsParsing] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [estimateTitle, setEstimateTitle] = useState("");
  const [validation, setValidation] = useState<ExcelEstimateValidationResult | null>(null);

  const fileInputRef = useRef<HTMLInputElement | null>(null);

  function resetState() {
    setFile(null);
    setIsParsing(false);
    setIsImporting(false);
    setEstimateTitle("");
    setValidation(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  }

  function handleDialogClose(nextOpen: boolean) {
    if (!nextOpen && !isImporting) {
      resetState();
    }
    onOpenChange(nextOpen);
  }

  async function handleFileSelect(selectedFile: File) {
    if (!selectedFile.name.endsWith(".xlsx")) {
      toast.error("Пожалуйста, выберите файл в формате .xlsx (Excel)");
      return;
    }

    setFile(selectedFile);
    setIsParsing(true);
    setValidation(null);

    // Автоподстановка названия сметы из имени файла, если поле пустое
    const defaultTitle = selectedFile.name.replace(/\.xlsx$/i, "").trim();
    if (!estimateTitle) {
      setEstimateTitle(defaultTitle);
    }

    try {
      const buffer = await selectedFile.arrayBuffer();
      const result = await parseEstimateExcel(buffer);
      setValidation(result);

      if (!result.isValid) {
        toast.error("Файл содержит ошибки структуры или пуст");
      }
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Не удалось прочитать Excel-файл"
      );
    } finally {
      setIsParsing(false);
    }
  }

  async function handleDownloadTemplate() {
    try {
      await downloadEstimateTemplate(contractNumber);
      toast.success("Шаблон сметы успешно скачан");
    } catch {
      toast.error("Не удалось скачать шаблон");
    }
  }

  async function handleImportSubmit() {
    if (!validation || !validation.isValid || validation.items.length === 0) {
      toast.error("Выберите корректный файл Excel с позициями");
      return;
    }

    const cleanTitle = estimateTitle.trim();
    if (!cleanTitle) {
      toast.error("Укажите название сметы");
      return;
    }

    try {
      setIsImporting(true);
      const res = await importEstimate({
        contractId,
        objectId: objectId ?? null,
        estimateTitle: cleanTitle,
        items: validation.items,
      });

      toast.success(`Смета «${cleanTitle}» успешно загружена (${res.count} поз.)`);
      handleDialogClose(false);
      onSuccess();
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : "Ошибка при сохранении сметы"
      );
    } finally {
      setIsImporting(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleDialogClose}>
      <DialogContent className="max-h-[min(90vh,52rem)] overflow-y-auto sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>Импорт сметы из Excel</DialogTitle>
          <DialogDescription>
            {contractNumber
              ? `Загрузка сметы в договор № ${contractNumber}`
              : "Загрузка сметы в договор"}
          </DialogDescription>
        </DialogHeader>

        <div className="flex flex-col gap-4 py-2">
          {/* Блок выбора файла и скачивания шаблона */}
          <div className="flex flex-col gap-2">
            <div className="flex items-center justify-between">
              <Label className="text-xs font-semibold">Файл сметы (.xlsx)</Label>
              <button
                type="button"
                onClick={handleDownloadTemplate}
                className="inline-flex items-center gap-1 text-xs text-primary hover:underline cursor-pointer"
              >
                <DownloadIcon className="size-3.5" />
                <span>Скачать шаблон</span>
              </button>
            </div>

            <div
              onClick={() => fileInputRef.current?.click()}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault();
                if (e.dataTransfer.files?.[0]) {
                  handleFileSelect(e.dataTransfer.files[0]);
                }
              }}
              className="flex flex-col items-center justify-center gap-2 rounded-xl border border-dashed border-border/80 bg-muted/20 p-6 text-center transition-colors hover:border-primary/60 hover:bg-muted/40 cursor-pointer"
            >
              <input
                ref={fileInputRef}
                type="file"
                accept=".xlsx"
                className="hidden"
                onChange={(e) => {
                  if (e.target.files?.[0]) {
                    handleFileSelect(e.target.files[0]);
                  }
                }}
              />
              <div className="rounded-full bg-muted p-2.5 text-muted-foreground">
                <UploadCloudIcon className="size-6" />
              </div>
              <div className="flex flex-col gap-0.5">
                <span className="text-xs font-medium text-foreground">
                  {file ? file.name : "Нажмите для выбора файла или перетащите его сюда"}
                </span>
                <span className="text-[11px] text-muted-foreground">
                  {file
                    ? `${(file.size / 1024).toFixed(1)} КБ`
                    : "Поддерживаются файлы Excel (.xlsx)"}
                </span>
              </div>
            </div>
          </div>

          {/* Парсинг и валидация */}
          {isParsing ? (
            <div className="flex items-center justify-center gap-2 rounded-lg border border-border/60 bg-muted/30 p-4 text-xs text-muted-foreground">
              <Loader2Icon className="size-4 animate-spin text-primary" />
              <span>Чтение и проверка структуры файла...</span>
            </div>
          ) : validation ? (
            <div className="flex flex-col gap-2">
              {validation.isValid ? (
                <div className="rounded-lg border border-emerald-500/30 bg-emerald-500/10 p-3 text-xs text-emerald-950 dark:text-emerald-200">
                  <div className="flex items-center gap-2 font-medium">
                    <CheckCircle2Icon className="size-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                    <span>Файл проверен: строк {formatQuantity(validation.totalRows)}, сумма {formatCurrency(validation.totalAmount)}</span>
                  </div>
                  {validation.systems.length > 0 ? (
                    <div className="mt-1.5 flex flex-wrap gap-1 text-[11px] text-muted-foreground">
                      <span className="font-medium">Системы:</span>
                      {validation.systems.map((s) => (
                        <span key={s} className="rounded bg-muted px-1.5 py-0.2 text-foreground">
                          {s}
                        </span>
                      ))}
                    </div>
                  ) : null}
                </div>
              ) : (
                <div className="rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-xs text-destructive">
                  <div className="flex items-center gap-2 font-medium">
                    <AlertCircleIcon className="size-4 shrink-0" />
                    <span>Ошибки в структуре файла</span>
                  </div>
                  <ul className="mt-1.5 list-disc pl-5 text-[11px]">
                    {validation.errors.slice(0, 5).map((err, i) => (
                      <li key={i}>{err}</li>
                    ))}
                    {validation.errors.length > 5 ? (
                      <li>...и еще {validation.errors.length - 5} ошибок</li>
                    ) : null}
                  </ul>
                </div>
              )}
            </div>
          ) : null}

          {/* Название сметы */}
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="estimate-title" className="text-xs font-semibold">
              Название сметы <span className="text-destructive">*</span>
            </Label>
            <Input
              id="estimate-title"
              value={estimateTitle}
              onChange={(e) => setEstimateTitle(e.target.value)}
              placeholder="Например: Смета на электромонтаж"
              disabled={isImporting}
              list="existing-titles"
            />
            {existingTitles.length > 0 ? (
              <datalist id="existing-titles">
                {existingTitles.map((t) => (
                  <option key={t} value={t} />
                ))}
              </datalist>
            ) : null}
            <span className="text-[11px] text-muted-foreground">
              Если указать название существующей сметы, строки добавятся в неё.
            </span>
          </div>
        </div>

        <DialogFooter className="sm:justify-between">
          <Button
            type="button"
            variant="outline"
            disabled={isImporting}
            onClick={() => handleDialogClose(false)}
          >
            Отмена
          </Button>
          <Button
            type="button"
            disabled={
              !validation ||
              !validation.isValid ||
              validation.items.length === 0 ||
              !estimateTitle.trim() ||
              isImporting ||
              isParsing
            }
            onClick={handleImportSubmit}
          >
            {isImporting ? <Spinner data-icon="inline-start" /> : <FileSpreadsheetIcon className="size-4 shrink-0" />}
            {isImporting ? "Импорт строк..." : "Загрузить смету"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

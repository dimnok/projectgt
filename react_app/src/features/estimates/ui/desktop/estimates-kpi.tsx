"use client";

import {
  ActivityIcon,
  CoinsIcon,
  ListOrderedIcon,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

import type {
  EstimateContractGroup,
  EstimateFile,
  EstimateObjectGroup,
} from "@/features/estimates/types/estimate.types";
import {
  formatCurrency,
  formatPlural,
  formatQuantity,
} from "@/features/estimates/utils/estimate.utils";
import { cn } from "@/lib/utils";

type EstimatesKpiProps = {
  file: EstimateFile | null;
  contractGroup: EstimateContractGroup | null;
  objectGroup: EstimateObjectGroup | null;
  allFiles: EstimateFile[];
};

export function EstimatesKpi({
  file,
  contractGroup,
  objectGroup,
  allFiles,
}: EstimatesKpiProps) {
  // Вариант 1: Выбрана конкретная смета
  if (file) {
    const percent = Math.min(100, Math.max(0, file.completionPercent));
    const isCompleted = percent >= 100;
    const isStarted = percent > 0;
    const contractFilesCount = contractGroup?.files.length ?? 1;

    const contractTotal = contractGroup?.total ?? file.total;
    const contractFiles = contractGroup?.files ?? [file];
    const contractCompletionPercent =
      contractTotal > 0
        ? contractFiles.reduce(
            (sum, f) => sum + f.total * (f.completionPercent || 0),
            0
          ) / contractTotal
        : contractFiles.length > 0
          ? contractFiles.reduce((sum, f) => sum + (f.completionPercent || 0), 0) /
            contractFiles.length
          : 0;

    return (
      <div className="grid grid-cols-2 divide-y divide-border/60 border-b border-border/80 bg-card sm:divide-y-0 sm:divide-x lg:grid-cols-4">
        <KpiCell
          label="Сумма сметы"
          value={formatCurrency(file.total)}
          subtext={
            objectGroup?.objectName
              ? `Объект: ${objectGroup.objectName}`
              : "По текущей смете"
          }
          icon={CoinsIcon}
        />
        <KpiCell
          label="Позиций в смете"
          value={`${formatQuantity(file.itemsCount)}`}
          subtext={formatPlural(file.itemsCount, "позиция", "позиции", "позиций")}
          icon={ListOrderedIcon}
        />
        <KpiCell
          label="Выполнение сметы"
          value={`${file.completionPercent.toFixed(1)}%`}
          icon={ActivityIcon}
          customContent={
            <div className="mt-0.5 flex flex-col gap-0.5">
              <div className="h-1 w-full overflow-hidden rounded-full bg-muted">
                <div
                  className={cn(
                    "h-full rounded-full transition-all duration-500",
                    isCompleted
                      ? "bg-success"
                      : isStarted
                        ? "bg-foreground"
                        : "bg-muted-foreground/40"
                  )}
                  style={{ width: `${percent}%` }}
                />
              </div>
              <span className="truncate text-[11px] text-muted-foreground leading-none">
                {isCompleted
                  ? "Полностью закрыта"
                  : isStarted
                    ? "В процессе выполнения"
                    : "Работы не начаты"}
              </span>
            </div>
          }
        />
        <KpiCell
          label="Итого по договору"
          value={formatCurrency(contractTotal)}
          subtext={`Договор № ${contractGroup?.contractNumber || "—"} (${formatPlural(contractFilesCount, "смета", "сметы", "смет")})`}
          customIcon={
            <CircularProgress
              percent={contractCompletionPercent}
              size={48}
              strokeWidth={3.5}
            />
          }
        />
      </div>
    );
  }

  // Вариант 2: Выбран договор (показываем сводку по всем сметам договора)
  if (contractGroup) {
    const contractFiles = contractGroup.files;
    const contractTotal = contractGroup.total;
    const contractItemsCount = contractFiles.reduce(
      (sum, f) => sum + f.itemsCount,
      0
    );
    const contractCompletionPercent =
      contractTotal > 0
        ? contractFiles.reduce(
            (sum, f) => sum + f.total * (f.completionPercent || 0),
            0
          ) / contractTotal
        : 0;

    return (
      <div className="grid grid-cols-2 divide-y divide-border/60 border-b border-border/80 bg-card sm:divide-y-0 sm:divide-x lg:grid-cols-4">
        <KpiCell
          label="Сумма по договору"
          value={formatCurrency(contractTotal)}
          subtext={
            objectGroup?.objectName
              ? `Объект: ${objectGroup.objectName}`
              : "По выбранному договору"
          }
          icon={CoinsIcon}
        />
        <KpiCell
          label="Всего смет в договоре"
          value={`${contractFiles.length}`}
          subtext={formatPlural(contractFiles.length, "смета", "сметы", "смет")}
          icon={ListOrderedIcon}
        />
        <KpiCell
          label="Всего позиций"
          value={formatQuantity(contractItemsCount)}
          subtext="Все строки смет договора"
          icon={ActivityIcon}
        />
        <KpiCell
          label="Выполнение по договору"
          value={`${contractCompletionPercent.toFixed(1)}%`}
          subtext={`Договор № ${contractGroup.contractNumber || "—"}`}
          customIcon={
            <CircularProgress
              percent={contractCompletionPercent}
              size={48}
              strokeWidth={3.5}
            />
          }
        />
      </div>
    );
  }

  // Вариант 3: Выбран только объект
  if (objectGroup) {
    const objectFiles = objectGroup.contracts.flatMap((c) => c.files);
    const objectTotal = objectGroup.total;
    const objectItemsCount = objectFiles.reduce(
      (sum, f) => sum + f.itemsCount,
      0
    );
    const objectCompletionPercent =
      objectTotal > 0
        ? objectFiles.reduce(
            (sum, f) => sum + f.total * (f.completionPercent || 0),
            0
          ) / objectTotal
        : 0;

    return (
      <div className="grid grid-cols-2 divide-y divide-border/60 border-b border-border/80 bg-card sm:divide-y-0 sm:divide-x lg:grid-cols-4">
        <KpiCell
          label="Сумма по объекту"
          value={formatCurrency(objectTotal)}
          subtext={`Объект: ${objectGroup.objectName}`}
          icon={CoinsIcon}
        />
        <KpiCell
          label="Смет на объекте"
          value={`${objectFiles.length}`}
          subtext={formatPlural(objectFiles.length, "смета", "сметы", "смет")}
          icon={ListOrderedIcon}
        />
        <KpiCell
          label="Позиций на объекте"
          value={formatQuantity(objectItemsCount)}
          subtext="Строки смет всех договоров"
          icon={ActivityIcon}
        />
        <KpiCell
          label="Договоры объекта"
          value={`${objectGroup.contracts.length}`}
          subtext={`${formatPlural(objectGroup.contracts.length, "договор", "договора", "договоров")}`}
          customIcon={
            <CircularProgress
              percent={objectCompletionPercent}
              size={48}
              strokeWidth={3.5}
            />
          }
        />
      </div>
    );
  }

  // Вариант 4: Ничего не выбрано (по умолчанию - сводка по компании)
  const totalAmount = allFiles.reduce((sum, item) => sum + item.total, 0);
  const totalItems = allFiles.reduce((sum, item) => sum + item.itemsCount, 0);
  const uniqueObjectsCount = new Set(
    allFiles.map((f) => f.objectId).filter(Boolean)
  ).size;
  const uniqueContractsCount = new Set(
    allFiles.map((f) => f.contractId || f.contractNumber).filter(Boolean)
  ).size;

  const totalOverallPercent =
    totalAmount > 0
      ? allFiles.reduce(
          (sum, f) => sum + f.total * (f.completionPercent || 0),
          0
        ) / totalAmount
      : 0;

  return (
    <div className="grid grid-cols-2 divide-y divide-border/60 border-b border-border/80 bg-card sm:divide-y-0 sm:divide-x lg:grid-cols-4">
      <KpiCell
        label="Общая сумма"
        value={formatCurrency(totalAmount)}
        subtext="Все сметы компании"
        icon={CoinsIcon}
      />
      <KpiCell
        label="Всего смет"
        value={`${allFiles.length}`}
        subtext={formatPlural(allFiles.length, "смета", "сметы", "смет")}
        icon={ListOrderedIcon}
      />
      <KpiCell
        label="Позиций в сметах"
        value={formatQuantity(totalItems)}
        subtext="Все строки спецификаций"
        icon={ActivityIcon}
      />
      <KpiCell
        label="Договоры и объекты"
        value={`${uniqueContractsCount} / ${uniqueObjectsCount}`}
        subtext={`${formatPlural(uniqueContractsCount, "договор", "договора", "договоров")}, ${formatPlural(uniqueObjectsCount, "объект", "объекта", "объектов")}`}
        customIcon={
          <CircularProgress
            percent={totalOverallPercent}
            size={48}
            strokeWidth={3.5}
          />
        }
      />
    </div>
  );
}

function CircularProgress({
  percent,
  size = 48,
  strokeWidth = 3.5,
}: {
  percent: number;
  size?: number;
  strokeWidth?: number;
}) {
  const clamped = Math.min(100, Math.max(0, percent));
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (clamped / 100) * circumference;
  const isCompleted = clamped >= 100;
  const isStarted = clamped > 0;

  return (
    <div
      className="relative flex shrink-0 items-center justify-center"
      style={{ width: size, height: size }}
      title={`Выполнение: ${clamped.toFixed(1)}%`}
    >
      <svg
        className="-rotate-90"
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
      >
        <circle
          className="text-muted-foreground/15"
          strokeWidth={strokeWidth}
          stroke="currentColor"
          fill="transparent"
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
        <circle
          className={cn(
            "transition-all duration-500",
            isCompleted
              ? "text-success"
              : isStarted
                ? "text-foreground"
                : "text-transparent"
          )}
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
          stroke="currentColor"
          fill="transparent"
          r={radius}
          cx={size / 2}
          cy={size / 2}
        />
      </svg>
      <span className="absolute font-heading text-xs font-semibold tracking-tight tabular-nums leading-none text-foreground">
        {clamped >= 100 ? "100" : clamped.toFixed(0)}%
      </span>
    </div>
  );
}

function KpiCell({
  label,
  value,
  subtext,
  icon: Icon,
  customIcon,
  customContent,
}: {
  label: string;
  value: string;
  subtext?: string;
  icon?: LucideIcon;
  customIcon?: React.ReactNode;
  customContent?: React.ReactNode;
}) {
  return (
    <div className="flex items-center justify-between gap-3 px-3.5 py-2 transition-colors hover:bg-muted/15 sm:px-5 sm:py-2.5">
      <div className="flex min-w-0 flex-1 flex-col justify-between">
        <span className="text-xs font-medium text-muted-foreground">
          {label}
        </span>
        <div className="mt-0.5 font-heading text-base font-semibold tracking-tight tabular-nums text-foreground lg:text-lg xl:text-xl">
          {value}
        </div>
        {customContent ? (
          customContent
        ) : subtext ? (
          <p className="truncate text-[11px] text-muted-foreground leading-tight">
            {subtext}
          </p>
        ) : null}
      </div>
      {customIcon ? (
        <div className="shrink-0">{customIcon}</div>
      ) : Icon ? (
        <div className="flex size-6 shrink-0 self-start items-center justify-center rounded-md bg-muted text-foreground/70 [&_svg]:size-3.5">
          <Icon />
        </div>
      ) : null}
    </div>
  );
}

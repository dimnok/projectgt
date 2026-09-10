"use client";

import type { ReactNode } from "react";
import { Button } from "@/components/ui/button";

import type { Contract } from "@/features/contracts/types/contract.types";
import {
  daysUntilEnd,
  formatCurrency,
  formatRuDate,
} from "@/features/contracts/utils/contract.utils";
import { cn } from "@/lib/utils";

type ContractDetailsProps = {
  contract: Contract;
  canUpdate?: boolean;
  canDelete?: boolean;
  onEdit?: () => void;
  onDelete?: () => void;
};

function filled(value: string | null | undefined): string | null {
  const text = value?.trim() ?? "";
  return text ? text : null;
}

function Detail({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <div className="flex min-w-0 flex-col gap-1">
      <p className="text-xs text-muted-foreground">{label}</p>
      <div className="text-sm">{children}</div>
    </div>
  );
}

function endDateLabel(contract: Contract) {
  if (!contract.endDate) {
    return "Не указана";
  }
  const days = daysUntilEnd(contract.endDate);
  const date = formatRuDate(contract.endDate);
  if (days === null) {
    return date;
  }
  if (days < 0) {
    return `${date} · срок истёк`;
  }
  if (days <= 30) {
    return `${date} · осталось ${days} дн.`;
  }
  return date;
}

function endDateClass(contract: Contract) {
  const days = daysUntilEnd(contract.endDate);
  if (days === null) {
    return undefined;
  }
  if (days < 0) {
    return "text-destructive";
  }
  if (days <= 30) {
    return "text-warning";
  }
  return undefined;
}

export function ContractDetails({
  contract,
  canUpdate = false,
  canDelete = false,
  onEdit,
  onDelete,
}: ContractDetailsProps) {
  const contractorOrg = filled(contract.contractorLegalName);
  const contractorPosition = filled(contract.contractorPosition);
  const contractorSigner = filled(contract.contractorSigner);
  const customerOrg = filled(contract.customerLegalName);
  const customerPosition = filled(contract.customerPosition);
  const customerSigner = filled(contract.customerSigner);
  const hasContractorSigners =
    contractorOrg || contractorPosition || contractorSigner;
  const hasCustomerSigners = customerOrg || customerPosition || customerSigner;

  return (
    <div className="flex flex-col gap-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Detail label="Контрагент">
          {contract.contractorName || "Не указан"}
        </Detail>
        <Detail label="Объект">{contract.objectName || "Не указан"}</Detail>
        <Detail label="Дата заключения">{formatRuDate(contract.date)}</Detail>
        <Detail label="Дата окончания">
          <span className={cn(endDateClass(contract))}>
            {endDateLabel(contract)}
          </span>
        </Detail>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <Detail label="Сумма">{formatCurrency(contract.amount)}</Detail>
        <Detail label="НДС">
          {formatCurrency(contract.vatAmount)}
          {contract.vatRate > 0
            ? ` · ${contract.vatRate}%${contract.isVatIncluded ? ", в том числе" : ", сверху"}`
            : ""}
        </Detail>
        {contract.advanceAmount > 0 ? (
          <Detail label="Аванс">{formatCurrency(contract.advanceAmount)}</Detail>
        ) : null}
        {contract.warrantyRetentionRate > 0 ||
        contract.warrantyRetentionAmount > 0 ? (
          <Detail label="Гарантийные удержания">
            {formatCurrency(contract.warrantyRetentionAmount)}
            {contract.warrantyRetentionRate > 0
              ? ` · ${contract.warrantyRetentionRate}%`
              : ""}
            {contract.warrantyPeriodMonths > 0
              ? ` · ${contract.warrantyPeriodMonths} мес.`
              : ""}
          </Detail>
        ) : null}
        {contract.generalContractorFeeRate > 0 ||
        contract.generalContractorFeeAmount > 0 ? (
          <Detail label="Генподрядные">
            {formatCurrency(contract.generalContractorFeeAmount)}
            {contract.generalContractorFeeRate > 0
              ? ` · ${contract.generalContractorFeeRate}%`
              : ""}
          </Detail>
        ) : null}
      </div>
      {hasContractorSigners || hasCustomerSigners ? (
        <div className="grid gap-4 sm:grid-cols-2">
          {hasContractorSigners ? (
            <Detail label="Подрядчик (исполнитель)">
              {[contractorOrg, contractorPosition, contractorSigner]
                .filter(Boolean)
                .join(" · ")}
            </Detail>
          ) : null}
          {hasCustomerSigners ? (
            <Detail label="Заказчик">
              {[customerOrg, customerPosition, customerSigner]
                .filter(Boolean)
                .join(" · ")}
            </Detail>
          ) : null}
        </div>
      ) : null}

      {/* Кнопки управления договором: Изменить / Удалить */}
      {canUpdate || canDelete ? (
        <div className="mt-4 flex flex-wrap items-center justify-end gap-2 border-t border-border/60 pt-4">
          {canUpdate && onEdit ? (
            <Button type="button" variant="outline" onClick={onEdit}>
              Изменить
            </Button>
          ) : null}
          {canDelete && onDelete ? (
            <Button type="button" variant="destructive" onClick={onDelete}>
              Удалить
            </Button>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

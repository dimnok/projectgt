"use client";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { PurchaseRequestStatusBadge } from "@/features/purchase-requests/ui/shared/purchase-request-status-badge";
import type { PurchaseRequestListItem } from "@/features/purchase-requests/types/purchase-request.types";
import {
  formatPurchaseRequestAmount,
  formatRuDate,
} from "@/features/purchase-requests/utils/format";
import { formatUserDisplayLabel } from "@/features/purchase-requests/utils/names";

type PurchaseRequestsListProps = {
  /** Строки реестра заявок: уже отфильтрованные и найденные поиском. */
  requests: PurchaseRequestListItem[];
  /** Идентификатор открытой заявки — её строка подсвечивается. */
  selectedId: string | null;
  /** Выбор заявки: открывает окно с подробностями. */
  onSelect: (request: PurchaseRequestListItem) => void;
};

/**
 * Реестр заявок в виде таблицы.
 *
 * Подробности заявки (позиции, счета, история, кнопки этапов) в строку не
 * помещаются — они открываются в отдельном окне `PurchaseRequestDetailsDialog`.
 */
export function PurchaseRequestsList({
  requests,
  selectedId,
  onSelect,
}: PurchaseRequestsListProps) {
  return (
    <div className="overflow-hidden rounded-xl bg-card ring-1 ring-foreground/10">
      <Table>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead>Номер</TableHead>
            <TableHead>Объект</TableHead>
            <TableHead>Инициатор</TableHead>
            <TableHead>Дата</TableHead>
            <TableHead className="text-right">Сумма</TableHead>
            <TableHead>Статус</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {requests.map((request) => {
            const isSelected = selectedId === request.id;

            return (
              <TableRow
                key={request.id}
                data-state={isSelected ? "selected" : undefined}
                className="cursor-pointer focus-visible:bg-muted/50 focus-visible:outline-none"
                tabIndex={0}
                onClick={() => onSelect(request)}
                onKeyDown={(event) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault();
                    onSelect(request);
                  }
                }}
              >
                <TableCell className="max-w-40 font-medium">
                  <span className="block truncate">№ {request.number}</span>
                </TableCell>
                <TableCell className="max-w-64">
                  <span className="block truncate">
                    {request.objectName || "—"}
                  </span>
                </TableCell>
                <TableCell className="max-w-48">
                  <span className="block truncate">
                    {formatUserDisplayLabel(request.createdByName)}
                  </span>
                </TableCell>
                <TableCell className="whitespace-nowrap">
                  {formatRuDate(request.createdAt)}
                </TableCell>
                <TableCell className="text-right font-medium tabular-nums">
                  {formatPurchaseRequestAmount(request.totalAmount)}
                </TableCell>
                <TableCell>
                  <PurchaseRequestStatusBadge status={request.status} />
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </div>
  );
}

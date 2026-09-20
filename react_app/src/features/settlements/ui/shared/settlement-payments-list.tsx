"use client";

import { PencilIcon, Trash2Icon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { SettlementPayment } from "@/features/settlements/types/settlement.types";
import { formatCurrency, formatRuDate } from "@/features/settlements/utils/settlement.utils";
import { cn } from "@/lib/utils";

type SettlementPaymentsListProps = {
  payments: SettlementPayment[];
  canUpdate: boolean;
  onEdit: (payment: SettlementPayment) => void;
  onDelete: (payment: SettlementPayment) => void;
};

/**
 * Таблица оплат по счёту.
 *
 * Оплаты из банковской выписки (модуль ДДС) показываются, но без кнопок
 * правки и удаления — они меняются только транзакцией в ДДС.
 */
export function SettlementPaymentsList({
  payments,
  canUpdate,
  onEdit,
  onDelete,
}: SettlementPaymentsListProps) {
  if (payments.length === 0) {
    return (
      <p className="text-muted-foreground text-sm">
        Оплат по этому счёту пока нет
      </p>
    );
  }

  return (
    <div className="overflow-hidden rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow className="hover:bg-transparent">
            <TableHead className="w-28">Дата</TableHead>
            <TableHead className="w-28 text-right">Сумма</TableHead>
            <TableHead className="w-full">Примечание</TableHead>
            {canUpdate ? <TableHead className="w-16" /> : null}
          </TableRow>
        </TableHeader>
        <TableBody>
          {payments.map((payment) => {
            const isFromBank = Boolean(payment.cashFlowTransactionId);
            return (
              <TableRow key={payment.id}>
                <TableCell>{formatRuDate(payment.paymentDate)}</TableCell>
                <TableCell className="w-28 text-right font-medium tabular-nums">
                  {formatCurrency(payment.amount)}
                </TableCell>
                <TableCell className="w-full whitespace-normal">
                  <span
                    className={cn(
                      "text-xs",
                      isFromBank ? "text-primary" : "text-muted-foreground"
                    )}
                  >
                    {isFromBank
                      ? `Из выписки${payment.note ? `: ${payment.note}` : ""}`
                      : payment.note || "—"}
                  </span>
                </TableCell>
                {canUpdate ? (
                  <TableCell className="w-16">
                    {isFromBank ? null : (
                      <div className="flex justify-end gap-1">
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-sm"
                          aria-label="Редактировать"
                          onClick={() => onEdit(payment)}
                        >
                          <PencilIcon />
                        </Button>
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-sm"
                          aria-label="Удалить"
                          onClick={() => onDelete(payment)}
                        >
                          <Trash2Icon />
                        </Button>
                      </div>
                    )}
                  </TableCell>
                ) : null}
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
    </div>
  );
}

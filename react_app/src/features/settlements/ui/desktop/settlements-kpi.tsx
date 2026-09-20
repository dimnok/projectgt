"use client";

import { AlertCircleIcon, CoinsIcon, ListOrderedIcon, WalletIcon } from "lucide-react";

import { KpiCell, KpiStrip } from "@/components/shared/kpi-cell";
import type { SettlementSummary } from "@/features/settlements/api/settlement-list";
import {
  SETTLEMENT_PAYMENT_STATUSES,
  settlementPaymentStatusLabel,
} from "@/features/settlements/utils/payment-status";
import { formatCurrency } from "@/features/settlements/utils/settlement.utils";

/** Полоса показателей реестра: к оплате, оплачено, остаток, всего счетов. */
export function SettlementsKpi({ summary }: { summary: SettlementSummary }) {
  const byStatus = SETTLEMENT_PAYMENT_STATUSES.map((status) => ({
    status,
    count: summary.byStatus[status] ?? 0,
  })).filter((item) => item.count > 0);

  const statusSubtext =
    byStatus.length > 0
      ? byStatus
          .map(
            (item) =>
              `${settlementPaymentStatusLabel(item.status).toLowerCase()} ${item.count}`
          )
          .join(" · ")
      : "Счетов пока нет";

  return (
    <KpiStrip>
      <KpiCell
        label="К оплате"
        value={formatCurrency(summary.totalAmount)}
        subtext="Сумма всех счетов"
        icon={CoinsIcon}
      />
      <KpiCell
        label="Оплачено"
        value={formatCurrency(summary.totalPaid)}
        subtext="Поступившие оплаты"
        icon={WalletIcon}
      />
      <KpiCell
        label="Остаток"
        value={formatCurrency(summary.totalDebt)}
        subtext="Долг по счетам"
        icon={AlertCircleIcon}
      />
      <KpiCell
        label="Всего счетов"
        value={`${summary.count}`}
        subtext={statusSubtext}
        icon={ListOrderedIcon}
      />
    </KpiStrip>
  );
}

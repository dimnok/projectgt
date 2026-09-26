"use client";

import {
  ListOrderedIcon,
  ScaleIcon,
  TrendingDownIcon,
  TrendingUpIcon,
} from "lucide-react";

import { KpiCell, KpiStrip } from "@/components/shared/kpi-cell";
import type { CashFlowSummary } from "@/features/cash-flow/types/cash-flow.types";
import { formatCurrency } from "@/features/cash-flow/utils/cash-flow.utils";

/** Полоса показателей реестра: приход, расход, сальдо, число операций. */
export function CashFlowKpi({ summary }: { summary: CashFlowSummary }) {
  return (
    <KpiStrip>
      <KpiCell
        label="Приход"
        value={formatCurrency(summary.income)}
        subtext="Поступления за период"
        icon={TrendingUpIcon}
      />
      <KpiCell
        label="Расход"
        value={formatCurrency(summary.expense)}
        subtext="Списания за период"
        icon={TrendingDownIcon}
      />
      <KpiCell
        label="Сальдо"
        value={formatCurrency(summary.balance)}
        subtext="Приход минус расход"
        icon={ScaleIcon}
      />
      <KpiCell
        label="Операций"
        value={`${summary.count}`}
        subtext="В реестре за период"
        icon={ListOrderedIcon}
      />
    </KpiStrip>
  );
}

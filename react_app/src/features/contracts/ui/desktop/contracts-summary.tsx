"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { ContractStatusBadge } from "@/features/contracts/ui/shared/contract-status-badge";
import type { Contract } from "@/features/contracts/types/contract.types";
import { CONTRACT_STATUSES } from "@/features/contracts/utils/contract-status";
import {
  countContractsByStatus,
  formatContractCount,
  formatCurrency,
} from "@/features/contracts/utils/contract.utils";

type ContractsSummaryProps = {
  contracts: Contract[];
};

export function ContractsSummary({ contracts }: ContractsSummaryProps) {
  const { total, totalAmount, byStatus } = countContractsByStatus(contracts);

  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Сводка</CardTitle>
        <CardDescription>Все договоры компании</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col gap-6 max-lg:flex-row max-lg:flex-wrap max-lg:items-center max-lg:justify-between max-lg:gap-x-4 max-lg:gap-y-2">
        <div className="flex flex-col gap-1 max-lg:flex-row max-lg:items-baseline max-lg:gap-2">
          <p className="text-sm text-muted-foreground">Всего</p>
          <p className="font-heading text-2xl font-medium tabular-nums max-lg:text-base">
            {formatContractCount(total)}
          </p>
        </div>
        <div className="flex flex-col gap-1 max-lg:flex-row max-lg:items-baseline max-lg:gap-2">
          <p className="text-sm text-muted-foreground">Сумма</p>
          <p className="font-heading text-lg font-medium tabular-nums max-lg:text-base">
            {formatCurrency(totalAmount)}
          </p>
        </div>
        <ul className="flex flex-col max-lg:flex-row max-lg:flex-wrap max-lg:items-center max-lg:gap-x-4 max-lg:gap-y-1">
          {CONTRACT_STATUSES.map((item) => (
            <li
              key={item}
              className="flex items-center gap-2 border-b py-3 last:border-b-0 max-lg:border-0 max-lg:py-0 lg:justify-between lg:gap-3"
            >
              <ContractStatusBadge status={item} />
              <span className="tabular-nums text-sm font-medium">
                {byStatus[item]}
              </span>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}

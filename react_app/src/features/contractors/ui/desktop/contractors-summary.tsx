"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { ContractorTypeBadge } from "@/features/contractors/ui/shared/contractor-type-badge";
import type { Contractor } from "@/features/contractors/types/contractor.types";
import { CONTRACTOR_TYPES } from "@/features/contractors/utils/contractor-type";
import {
  countContractorsByType,
  formatContractorCount,
} from "@/features/contractors/utils/contractor.utils";

type ContractorsSummaryProps = {
  contractors: Contractor[];
};

export function ContractorsSummary({ contractors }: ContractorsSummaryProps) {
  const { total, byType } = countContractorsByType(contractors);

  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Сводка</CardTitle>
        <CardDescription>Все контрагенты компании</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col gap-6 max-lg:flex-row max-lg:flex-wrap max-lg:items-center max-lg:justify-between max-lg:gap-x-4 max-lg:gap-y-2">
        <div className="flex flex-col gap-1 max-lg:flex-row max-lg:items-baseline max-lg:gap-2">
          <p className="text-sm text-muted-foreground">Всего</p>
          <p className="font-heading text-2xl font-medium tabular-nums max-lg:text-base">
            {formatContractorCount(total)}
          </p>
        </div>
        <ul className="flex flex-col max-lg:flex-row max-lg:flex-wrap max-lg:items-center max-lg:gap-x-4 max-lg:gap-y-1">
          {CONTRACTOR_TYPES.map((item) => (
            <li
              key={item}
              className="flex items-center gap-2 border-b py-3 last:border-b-0 max-lg:border-0 max-lg:py-0 lg:justify-between lg:gap-3"
            >
              <ContractorTypeBadge type={item} />
              <span className="tabular-nums text-sm font-medium">
                {byType[item]}
              </span>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}

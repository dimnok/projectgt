"use client";

import { Badge } from "@/components/ui/badge";
import {
  contractKindLabel,
  type ContractKind,
} from "@/features/contracts/utils/contract-kind";

const kindVariant: Record<ContractKind, "default" | "success" | "warning"> = {
  customer: "default",
  subcontract: "success",
  supply: "warning",
};

type ContractKindBadgeProps = {
  kind: ContractKind;
  compact?: boolean;
};

export function ContractKindBadge({ kind, compact }: ContractKindBadgeProps) {
  return (
    <Badge
      variant={kindVariant[kind]}
      className={compact ? "h-3.5 px-1 text-[10px]" : undefined}
    >
      {contractKindLabel(kind)}
    </Badge>
  );
}

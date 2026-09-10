"use client";

import { Badge } from "@/components/ui/badge";
import {
  contractStatusLabel,
  type ContractStatus,
} from "@/features/contracts/utils/contract-status";

const statusVariant: Record<
  ContractStatus,
  "success" | "warning" | "secondary"
> = {
  active: "success",
  suspended: "warning",
  completed: "secondary",
};

type ContractStatusBadgeProps = {
  status: ContractStatus;
};

export function ContractStatusBadge({ status }: ContractStatusBadgeProps) {
  return (
    <Badge variant={statusVariant[status]}>{contractStatusLabel(status)}</Badge>
  );
}

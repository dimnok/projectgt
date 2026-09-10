"use client";

import { Badge } from "@/components/ui/badge";
import {
  contractorTypeLabel,
  type ContractorType,
} from "@/features/contractors/utils/contractor-type";

const typeVariant: Record<
  ContractorType,
  "default" | "success" | "warning"
> = {
  customer: "default",
  contractor: "success",
  supplier: "warning",
};

type ContractorTypeBadgeProps = {
  type: ContractorType;
};

export function ContractorTypeBadge({ type }: ContractorTypeBadgeProps) {
  return (
    <Badge variant={typeVariant[type]}>{contractorTypeLabel(type)}</Badge>
  );
}

import { Badge } from "@/components/ui/badge";
import type { SettlementOperationType } from "@/features/settlements/types/settlement.types";
import {
  settlementOperationTypeLabel,
  settlementOperationTypeVariant,
} from "@/features/settlements/utils/operation-type";

/** Бейдж типа операции: акт, аванс или прочее. */
export function SettlementTypeBadge({
  type,
}: {
  type: SettlementOperationType;
}) {
  return (
    <Badge variant={settlementOperationTypeVariant(type)}>
      {settlementOperationTypeLabel(type)}
    </Badge>
  );
}

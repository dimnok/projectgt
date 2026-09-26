import { Badge } from "@/components/ui/badge";
import type { CashFlowType } from "@/features/cash-flow/types/cash-flow.types";
import { cashFlowTypeLabel } from "@/features/cash-flow/utils/operation-type";

/** Бейдж типа операции: приход — зелёный, расход — красный. */
export function CashFlowTypeBadge({ type }: { type: CashFlowType }) {
  return (
    <Badge variant={type === "income" ? "success" : "destructive"}>
      {cashFlowTypeLabel(type)}
    </Badge>
  );
}

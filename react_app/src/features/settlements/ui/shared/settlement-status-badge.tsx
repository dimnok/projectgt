import { Badge } from "@/components/ui/badge";
import type { SettlementPaymentStatus } from "@/features/settlements/types/settlement.types";
import {
  settlementPaymentStatusLabel,
  settlementPaymentStatusVariant,
} from "@/features/settlements/utils/payment-status";

/** Бейдж статуса оплаты счёта: подпись и цвет берутся из справочника статусов. */
export function SettlementStatusBadge({
  status,
}: {
  status: SettlementPaymentStatus;
}) {
  return (
    <Badge variant={settlementPaymentStatusVariant(status)}>
      {settlementPaymentStatusLabel(status)}
    </Badge>
  );
}

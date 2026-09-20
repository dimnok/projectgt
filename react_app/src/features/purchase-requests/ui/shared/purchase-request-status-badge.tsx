"use client";

import { Badge } from "@/components/ui/badge";
import type { PurchaseRequestStatus } from "@/features/purchase-requests/types/purchase-request.types";
import { STATUS_BADGE_CLASS } from "@/features/purchase-requests/utils/labels";
import { purchaseRequestStatusLabel } from "@/features/purchase-requests/utils/status";
import { cn } from "@/lib/utils";

type PurchaseRequestStatusBadgeProps = {
  status: PurchaseRequestStatus;
  className?: string;
};

export function PurchaseRequestStatusBadge({
  status,
  className,
}: PurchaseRequestStatusBadgeProps) {
  return (
    <Badge
      variant="secondary"
      className={cn("border-0", STATUS_BADGE_CLASS[status], className)}
    >
      {purchaseRequestStatusLabel(status)}
    </Badge>
  );
}

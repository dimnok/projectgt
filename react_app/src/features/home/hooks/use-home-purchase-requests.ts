"use client";

import { usePurchaseRequestCounts } from "@/features/purchase-requests/hooks/use-purchase-requests";
import {
  PURCHASE_REQUEST_APPROVAL_STAGES,
  PURCHASE_REQUEST_PAYMENT_STAGES,
  purchaseRequestStageCount,
} from "@/features/purchase-requests/utils/status";
import { usePermissions } from "@/hooks/use-permissions";

/**
 * Компактные счётчики заявок, требующих действия, для Главной.
 *
 * Согласование — этапы «На согласовании» и «Согласование счета», оплата —
 * «Передано бухгалтеру» и «Заведено на оплату». Сервер отдаёт только доступные
 * пользователю заявки: у руководителя это вся компания, у остальных — свои
 * и назначенные на них.
 */
export function useHomePurchaseRequestCounts() {
  const { can, isOwner } = usePermissions();
  const canRead = isOwner || can("purchase_requests", "read");
  const countsQuery = usePurchaseRequestCounts("", canRead);
  const counts = countsQuery.data;

  return {
    canRead,
    approvalCount: purchaseRequestStageCount(
      counts,
      PURCHASE_REQUEST_APPROVAL_STAGES
    ),
    paymentCount: purchaseRequestStageCount(
      counts,
      PURCHASE_REQUEST_PAYMENT_STAGES
    ),
    isLoading: canRead && countsQuery.isLoading,
  };
}

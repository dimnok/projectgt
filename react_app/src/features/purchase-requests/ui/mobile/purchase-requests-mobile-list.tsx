"use client";

import { ShoppingCartIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { PurchaseRequestStatusBadge } from "@/features/purchase-requests/ui/shared/purchase-request-status-badge";
import type { PurchaseRequestListItem } from "@/features/purchase-requests/types/purchase-request.types";
import {
  formatPurchaseRequestAmount,
  formatRuDate,
} from "@/features/purchase-requests/utils/format";
import { formatUserDisplayLabel } from "@/features/purchase-requests/utils/names";

type PurchaseRequestsMobileListProps = {
  requests: PurchaseRequestListItem[];
  isLoading: boolean;
  errorMessage?: string;
  emptyDescription: string;
  onSelectRequest: (request: PurchaseRequestListItem) => void;
};

/** Список заявок карточками: статус, объект, инициатор, дата и сумма. */
export function PurchaseRequestsMobileList({
  requests,
  isLoading,
  errorMessage,
  emptyDescription,
  onSelectRequest,
}: PurchaseRequestsMobileListProps) {
  if (isLoading) {
    return (
      <div className="flex flex-col gap-2">
        <Skeleton className="h-24 w-full rounded-xl" />
        <Skeleton className="h-24 w-full rounded-xl" />
        <Skeleton className="h-24 w-full rounded-xl" />
      </div>
    );
  }

  if (errorMessage) {
    return <ErrorState message={errorMessage} />;
  }

  if (requests.length === 0) {
    return (
      <EmptyState
        title="Заявок нет"
        description={emptyDescription}
        icon={ShoppingCartIcon}
      />
    );
  }

  return (
    <div className="flex flex-col gap-2">
      {requests.map((request) => (
        <RequestMobileCard
          key={request.id}
          request={request}
          onSelect={() => onSelectRequest(request)}
        />
      ))}
    </div>
  );
}

function RequestMobileCard({
  request,
  onSelect,
}: {
  request: PurchaseRequestListItem;
  onSelect: () => void;
}) {
  return (
    <button type="button" className="w-full text-left" onClick={onSelect}>
      <Card size="sm" className="shadow-float">
        <CardContent className="flex flex-col gap-1.5">
          <div className="flex items-center justify-between gap-2">
            <p className="min-w-0 truncate font-heading text-sm font-medium">
              № {request.number}
            </p>
            <PurchaseRequestStatusBadge status={request.status} />
          </div>

          <p className="truncate text-sm text-foreground">
            {request.objectName || "—"}
          </p>

          <div className="flex items-end justify-between gap-2">
            <p className="min-w-0 truncate text-xs text-muted-foreground">
              {formatUserDisplayLabel(request.createdByName)} ·{" "}
              {formatRuDate(request.createdAt)}
            </p>
            <p className="shrink-0 text-sm font-semibold tabular-nums">
              {formatPurchaseRequestAmount(request.totalAmount)}
            </p>
          </div>
        </CardContent>
      </Card>
    </button>
  );
}

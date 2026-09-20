"use client";

import { Maximize2Icon, Minimize2Icon, XIcon } from "lucide-react";
import { useState } from "react";

import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { usePurchaseRequestDetails } from "@/features/purchase-requests/hooks/use-purchase-requests";
import type {
  PurchaseRequest,
  PurchaseRequestItem,
  PurchaseRequestSettings,
} from "@/features/purchase-requests/types/purchase-request.types";
import { PurchaseRequestDetailsCard } from "@/features/purchase-requests/ui/shared/purchase-request-details";
import { PurchaseRequestStatusBadge } from "@/features/purchase-requests/ui/shared/purchase-request-status-badge";
import { resolvePurchaseRequestActions } from "@/features/purchase-requests/utils/actions";
import {
  formatPurchaseRequestAmount,
  formatRuDate,
} from "@/features/purchase-requests/utils/format";
import { formatUserDisplayLabel } from "@/features/purchase-requests/utils/names";
import { cn } from "@/lib/utils";

type PurchaseRequestDetailsDialogProps = {
  /** Идентификатор заявки. `null` — окно закрыто. */
  requestId: string | null;
  /** Текущий пользователь: от него зависят доступные кнопки этапов. */
  currentUserId: string | null;
  /** Проверка прав по модулю заявок. */
  can: (module: string, action: string) => boolean;
  /** Настроенный маршрут: участники каждого этапа. */
  settings: PurchaseRequestSettings | null | undefined;
  /** Закрытие окна. */
  onOpenChange: (open: boolean) => void;
  /** Переход к редактированию черновика. */
  onEditDraft: (request: PurchaseRequest, items: PurchaseRequestItem[]) => void;
  /** Запрос удаления черновика. */
  onDeleteDraft: (request: PurchaseRequest) => void;
};

/**
 * Окно с подробностями заявки.
 *
 * Заменяет раскрывающуюся карточку: показывает статус, сумму, позиции, счета,
 * историю и кнопки этапов. Данные подгружаются по идентификатору заявки, поэтому
 * окно остаётся рабочим, даже если заявка не попала в текущий фильтр списка.
 */
export function PurchaseRequestDetailsDialog({
  requestId,
  currentUserId,
  can,
  settings,
  onOpenChange,
  onEditDraft,
  onDeleteDraft,
}: PurchaseRequestDetailsDialogProps) {
  const [isMaximized, setIsMaximized] = useState(false);
  const detailsQuery = usePurchaseRequestDetails(requestId);
  const details = detailsQuery.data ?? null;
  const request = details?.request ?? null;

  // При переходе к другой заявке окно возвращается к обычному размеру.
  const [lastRequestId, setLastRequestId] = useState(requestId);
  if (requestId !== lastRequestId) {
    setLastRequestId(requestId);
    setIsMaximized(false);
  }

  /** Сброс разворота окна при закрытии. */
  function handleOpenChange(open: boolean) {
    if (!open) {
      setIsMaximized(false);
    }
    onOpenChange(open);
  }

  const subtitle = request
    ? [
        request.objectName,
        formatUserDisplayLabel(request.createdByName),
        formatRuDate(request.createdAt),
      ]
        .filter(Boolean)
        .join(" · ")
    : "";

  return (
    <Dialog
      open={Boolean(requestId)}
      onOpenChange={handleOpenChange}
      disablePointerDismissal
    >
      <DialogContent
        showCloseButton={false}
        className={cn(
          "flex flex-col overflow-hidden",
          isMaximized
            ? "!h-[97vh] !max-h-[97vh] !w-[98vw] !max-w-[98vw] sm:!max-w-[98vw]"
            : "h-[min(82vh,54rem)] w-[min(90vw,85rem)] sm:max-w-[min(90vw,85rem)]"
        )}
      >
        {/* Кнопки управления окном: Развернуть / Восстановить + Закрыть */}
        <div className="absolute top-2.5 right-2.5 z-20 flex items-center gap-1">
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            onClick={() => setIsMaximized((previous) => !previous)}
            className="text-muted-foreground hover:text-foreground cursor-pointer"
            title={isMaximized ? "Восстановить размер" : "Развернуть на весь экран"}
            aria-label={isMaximized ? "Восстановить размер" : "Развернуть на весь экран"}
          >
            {isMaximized ? (
              <Minimize2Icon className="size-4" />
            ) : (
              <Maximize2Icon className="size-4" />
            )}
          </Button>
          <DialogClose
            render={
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                className="text-muted-foreground hover:text-foreground cursor-pointer"
                title="Закрыть"
                aria-label="Закрыть"
              />
            }
          >
            <XIcon className="size-4" />
          </DialogClose>
        </div>

        <DialogHeader className="shrink-0 pr-20">
          <DialogTitle>
            {request ? `Заявка № ${request.number}` : "Заявка"}
          </DialogTitle>
          <DialogDescription>{subtitle || "Карточка заявки"}</DialogDescription>
          {request ? (
            <div className="flex flex-wrap items-center gap-2">
              <PurchaseRequestStatusBadge status={request.status} />
              <span className="text-sm text-muted-foreground tabular-nums">
                {formatPurchaseRequestAmount(request.totalAmount)}
              </span>
            </div>
          ) : null}
        </DialogHeader>

        <div className="min-h-0 flex-1 overflow-y-auto">
          {detailsQuery.isLoading ? (
            <Loading />
          ) : details && request ? (
            <PurchaseRequestDetailsCard
              details={details}
              actions={resolvePurchaseRequestActions({
                request,
                currentUserId,
                can,
                settings,
              })}
              onEditDraft={() => onEditDraft(request, details.items)}
              onDeleteDraft={() => onDeleteDraft(request)}
            />
          ) : (
            <ErrorState message="Не удалось открыть заявку." />
          )}
        </div>

        <DialogFooter className="shrink-0">
          <DialogClose render={<Button type="button" variant="outline" />}>
            Закрыть
          </DialogClose>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

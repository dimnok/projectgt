"use client";

import { useState } from "react";
import { ChevronLeftIcon, PencilIcon, Trash2Icon } from "lucide-react";
import { toast } from "sonner";

import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { useCurrentProfile } from "@/features/profile/hooks/use-current-profile";
import { usePurchaseRequestInvoiceFile } from "@/features/purchase-requests/hooks/use-purchase-request-invoice-file";
import {
  useDeletePurchaseRequestDraft,
  usePurchaseRequestDetails,
  usePurchaseRequestSettings,
  usePurchaseRequestWorkflow,
  useReplacePurchaseRequestItems,
} from "@/features/purchase-requests/hooks/use-purchase-requests";
import type {
  PurchaseRequest,
  PurchaseRequestItem,
  PurchaseRequestItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import {
  purchaseRequestActionsHasAny,
  resolvePurchaseRequestActions,
} from "@/features/purchase-requests/utils/actions";
import { formatPurchaseRequestAmount, formatRuDate } from "@/features/purchase-requests/utils/format";
import { purchaseRequestInvoicesReadyForSubmit } from "@/features/purchase-requests/utils/invoices";
import { idleActionsMessage } from "@/features/purchase-requests/utils/labels";
import { mapItemToDraft } from "@/features/purchase-requests/utils/mappers";
import { formatUserDisplayLabel } from "@/features/purchase-requests/utils/names";
import { latestPurchaseRequestReworkComment } from "@/features/purchase-requests/utils/settings";
import { invoiceStatusesVisible } from "@/features/purchase-requests/utils/status";
import { PurchaseRequestCommentSheet } from "@/features/purchase-requests/ui/mobile/purchase-request-comment-sheet";
import { PurchaseRequestFilePreviewSheet } from "@/features/purchase-requests/ui/mobile/purchase-request-file-preview-sheet";
import { PurchaseRequestHistorySection } from "@/features/purchase-requests/ui/mobile/purchase-request-history-section";
import { PurchaseRequestInvoiceSheet } from "@/features/purchase-requests/ui/mobile/purchase-request-invoice-sheet";
import { PurchaseRequestInvoicesSection } from "@/features/purchase-requests/ui/mobile/purchase-request-invoices-section";
import { PurchaseRequestItemSheet } from "@/features/purchase-requests/ui/mobile/purchase-request-item-sheet";
import { PurchaseRequestItemsSection } from "@/features/purchase-requests/ui/mobile/purchase-request-items-section";
import { PurchaseRequestStatusBadge } from "@/features/purchase-requests/ui/shared/purchase-request-status-badge";
import { usePermissions } from "@/hooks/use-permissions";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

type PurchaseRequestDetailsMobileProps = {
  requestId: string;
  onBack: () => void;
  /** Переход к редактированию черновика. */
  onEditDraft: (request: PurchaseRequest, items: PurchaseRequestItem[]) => void;
  /** Заявка удалена — возвращаемся к списку. */
  onDeleted: () => void;
};

/** Кнопка этапа в закреплённой панели снизу. */
type StageAction = {
  key: string;
  label: string;
  variant: "default" | "outline";
  disabled: boolean;
  onClick: () => void;
};

/**
 * Карточка заявки на весь экран (телефон).
 *
 * Один прокручиваемый экран без вкладок: шапка со статусом и суммой, затем
 * позиции, счета и история. Кнопки этапа закреплены снизу и всегда под рукой.
 * Логика общая с настольным видом: те же хуки, серверные функции и права.
 */
export function PurchaseRequestDetailsMobile({
  requestId,
  onBack,
  onEditDraft,
  onDeleted,
}: PurchaseRequestDetailsMobileProps) {
  const detailsQuery = usePurchaseRequestDetails(requestId);
  const details = detailsQuery.data ?? null;
  const request = details?.request ?? null;
  const items = details?.items ?? [];
  const invoices = details?.invoices ?? [];
  const history = details?.history ?? [];

  const { data: profile } = useCurrentProfile();
  const { can } = usePermissions();
  const settingsQuery = usePurchaseRequestSettings();

  const workflow = usePurchaseRequestWorkflow(requestId);
  const replaceItems = useReplacePurchaseRequestItems(requestId);
  const deleteDraft = useDeletePurchaseRequestDraft();
  const invoiceFile = usePurchaseRequestInvoiceFile();

  const [itemSheetOpen, setItemSheetOpen] = useState(false);
  const [invoiceSheetOpen, setInvoiceSheetOpen] = useState(false);
  const [commentKind, setCommentKind] = useState<
    "return" | "returnInvoice" | null
  >(null);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const reworkComment = latestPurchaseRequestReworkComment(history);
  const invoicesReady = purchaseRequestInvoicesReadyForSubmit(invoices);
  const workflowBusy = Object.values(workflow).some((item) => item.isPending);
  const actions = request
    ? resolvePurchaseRequestActions({
        request,
        currentUserId: profile?.id ?? null,
        can,
        settings: settingsQuery.data,
      })
    : null;

  function run(action: () => Promise<unknown>, success: string) {
    void action()
      .then(() => toast.success(success))
      .catch((error) =>
        toast.error(
          error instanceof Error
            ? error.message
            : "Не удалось выполнить действие"
        )
      );
  }

  // Кнопки этапа: показываем только доступные, порядок — по важности.
  const stageActions: StageAction[] = [];
  if (request && actions) {
    if (actions.canSubmit) {
      stageActions.push({
        key: "submit",
        label:
          request.status === "revision" ? "Отправить повторно" : "Отправить",
        variant: "default",
        disabled: workflowBusy || items.length === 0,
        onClick: () =>
          run(() => workflow.submit.mutateAsync(), "Заявка отправлена"),
      });
    }
    if (actions.canApprove) {
      stageActions.push({
        key: "approve",
        label: "Согласовать",
        variant: "default",
        disabled: workflowBusy,
        onClick: () =>
          run(() => workflow.approve.mutateAsync(), "Заявка согласована"),
      });
    }
    if (actions.canReturn) {
      stageActions.push({
        key: "return",
        label: "Вернуть",
        variant: "outline",
        disabled: workflowBusy,
        onClick: () => setCommentKind("return"),
      });
    }
    if (actions.canSubmitInvoices) {
      stageActions.push({
        key: "submit-invoices",
        label: "На согласование",
        variant: "default",
        disabled: workflowBusy || !invoicesReady,
        onClick: () =>
          run(() => workflow.submitInvoices.mutateAsync(), "Счета отправлены"),
      });
    }
    if (actions.canApproveInvoice) {
      stageActions.push({
        key: "approve-invoice",
        label: "Согласовать счета",
        variant: "default",
        disabled: workflowBusy,
        onClick: () =>
          run(() => workflow.approveInvoice.mutateAsync(), "Счета согласованы"),
      });
    }
    if (actions.canReturnInvoice) {
      stageActions.push({
        key: "return-invoice",
        label: "Вернуть счета",
        variant: "outline",
        disabled: workflowBusy,
        onClick: () => setCommentKind("returnInvoice"),
      });
    }
    if (actions.canQueuePayment) {
      stageActions.push({
        key: "queue-payment",
        label: "Завести на оплату",
        variant: "default",
        disabled: workflowBusy,
        onClick: () =>
          run(
            () => workflow.queuePayment.mutateAsync(),
            "Заявка в очереди оплаты"
          ),
      });
    }
    if (actions.canMarkPaid) {
      stageActions.push({
        key: "mark-paid",
        label: "Оплачено",
        variant: "default",
        disabled: workflowBusy,
        onClick: () =>
          run(() => workflow.markPaid.mutateAsync(), "Оплата отмечена"),
      });
    }
    if (actions.canMarkReceived) {
      stageActions.push({
        key: "mark-received",
        label: "Получено",
        variant: "default",
        disabled: workflowBusy,
        onClick: () =>
          run(
            () => workflow.markReceived.mutateAsync(),
            "Получение подтверждено"
          ),
      });
    }
  }

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <header className="shrink-0 border-b bg-background">
        <MobileAppBar
          title={request ? `Заявка № ${request.number}` : "Заявка"}
          className="border-b-0"
          leading={
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="rounded-full"
              aria-label="Назад к списку заявок"
              onClick={onBack}
            >
              <ChevronLeftIcon />
            </Button>
          }
        />

        {detailsQuery.isLoading ? (
          <div className="flex flex-col gap-1.5 px-4 pb-3.5">
            <Skeleton className="h-5 w-40" />
            <Skeleton className="h-4 w-52" />
          </div>
        ) : request ? (
          <div className="flex flex-col gap-1.5 px-4 pb-3.5">
            <div className="flex items-center justify-between gap-3">
              <PurchaseRequestStatusBadge status={request.status} />
              <span className="shrink-0 text-base font-semibold tabular-nums">
                {formatPurchaseRequestAmount(request.totalAmount)}
              </span>
            </div>
            <p className="truncate text-xs text-muted-foreground">
              {[
                request.objectName,
                formatUserDisplayLabel(request.createdByName),
                formatRuDate(request.createdAt),
              ]
                .filter(Boolean)
                .join(" · ")}
            </p>
          </div>
        ) : null}
      </header>

      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain px-4 pt-3.5 pb-6">
        {detailsQuery.isLoading ? (
          <div className="flex flex-col gap-2">
            <Skeleton className="h-20 w-full rounded-xl" />
            <Skeleton className="h-20 w-full rounded-xl" />
            <Skeleton className="h-20 w-full rounded-xl" />
          </div>
        ) : !details || !request || !actions ? (
          <ErrorState message="Не удалось открыть заявку." />
        ) : (
          <div className="flex flex-col gap-5">
            {/* Действия автора черновика */}
            {actions.canEditDraft || actions.canDeleteDraft ? (
              <div className="flex gap-2">
                {actions.canEditDraft ? (
                  <Button
                    type="button"
                    variant="outline"
                    className="flex-1"
                    onClick={() => onEditDraft(request, items)}
                  >
                    <PencilIcon data-icon="inline-start" />
                    Изменить
                  </Button>
                ) : null}
                {actions.canDeleteDraft ? (
                  <Button
                    type="button"
                    variant="outline"
                    className="flex-1 text-destructive hover:text-destructive"
                    onClick={() => setDeleteOpen(true)}
                  >
                    <Trash2Icon data-icon="inline-start" />
                    Удалить
                  </Button>
                ) : null}
              </div>
            ) : null}

            {/* Причина возврата и комментарий */}
            {request.status === "revision" && reworkComment ? (
              <div className="rounded-xl border border-orange-500/20 bg-orange-500/10 px-3 py-2.5">
                <p className="text-xs font-medium text-orange-700 dark:text-orange-300">
                  Возвращено на доработку
                </p>
                <p className="mt-1 text-sm">{reworkComment}</p>
              </div>
            ) : null}

            {request.comment?.trim() ? (
              <div className="rounded-xl bg-muted/50 px-3 py-2.5">
                <p className="text-xs font-medium text-muted-foreground">
                  Комментарий
                </p>
                <p className="mt-1 text-sm">{request.comment}</p>
              </div>
            ) : null}

            <PurchaseRequestItemsSection
              items={items}
              canEdit={actions.canEditItems}
              isPending={replaceItems.isPending}
              onAdd={() => setItemSheetOpen(true)}
              onDelete={(item) =>
                run(
                  () =>
                    replaceItems.mutateAsync(
                      items
                        .filter((row) => row.id !== item.id)
                        .map(mapItemToDraft)
                    ),
                  "Позиция удалена"
                )
              }
            />

            {invoiceStatusesVisible(request.status) ? (
              <PurchaseRequestInvoicesSection
                invoices={invoices}
                canEdit={actions.canSubmitInvoices}
                busyFileId={invoiceFile.busyFileId}
                isDeleting={workflow.deleteInvoice.isPending}
                onAdd={() => setInvoiceSheetOpen(true)}
                onPreview={(file) => invoiceFile.openFile(file, "preview")}
                onDownload={(file) => invoiceFile.openFile(file, "download")}
                onDelete={(invoiceId) =>
                  run(
                    () => workflow.deleteInvoice.mutateAsync(invoiceId),
                    "Счёт удалён"
                  )
                }
              />
            ) : null}

            <PurchaseRequestHistorySection history={history} />
          </div>
        )}
      </div>

      {/* Закреплённые кнопки этапа: всегда под рукой */}
      {request && actions ? (
        <div className="shrink-0 border-t bg-background px-4 py-2.5 pb-[max(0.625rem,env(safe-area-inset-bottom))]">
          {actions.canSubmit && items.length === 0 ? (
            <p className="pb-1.5 text-center text-xs text-muted-foreground">
              Добавьте позицию
            </p>
          ) : null}
          {actions.canSubmitInvoices && !invoicesReady ? (
            <p className="pb-1.5 text-center text-xs text-muted-foreground">
              Для каждого счёта нужен файл
            </p>
          ) : null}

          <div className="flex gap-2">
            {stageActions.map((action) => (
              <Button
                key={action.key}
                type="button"
                variant={action.variant}
                className="flex-1"
                disabled={action.disabled}
                onClick={action.onClick}
              >
                {action.label}
              </Button>
            ))}
          </div>

          {!purchaseRequestActionsHasAny(actions) ? (
            <p className="py-1 text-center text-xs text-muted-foreground">
              {idleActionsMessage(request.status)}
            </p>
          ) : null}
        </div>
      ) : null}

      {/* Формы и просмотр файла */}
      <PurchaseRequestItemSheet
        open={itemSheetOpen}
        isSaving={replaceItems.isPending}
        onOpenChange={setItemSheetOpen}
        onSubmit={(item: PurchaseRequestItemDraft) => {
          replaceItems.mutate([...items.map(mapItemToDraft), item], {
            onSuccess: () => {
              setItemSheetOpen(false);
              toast.success("Позиция добавлена");
            },
            onError: (error) =>
              toast.error(
                error instanceof Error
                  ? error.message
                  : "Не удалось добавить позицию"
              ),
          });
        }}
      />
      <PurchaseRequestInvoiceSheet
        open={invoiceSheetOpen}
        requestId={requestId}
        isSaving={workflow.createInvoice.isPending}
        onOpenChange={setInvoiceSheetOpen}
        onSubmit={(input) => {
          workflow.createInvoice.mutate(
            { requestId, ...input },
            {
              onSuccess: () => {
                setInvoiceSheetOpen(false);
                toast.success("Счёт добавлен");
              },
              onError: (error) =>
                toast.error(
                  error instanceof Error
                    ? error.message
                    : "Не удалось добавить счёт"
                ),
            }
          );
        }}
      />
      <PurchaseRequestCommentSheet
        open={commentKind !== null}
        title={
          commentKind === "returnInvoice"
            ? "Вернуть счета на доработку"
            : "Вернуть на доработку"
        }
        description="Укажите причину. Без неё заявка не вернётся."
        required
        isSaving={
          workflow.returnToRevision.isPending || workflow.returnInvoice.isPending
        }
        onOpenChange={(open) => {
          if (!open) {
            setCommentKind(null);
          }
        }}
        onSubmit={(comment) => {
          if (commentKind === "returnInvoice") {
            run(
              () => workflow.returnInvoice.mutateAsync(comment),
              "Счета возвращены"
            );
          } else {
            run(
              () => workflow.returnToRevision.mutateAsync(comment),
              "Заявка возвращена"
            );
          }
          setCommentKind(null);
        }}
      />
      <PurchaseRequestFilePreviewSheet
        file={invoiceFile.preview?.file ?? null}
        url={invoiceFile.preview?.url ?? null}
        onDownload={() => {
          if (invoiceFile.preview) {
            void invoiceFile.openFile(invoiceFile.preview.file, "download");
          }
        }}
        onOpenChange={(open) => {
          if (!open) {
            invoiceFile.closePreview();
          }
        }}
      />

      {/* Подтверждение удаления черновика */}
      <Dialog
        open={deleteOpen}
        onOpenChange={(open) => {
          if (!open) {
            setDeleteOpen(false);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Удалить черновик?</DialogTitle>
            <DialogDescription>
              {request ? `Заявка ${request.number} будет удалена.` : ""}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              disabled={deleteDraft.isPending}
              onClick={() => setDeleteOpen(false)}
            >
              Отмена
            </Button>
            <Button
              type="button"
              variant="destructive"
              disabled={deleteDraft.isPending}
              onClick={() => {
                deleteDraft.mutate(requestId, {
                  onSuccess: () => {
                    setDeleteOpen(false);
                    toast.success("Черновик удалён");
                    onDeleted();
                  },
                  onError: (error) =>
                    toast.error(
                      error instanceof Error
                        ? error.message
                        : "Не удалось удалить заявку"
                    ),
                });
              }}
            >
              Удалить
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

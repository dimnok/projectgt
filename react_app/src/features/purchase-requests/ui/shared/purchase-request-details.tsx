"use client";

import {
  DownloadIcon,
  EyeIcon,
  PencilIcon,
  PlusIcon,
  Trash2Icon,
} from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { usePurchaseRequestInvoiceFile } from "@/features/purchase-requests/hooks/use-purchase-request-invoice-file";
import {
  usePurchaseRequestWorkflow,
  useReplacePurchaseRequestItems,
} from "@/features/purchase-requests/hooks/use-purchase-requests";
import type {
  PurchaseRequestActionSet,
  PurchaseRequestDetails,
  PurchaseRequestItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import {
  purchaseRequestActionsHasAny,
} from "@/features/purchase-requests/utils/actions";
import {
  exportPurchaseRequestItemsExcel,
} from "@/features/purchase-requests/utils/export-items-excel";
import {
  formatPurchaseRequestAmount,
  formatQuantity,
  formatRuDate,
  formatRuDateTime,
} from "@/features/purchase-requests/utils/format";
import { formatUserDisplayLabel } from "@/features/purchase-requests/utils/names";
import { purchaseRequestInvoicesReadyForSubmit } from "@/features/purchase-requests/utils/invoices";
import { historyActionPhrase, idleActionsMessage } from "@/features/purchase-requests/utils/labels";
import { mapItemToDraft } from "@/features/purchase-requests/utils/mappers";
import { latestPurchaseRequestReworkComment } from "@/features/purchase-requests/utils/settings";
import { invoiceStatusesVisible } from "@/features/purchase-requests/utils/status";
import { PurchaseRequestCommentDialog } from "@/features/purchase-requests/ui/shared/purchase-request-comment-dialog";
import { PurchaseRequestFilePreviewDialog } from "@/features/purchase-requests/ui/shared/purchase-request-file-preview-dialog";
import { PurchaseRequestInvoiceDialog } from "@/features/purchase-requests/ui/shared/purchase-request-invoice-dialog";
import { PurchaseRequestInvoiceItemsList } from "@/features/purchase-requests/ui/shared/purchase-request-invoice-items-list";
import { PurchaseRequestItemDialog } from "@/features/purchase-requests/ui/shared/purchase-request-item-dialog";
import { PurchaseRequestStatusBadge } from "@/features/purchase-requests/ui/shared/purchase-request-status-badge";
import { cn } from "@/lib/utils";

type DetailsProps = {
  /** Заявка целиком: шапка, позиции, история и счета. */
  details: PurchaseRequestDetails;
  /** Какие действия доступны текущему пользователю на этом этапе. */
  actions: PurchaseRequestActionSet;
  /** Переход к редактированию черновика. */
  onEditDraft: () => void;
  /** Запрос удаления черновика. */
  onDeleteDraft: () => void;
  /** Дополнительные классы корня — задаёт отступы вызывающее окно. */
  className?: string;
};

/**
 * Содержимое заявки: сводка, позиции, счета, история и кнопки этапов.
 *
 * Компонент не отвечает за рамку и размеры — их задаёт вызывающее окно
 * `PurchaseRequestDetailsDialog`.
 */
export function PurchaseRequestDetailsCard({
  details,
  actions,
  onEditDraft,
  onDeleteDraft,
  className,
}: DetailsProps) {
  const { request, items, history, invoices } = details;
  const workflow = usePurchaseRequestWorkflow(request.id);
  const replaceItems = useReplacePurchaseRequestItems(request.id);
  const [itemDialogOpen, setItemDialogOpen] = useState(false);
  const [invoiceDialogOpen, setInvoiceDialogOpen] = useState(false);
  const [commentKind, setCommentKind] = useState<"return" | "returnInvoice" | null>(
    null
  );
  const invoiceFile = usePurchaseRequestInvoiceFile();
  const reworkComment = latestPurchaseRequestReworkComment(history);
  const invoicesReady = purchaseRequestInvoicesReadyForSubmit(invoices);
  const workflowBusy = Object.values(workflow).some((item) => item.isPending);

  function run(action: () => Promise<unknown>, success: string) {
    void action()
      .then(() => toast.success(success))
      .catch((error) =>
        toast.error(error instanceof Error ? error.message : "Не удалось выполнить действие")
      );
  }

  return (
    <div className={cn("flex flex-col gap-5", className)}>
      {actions.canEditDraft || actions.canDeleteDraft ? (
        <div className="flex justify-end gap-2">
          {actions.canEditDraft ? (
            <Button type="button" size="sm" variant="outline" onClick={onEditDraft}>
              <PencilIcon />
              Изменить
            </Button>
          ) : null}
          {actions.canDeleteDraft ? (
            <Button type="button" size="sm" variant="destructive" onClick={onDeleteDraft}>
              <Trash2Icon />
              Удалить
            </Button>
          ) : null}
        </div>
      ) : null}

      <div className="grid gap-3 sm:grid-cols-3">
        <KpiCard label="Статус">
          <PurchaseRequestStatusBadge status={request.status} />
        </KpiCard>
        <KpiCard label="Сумма">
          {formatPurchaseRequestAmount(request.totalAmount)}
        </KpiCard>
        <KpiCard label="Позиций">{items.length}</KpiCard>
      </div>

      {request.status === "revision" && reworkComment ? (
        <div className="rounded-xl bg-orange-500/10 px-3 py-2 text-sm">
          Возвращено на доработку: {reworkComment}
        </div>
      ) : null}

      {request.comment?.trim() ? (
        <div className="rounded-xl bg-muted/50 px-3 py-2 text-sm">
          {request.comment}
        </div>
      ) : null}

      <section className="flex flex-col gap-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="text-sm font-medium">Позиции</h3>
          <div className="flex gap-2">
            {items.length > 0 ? (
              <Button
                type="button"
                size="sm"
                variant="ghost"
                onClick={() => {
                  void exportPurchaseRequestItemsExcel({
                    requestNumber: request.number,
                    items,
                  })
                    .then(() => toast.success("Excel сохранён"))
                    .catch((error) =>
                      toast.error(
                        error instanceof Error
                          ? error.message
                          : "Не удалось сохранить Excel"
                      )
                    );
                }}
              >
                <DownloadIcon />
                Excel
              </Button>
            ) : null}
            {actions.canEditItems ? (
              <Button
                type="button"
                size="sm"
                variant="ghost"
                onClick={() => setItemDialogOpen(true)}
              >
                <PlusIcon />
                Добавить
              </Button>
            ) : null}
          </div>
        </div>
        {items.length === 0 ? (
          <p className="text-sm text-muted-foreground">Позиций пока нет.</p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-10">№</TableHead>
                <TableHead>Наименование</TableHead>
                <TableHead>Кол-во</TableHead>
                <TableHead>Ед.</TableHead>
                <TableHead>Артикул</TableHead>
                {actions.canEditItems ? <TableHead className="w-10" /> : null}
              </TableRow>
            </TableHeader>
            <TableBody>
              {items.map((item, index) => (
                <TableRow key={item.id}>
                  <TableCell>{index + 1}</TableCell>
                  <TableCell>{item.name}</TableCell>
                  <TableCell>{formatQuantity(item.quantity)}</TableCell>
                  <TableCell>{item.unit}</TableCell>
                  <TableCell>{item.article ?? "—"}</TableCell>
                  {actions.canEditItems ? (
                    <TableCell>
                      <Button
                        type="button"
                        size="icon"
                        variant="ghost"
                        aria-label="Удалить позицию"
                        disabled={replaceItems.isPending}
                        onClick={() =>
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
                      >
                        <Trash2Icon />
                      </Button>
                    </TableCell>
                  ) : null}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </section>

      {invoiceStatusesVisible(request.status) ? (
        <section className="flex flex-col gap-3">
          <div className="flex items-center justify-between gap-2">
            <h3 className="text-sm font-medium">Счета</h3>
            {actions.canSubmitInvoices ? (
              <Button
                type="button"
                size="sm"
                variant="ghost"
                onClick={() => setInvoiceDialogOpen(true)}
              >
                <PlusIcon />
                Добавить
              </Button>
            ) : null}
          </div>
          {invoices.length === 0 ? (
            <p className="text-sm text-muted-foreground">Счетов пока нет.</p>
          ) : (
            <div className="flex flex-col gap-2">
              {invoices.map((invoice) => (
                <div
                  key={invoice.id}
                  className="flex flex-col gap-2 rounded-xl bg-muted/40 px-3 py-2"
                >
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="min-w-0">
                      <p className="text-sm font-medium">
                        {invoice.supplierName ?? "Поставщик"} ·{" "}
                        {formatPurchaseRequestAmount(invoice.amount)}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {invoice.invoiceNumber ?? "без номера"} ·{" "}
                        {formatRuDate(invoice.invoiceDate)} ·{" "}
                        {invoice.invoiceFile ? invoice.invoiceFile.fileName : "нет файла"}
                      </p>
                    </div>
                    <div className="flex items-center gap-1">
                      {invoice.invoiceFile ? (
                        <>
                          <Button
                            type="button"
                            size="icon"
                            variant="ghost"
                            aria-label="Просмотреть счёт"
                            disabled={invoiceFile.busyFileId === invoice.invoiceFile.id}
                            onClick={() => invoiceFile.openFile(invoice.invoiceFile!, "preview")}
                          >
                            {invoiceFile.busyFileId === invoice.invoiceFile.id ? (
                              <Spinner />
                            ) : (
                              <EyeIcon />
                            )}
                          </Button>
                          <Button
                            type="button"
                            size="icon"
                            variant="ghost"
                            aria-label="Скачать счёт"
                            onClick={() => invoiceFile.openFile(invoice.invoiceFile!, "download")}
                          >
                            <DownloadIcon />
                          </Button>
                        </>
                      ) : null}
                      {actions.canSubmitInvoices ? (
                        <Button
                          type="button"
                          size="icon"
                          variant="ghost"
                          aria-label="Удалить счёт"
                          disabled={workflow.deleteInvoice.isPending}
                          onClick={() =>
                            run(
                              () => workflow.deleteInvoice.mutateAsync(invoice.id),
                              "Счёт удалён"
                            )
                          }
                        >
                          <Trash2Icon />
                        </Button>
                      ) : null}
                    </div>
                  </div>
                  <PurchaseRequestInvoiceItemsList items={invoice.items} />
                </div>
              ))}
            </div>
          )}
        </section>
      ) : null}

      <section className="flex flex-col gap-3">
        <h3 className="text-sm font-medium">История</h3>
        <ol className="flex flex-col gap-3 border-l pl-4">
          {history.map((entry) => (
            <li key={entry.id} className="relative">
              <span className="absolute top-1.5 -left-[21px] size-2 rounded-full bg-foreground" />
              <div className="flex items-start justify-between gap-3">
                <p className="text-sm">
                  <span className="font-medium">
                    {formatUserDisplayLabel(entry.userName)}
                  </span>{" "}
                  {historyActionPhrase(entry.action)}
                </p>
                <span className="shrink-0 text-xs text-muted-foreground">
                  {formatRuDateTime(entry.createdAt)}
                </span>
              </div>
              {entry.comment?.trim() ? (
                <p className="text-sm italic text-muted-foreground">
                  {entry.comment}
                </p>
              ) : null}
            </li>
          ))}
        </ol>
      </section>

      <div className="flex flex-wrap justify-end gap-2 border-t pt-3">
        {actions.canSubmit && items.length === 0 ? (
          <p className="mr-auto self-center text-sm text-muted-foreground">
            Добавьте позицию
          </p>
        ) : null}
        {actions.canSubmitInvoices && !invoicesReady ? (
          <p className="mr-auto self-center text-sm text-muted-foreground">
            Добавьте счёт
          </p>
        ) : null}
        {actions.canSubmit ? (
          <Button
            type="button"
            disabled={workflowBusy || items.length === 0}
            onClick={() => run(() => workflow.submit.mutateAsync(), "Заявка отправлена")}
          >
            {request.status === "revision" ? "Отправить повторно" : "Отправить"}
          </Button>
        ) : null}
        {actions.canApprove ? (
          <Button
            type="button"
            disabled={workflowBusy}
            onClick={() => run(() => workflow.approve.mutateAsync(), "Заявка согласована")}
          >
            Согласовать
          </Button>
        ) : null}
        {actions.canReturn ? (
          <Button
            type="button"
            variant="outline"
            disabled={workflowBusy}
            onClick={() => setCommentKind("return")}
          >
            Вернуть на доработку
          </Button>
        ) : null}
        {actions.canSubmitInvoices ? (
          <Button
            type="button"
            disabled={workflowBusy || !invoicesReady}
            onClick={() =>
              run(() => workflow.submitInvoices.mutateAsync(), "Счета отправлены")
            }
          >
            Отправить на согласование
          </Button>
        ) : null}
        {actions.canApproveInvoice ? (
          <Button
            type="button"
            disabled={workflowBusy}
            onClick={() =>
              run(() => workflow.approveInvoice.mutateAsync(), "Счета согласованы")
            }
          >
            Согласовать счета
          </Button>
        ) : null}
        {actions.canReturnInvoice ? (
          <Button
            type="button"
            variant="outline"
            disabled={workflowBusy}
            onClick={() => setCommentKind("returnInvoice")}
          >
            Вернуть счета
          </Button>
        ) : null}
        {actions.canQueuePayment ? (
          <Button
            type="button"
            disabled={workflowBusy}
            onClick={() =>
              run(() => workflow.queuePayment.mutateAsync(), "Заявка в очереди оплаты")
            }
          >
            Завести на оплату
          </Button>
        ) : null}
        {actions.canMarkPaid ? (
          <Button
            type="button"
            disabled={workflowBusy}
            onClick={() => run(() => workflow.markPaid.mutateAsync(), "Оплата отмечена")}
          >
            Оплачено
          </Button>
        ) : null}
        {actions.canMarkReceived ? (
          <Button
            type="button"
            disabled={workflowBusy}
            onClick={() =>
              run(() => workflow.markReceived.mutateAsync(), "Получение подтверждено")
            }
          >
            Получено
          </Button>
        ) : null}
        {!purchaseRequestActionsHasAny(actions) ? (
          <p className="text-sm text-muted-foreground">
            {idleActionsMessage(request.status)}
          </p>
        ) : null}
      </div>

      <PurchaseRequestItemDialog
        open={itemDialogOpen}
        isSaving={replaceItems.isPending}
        onOpenChange={setItemDialogOpen}
        onSubmit={(item: PurchaseRequestItemDraft) => {
          replaceItems.mutate([...items.map(mapItemToDraft), item], {
            onSuccess: () => {
              setItemDialogOpen(false);
              toast.success("Позиция добавлена");
            },
            onError: (error) =>
              toast.error(
                error instanceof Error ? error.message : "Не удалось добавить позицию"
              ),
          });
        }}
      />
      <PurchaseRequestInvoiceDialog
        open={invoiceDialogOpen}
        requestId={request.id}
        isSaving={workflow.createInvoice.isPending}
        onOpenChange={setInvoiceDialogOpen}
        onSubmit={(input) => {
          workflow.createInvoice.mutate(
            { requestId: request.id, ...input },
            {
              onSuccess: () => {
                setInvoiceDialogOpen(false);
                toast.success("Счёт добавлен");
              },
              onError: (error) =>
                toast.error(
                  error instanceof Error ? error.message : "Не удалось добавить счёт"
                ),
            }
          );
        }}
      />
      <PurchaseRequestCommentDialog
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
            run(() => workflow.returnInvoice.mutateAsync(comment), "Счета возвращены");
          } else {
            run(() => workflow.returnToRevision.mutateAsync(comment), "Заявка возвращена");
          }
          setCommentKind(null);
        }}
      />
      <PurchaseRequestFilePreviewDialog
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
    </div>
  );
}

function KpiCard({
  label,
  children,
}: {
  label: string;
  children: import("react").ReactNode;
}) {
  return (
    <div className="rounded-xl bg-muted/40 px-3 py-2">
      <p className="text-xs text-muted-foreground">{label}</p>
      <div className="mt-1 text-sm font-medium">{children}</div>
    </div>
  );
}

"use client";

import { useState } from "react";
import { FileTextIcon } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Spinner } from "@/components/ui/spinner";
import { useCompanyBankAccounts } from "@/features/company/hooks/use-company-bank-accounts";
import { useCompanyProfile } from "@/features/company/hooks/use-company-profile";
import { useContractors } from "@/features/contractors/hooks/use-contractors";
import {
  useDeleteSettlement,
  useSettlement,
} from "@/features/settlements/hooks/use-settlements";
import {
  useCreateSettlementPayment,
  useDeleteSettlementPayment,
  useSettlementPayments,
  useUpdateSettlementPayment,
} from "@/features/settlements/hooks/use-settlement-payments";
import { validateSettlementInvoiceData } from "@/features/settlements/api/settlement-invoice-pdf";
import {
  settlementInvoicePdfFileName,
  useSettlementInvoicePdf,
} from "@/features/settlements/hooks/use-settlement-invoice-pdf";
import type {
  Settlement,
  SettlementPayment,
  SettlementPaymentDraft,
} from "@/features/settlements/types/settlement.types";
import { SettlementDeleteDialog } from "@/features/settlements/ui/shared/settlement-delete-dialog";
import {
  SettlementFilePreviewDialog,
  type SettlementPreviewFile,
} from "@/features/settlements/ui/shared/settlement-file-preview-dialog";
import { SettlementFilesSection } from "@/features/settlements/ui/shared/settlement-files-section";
import { SettlementPaymentDialog } from "@/features/settlements/ui/shared/settlement-payment-dialog";
import { SettlementPaymentsList } from "@/features/settlements/ui/shared/settlement-payments-list";
import { SettlementPaymentsSkeleton } from "@/features/settlements/ui/shared/settlement-skeletons";
import { SettlementStatusBadge } from "@/features/settlements/ui/shared/settlement-status-badge";
import { SettlementTypeBadge } from "@/features/settlements/ui/shared/settlement-type-badge";
import { settlementPaymentStatusLabel } from "@/features/settlements/utils/payment-status";
import { settlementOperationTypeLabel } from "@/features/settlements/utils/operation-type";
import {
  formatCurrency,
  formatQuantity,
  formatRuDate,
  settlementRemaining,
} from "@/features/settlements/utils/settlement.utils";
import { cn } from "@/lib/utils";
import { saveBlobAsFile } from "@/features/settlements/utils/download";

type SettlementDetailsDialogProps = {
  settlement: Settlement | null;
  canUpdate: boolean;
  canDelete: boolean;
  onOpenChange: (open: boolean) => void;
  onEdit: (settlement: Settlement) => void;
  onDeleted: () => void;
};

/**
 * Карточка счёта на компьютере: сводка, реквизиты, суммы, документы и оплаты.
 *
 * Данные перечитываются по идентификатору, поэтому карточка показывает
 * актуальные суммы после правок и оплат.
 */
export function SettlementDetailsDialog({
  settlement,
  canUpdate,
  canDelete,
  onOpenChange,
  onEdit,
  onDeleted,
}: SettlementDetailsDialogProps) {
  const id = settlement?.id ?? null;
  const freshQuery = useSettlement(id);
  const current = freshQuery.data ?? settlement;

  const paymentsQuery = useSettlementPayments(id);
  const createPayment = useCreateSettlementPayment(id ?? "");
  const updatePayment = useUpdateSettlementPayment(id ?? "");
  const deletePayment = useDeleteSettlementPayment(id ?? "");
  const deleteSettlement = useDeleteSettlement();

  // Реквизиты компании, её банковский счёт и карточка контрагента нужны только
  // для PDF счёта — до нажатия кнопки их не грузим.
  const companyQuery = useCompanyProfile({ enabled: false });
  const bankAccountsQuery = useCompanyBankAccounts({ enabled: false });
  const contractorsQuery = useContractors({ enabled: false });
  const invoicePdf = useSettlementInvoicePdf();

  const [paymentDialogOpen, setPaymentDialogOpen] = useState(false);
  const [editingPayment, setEditingPayment] = useState<SettlementPayment | null>(
    null
  );
  const [paymentToDelete, setPaymentToDelete] =
    useState<SettlementPayment | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [pdfPreview, setPdfPreview] = useState<SettlementPreviewFile | null>(
    null
  );
  const [pdfBlob, setPdfBlob] = useState<Blob | null>(null);

  if (!current) {
    return null;
  }

  const status = current.paymentStatus;
  const remaining = settlementRemaining(current);
  const hasVat = current.vatRate !== null && current.vatRate > 0;
  const payments = paymentsQuery.data ?? [];

  async function handleGeneratePdf() {
    if (!current) return;

    const [companyResult, accountsResult, contractorsResult] = await Promise.all([
      companyQuery.refetch(),
      bankAccountsQuery.refetch(),
      contractorsQuery.refetch(),
    ]);

    const failure = [companyResult, accountsResult, contractorsResult].find(
      (result) => result.error
    );
    if (failure?.error) {
      toast.error(
        failure.error instanceof Error
          ? failure.error.message
          : "Не удалось загрузить данные для счёта"
      );
      return;
    }

    const company = companyResult.data;
    const accounts = accountsResult.data ?? [];
    const bankAccount =
      accounts.find((item) => item.isPrimary) ?? accounts[0] ?? null;
    const contractor =
      (contractorsResult.data ?? []).find(
        (item) => item.id === current.contractorId
      ) ?? null;

    const missing = validateSettlementInvoiceData({
      company,
      bankAccount,
      contractor,
    });
    if (missing.length > 0) {
      toast.error(
        `Не хватает данных для счёта: ${missing.join(", ")}. Заполните реквизиты в карточке компании и контрагента.`
      );
      return;
    }

    invoicePdf.mutate(
      {
        settlement: current,
        company,
        bankAccount,
        contractor,
        persist: canUpdate,
      },
      {
        onSuccess: (blob) => {
          setPdfBlob(blob);
          setPdfPreview({
            title: `Счёт на оплату № ${current.invoiceNumber}`,
            url: URL.createObjectURL(blob),
            isPdf: true,
          });
          toast.success(
            canUpdate
              ? "Счёт сформирован и сохранён в документы"
              : "Счёт сформирован"
          );
        },
        onError: (error) =>
          toast.error(
            error instanceof Error
              ? error.message
              : "Не удалось сформировать счёт"
          ),
      }
    );
  }

  function handlePaymentSubmit(draft: SettlementPaymentDraft) {
    if (editingPayment) {
      updatePayment.mutate(
        { paymentId: editingPayment.id, draft },
        {
          onSuccess: () => {
            setPaymentDialogOpen(false);
            setEditingPayment(null);
            toast.success("Оплата обновлена");
          },
          onError: (error) =>
            toast.error(
              error instanceof Error ? error.message : "Не удалось сохранить"
            ),
        }
      );
      return;
    }

    createPayment.mutate(draft, {
      onSuccess: () => {
        setPaymentDialogOpen(false);
        toast.success("Оплата добавлена");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось сохранить"
        ),
    });
  }

  function handlePaymentDelete() {
    if (!paymentToDelete) return;
    deletePayment.mutate(paymentToDelete.id, {
      onSuccess: () => {
        setPaymentToDelete(null);
        toast.success("Оплата удалена");
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось удалить"
        ),
    });
  }

  function handleSettlementDelete() {
    if (!current) return;
    deleteSettlement.mutate(current.id, {
      onSuccess: () => {
        setDeleteOpen(false);
        toast.success("Счёт удалён");
        onDeleted();
      },
      onError: (error) =>
        toast.error(
          error instanceof Error ? error.message : "Не удалось удалить счёт"
        ),
    });
  }

  return (
    <>
      <Dialog open={Boolean(settlement)} onOpenChange={onOpenChange}>
        <DialogContent className="max-h-[min(92vh,60rem)] overflow-y-auto sm:max-w-5xl">
          <DialogHeader>
            <DialogTitle className="flex flex-wrap items-center gap-2">
              Счёт {current.invoiceNumber}
              <SettlementTypeBadge type={current.operationType} />
              <SettlementStatusBadge status={status} />
            </DialogTitle>
            <DialogDescription>
              {[current.contractorName, current.objectName]
                .filter(Boolean)
                .join(" · ")}
            </DialogDescription>
          </DialogHeader>

          <div className="flex flex-wrap justify-end gap-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={invoicePdf.isPending}
              onClick={() => void handleGeneratePdf()}
            >
              {invoicePdf.isPending ? (
                <Spinner data-icon="inline-start" />
              ) : (
                <FileTextIcon />
              )}
              Сформировать PDF
            </Button>
            {canUpdate ? (
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => onEdit(current)}
              >
                Редактировать
              </Button>
            ) : null}
            {canDelete ? (
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setDeleteOpen(true)}
              >
                Удалить
              </Button>
            ) : null}
          </div>

          {/* Сводка */}
          <div className="bg-muted/30 grid grid-cols-2 gap-3 rounded-lg border p-3 sm:grid-cols-4">
            <SummaryItem label="К оплате" value={formatCurrency(current.totalToPay)} />
            <SummaryItem label="Оплачено" value={formatCurrency(current.paidAmount)} />
            <SummaryItem
              label="Остаток"
              value={formatCurrency(remaining)}
              tone={remaining > 0 ? "danger" : undefined}
            />
            <SummaryItem
              label="Статус"
              value={settlementPaymentStatusLabel(status)}
            />
          </div>

          {/* Реквизиты и суммы — две колонки */}
          <div className="grid gap-4 lg:grid-cols-2">
            <section className="rounded-lg border p-4">
              <p className="mb-3 font-medium">Реквизиты счёта</p>
              <dl className="grid gap-x-6 gap-y-3 sm:grid-cols-2">
                <InfoRow
                  label="Дата счёта"
                  value={formatRuDate(current.invoiceDate)}
                />
                <InfoRow
                  label="Тип"
                  value={settlementOperationTypeLabel(current.operationType)}
                />
                {current.actNumber ? (
                  <InfoRow label="Номер акта" value={current.actNumber} />
                ) : null}
                <InfoRow label="Договор" value={current.contractNumber || "—"} />
                <InfoRow
                  label="Контрагент"
                  value={current.contractorName || "—"}
                />
                <InfoRow label="Объект" value={current.objectName || "—"} />
                {current.note ? (
                  <InfoRow
                    label="Примечание"
                    value={current.note}
                    className="sm:col-span-2"
                  />
                ) : null}
              </dl>
            </section>

            <section className="rounded-lg border p-4">
              <p className="mb-3 font-medium">Суммы</p>
              <dl className="grid gap-x-6 gap-y-3 sm:grid-cols-2">
                <InfoRow
                  label="Без НДС"
                  value={formatCurrency(current.amount)}
                />
                {hasVat ? (
                  <InfoRow
                    label={`НДС ${formatQuantity(current.vatRate as number)}%`}
                    value={formatCurrency(current.vatAmount)}
                  />
                ) : null}
                <InfoRow
                  label={hasVat ? "Итого с НДС" : "К оплате"}
                  value={formatCurrency(current.totalToPay)}
                />
                <InfoRow
                  label="Оплачено"
                  value={formatCurrency(current.paidAmount)}
                />
                <InfoRow
                  label="Остаток"
                  value={formatCurrency(remaining)}
                />
              </dl>
            </section>
          </div>

          {/* Документы */}
          <section className="rounded-lg border p-4">
            <SettlementFilesSection
              settlementOperationId={current.id}
              canUpdate={canUpdate}
            />
          </section>

          {/* Оплаты */}
          <section className="flex flex-col gap-3 rounded-lg border p-4">
            <div className="flex items-center justify-between">
              <p className="font-medium">Оплаты</p>
              {canUpdate ? (
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setEditingPayment(null);
                    setPaymentDialogOpen(true);
                  }}
                >
                  Добавить оплату
                </Button>
              ) : null}
            </div>
            {paymentsQuery.isLoading ? (
              <SettlementPaymentsSkeleton />
            ) : (
              <SettlementPaymentsList
                payments={payments}
                canUpdate={canUpdate}
                onEdit={(payment) => {
                  setEditingPayment(payment);
                  setPaymentDialogOpen(true);
                }}
                onDelete={setPaymentToDelete}
              />
            )}
          </section>
        </DialogContent>
      </Dialog>

      <SettlementPaymentDialog
        key={editingPayment?.id ?? "new-payment"}
        open={paymentDialogOpen}
        payment={editingPayment}
        isSaving={createPayment.isPending || updatePayment.isPending}
        onOpenChange={(open) => {
          setPaymentDialogOpen(open);
          if (!open) setEditingPayment(null);
        }}
        onSubmit={handlePaymentSubmit}
      />

      <SettlementDeleteDialog
        open={Boolean(paymentToDelete)}
        title="Удалить оплату?"
        description={
          paymentToDelete
            ? `Оплата ${formatCurrency(paymentToDelete.amount)} от ${formatRuDate(
                paymentToDelete.paymentDate
              )} будет удалена.`
            : ""
        }
        isDeleting={deletePayment.isPending}
        onOpenChange={(open) => {
          if (!open) setPaymentToDelete(null);
        }}
        onConfirm={handlePaymentDelete}
      />

      <SettlementDeleteDialog
        open={deleteOpen}
        title="Удалить счёт?"
        description={`Счёт ${current.invoiceNumber}, все прикреплённые файлы и оплаты будут удалены без возможности восстановления.`}
        isDeleting={deleteSettlement.isPending}
        onOpenChange={setDeleteOpen}
        onConfirm={handleSettlementDelete}
      />

      <SettlementFilePreviewDialog
        file={pdfPreview}
        onDownload={() => {
          if (pdfBlob) saveBlobAsFile(pdfBlob, settlementInvoicePdfFileName(current));
        }}
        onOpenChange={(open) => {
          if (!open) {
            if (pdfPreview) URL.revokeObjectURL(pdfPreview.url);
            setPdfPreview(null);
            setPdfBlob(null);
          }
        }}
      />
    </>
  );
}

/** Ячейка сводки в карточке счёта. */
function SummaryItem({
  label,
  value,
  tone,
}: {
  label: string;
  value: string;
  tone?: "danger";
}) {
  return (
    <div>
      <p className="text-muted-foreground text-xs">{label}</p>
      <p
        className={cn(
          "font-medium tabular-nums",
          tone === "danger" && "text-destructive"
        )}
      >
        {value}
      </p>
    </div>
  );
}

/** Строка списка реквизитов или сумм. */
function InfoRow({
  label,
  value,
  className,
}: {
  label: string;
  value: string;
  className?: string;
}) {
  return (
    <div className={cn("flex min-w-0 flex-col gap-0.5", className)}>
      <dt className="text-muted-foreground text-xs">{label}</dt>
      <dd className="min-w-0 break-words text-sm font-medium">{value}</dd>
    </div>
  );
}

"use client";

import { useState } from "react";
import { ChevronLeftIcon, FileTextIcon, PlusIcon } from "lucide-react";
import { toast } from "sonner";

import { ErrorState } from "@/components/shared/error-state";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
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
import { type SettlementPreviewFile } from "@/features/settlements/ui/shared/settlement-file-preview-dialog";
import { SettlementFilePreview } from "@/features/settlements/ui/shared/settlement-file-preview";
import { SettlementFilesSection } from "@/features/settlements/ui/shared/settlement-files-section";
import { SettlementPaymentSheet } from "@/features/settlements/ui/mobile/settlement-payment-sheet";
import { SettlementPaymentsList } from "@/features/settlements/ui/shared/settlement-payments-list";
import { SettlementDetailsMobileSkeleton } from "@/features/settlements/ui/shared/settlement-skeletons";
import { SettlementStatusBadge } from "@/features/settlements/ui/shared/settlement-status-badge";
import { SettlementTypeBadge } from "@/features/settlements/ui/shared/settlement-type-badge";
import {
  formatCurrency,
  formatQuantity,
  formatRuDate,
  settlementRemaining,
} from "@/features/settlements/utils/settlement.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";
import { saveBlobAsFile } from "@/features/settlements/utils/download";

type SettlementDetailsMobileProps = {
  settlementId: string;
  onBack: () => void;
  onEdit: (settlement: Settlement) => void;
  onDeleted: () => void;
};

/**
 * Карточка счёта на телефоне: сводка, реквизиты, документы, оплаты и кнопки
 * внизу. Оплаты и документы открываются окнами снизу.
 */
export function SettlementDetailsMobile({
  settlementId,
  onBack,
  onEdit,
  onDeleted,
}: SettlementDetailsMobileProps) {
  const { can } = usePermissions();
  const canUpdate = can("settlements", "update");
  const canDelete = can("settlements", "delete");

  const settlementQuery = useSettlement(settlementId);
  const current = settlementQuery.data ?? null;

  const paymentsQuery = useSettlementPayments(settlementId);
  const createPayment = useCreateSettlementPayment(settlementId);
  const updatePayment = useUpdateSettlementPayment(settlementId);
  const deletePayment = useDeleteSettlementPayment(settlementId);
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

  if (settlementQuery.isLoading && !current) {
    return (
      <div
        data-fill-viewport
        className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
      >
        <MobileAppBar
          title="Счёт"
          leading={
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="rounded-full"
              aria-label="Назад"
              onClick={onBack}
            >
              <ChevronLeftIcon />
            </Button>
          }
        />
        <SettlementDetailsMobileSkeleton />
      </div>
    );
  }

  if (!current) {
    return (
      <div className="p-4">
        <ErrorState message="Счёт не найден" />
      </div>
    );
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
      toast.error(`Не хватает данных: ${missing.join(", ")}`);
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
          toast.success("Счёт сформирован");
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
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <MobileAppBar
        title={`Счёт ${current.invoiceNumber}`}
        leading={
          <Button
            type="button"
            variant="ghost"
            size="icon"
            className="rounded-full"
            aria-label="Назад"
            onClick={onBack}
          >
            <ChevronLeftIcon />
          </Button>
        }
      />

      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain px-4 pt-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        <div className="flex flex-col gap-4">
          <div className="flex flex-wrap items-center gap-2">
            <SettlementTypeBadge type={current.operationType} />
            <SettlementStatusBadge status={status} />
            <span className="text-muted-foreground text-sm">
              {formatRuDate(current.invoiceDate)}
            </span>
          </div>

          <div className="grid grid-cols-2 gap-3 rounded-lg border p-3">
            <Cell label="К оплате" value={formatCurrency(current.totalToPay)} />
            <Cell label="Оплачено" value={formatCurrency(current.paidAmount)} />
            <Cell
              label="Остаток"
              value={formatCurrency(remaining)}
              danger={remaining > 0}
            />
            <Cell label="Сумма без НДС" value={formatCurrency(current.amount)} />
          </div>

          <div className="rounded-lg border p-3">
            <p className="mb-2 font-medium">Реквизиты</p>
            <dl className="flex flex-col gap-2 text-sm">
              {current.actNumber ? (
                <Row label="Акт" value={current.actNumber} />
              ) : null}
              <Row label="Договор" value={current.contractNumber || "—"} />
              <Row label="Контрагент" value={current.contractorName || "—"} />
              <Row label="Объект" value={current.objectName || "—"} />
              {hasVat ? (
                <Row
                  label={`НДС (${formatQuantity(current.vatRate as number)}%)`}
                  value={formatCurrency(current.vatAmount)}
                />
              ) : null}
              {current.note ? <Row label="Примечание" value={current.note} /> : null}
            </dl>
          </div>

          <SettlementFilesSection
            settlementOperationId={current.id}
            canUpdate={canUpdate}
          />

          <Separator />

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
                <PlusIcon />
                Оплата
              </Button>
            ) : null}
          </div>
          <SettlementPaymentsList
            payments={payments}
            canUpdate={canUpdate}
            onEdit={(payment) => {
              setEditingPayment(payment);
              setPaymentDialogOpen(true);
            }}
            onDelete={setPaymentToDelete}
          />

          <div className="flex flex-col gap-2 pt-2">
            <Button
              type="button"
              variant="outline"
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
                onClick={() => onEdit(current)}
              >
                Редактировать
              </Button>
            ) : null}
            {canDelete ? (
              <Button
                type="button"
                variant="outline"
                className="text-destructive"
                onClick={() => setDeleteOpen(true)}
              >
                Удалить счёт
              </Button>
            ) : null}
          </div>
        </div>
      </div>

      <SettlementPaymentSheet
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

      <SettlementFilePreview
        file={pdfPreview}
        onDownload={() => {
          if (pdfBlob) {
            saveBlobAsFile(pdfBlob, settlementInvoicePdfFileName(current));
          }
        }}
        onOpenChange={(open) => {
          if (!open) {
            if (pdfPreview) URL.revokeObjectURL(pdfPreview.url);
            setPdfPreview(null);
            setPdfBlob(null);
          }
        }}
      />
    </div>
  );
}

/** Ячейка сводки: подпись сверху, значение снизу. */
function Cell({
  label,
  value,
  danger,
}: {
  label: string;
  value: string;
  danger?: boolean;
}) {
  return (
    <div>
      <p className="text-muted-foreground text-xs">{label}</p>
      <p
        className={
          danger ? "text-destructive font-medium tabular-nums" : "font-medium tabular-nums"
        }
      >
        {value}
      </p>
    </div>
  );
}

/** Строка реквизитов: подпись слева, значение справа. */
function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex gap-2">
      <dt className="text-muted-foreground w-28 shrink-0">{label}</dt>
      <dd className="min-w-0 break-words font-medium">{value}</dd>
    </div>
  );
}

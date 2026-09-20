"use client";

import {
  CoinsIcon,
  ListOrderedIcon,
  PencilIcon,
  ReceiptIcon,
  Trash2Icon,
  UploadIcon,
  UsersIcon,
} from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import {
  ContextMenuItem,
  ContextMenuSeparator,
} from "@/components/ui/context-menu";
import { usePayrollExport } from "@/features/payrolls/hooks/use-payroll-export";
import { usePayrollTransactionMutations } from "@/features/payrolls/hooks/use-payroll-mutations";
import { usePayrollTransactions } from "@/features/payrolls/hooks/use-payroll-transactions";
import { PayrollDeleteDialog } from "@/features/payrolls/ui/shared/payroll-delete-dialog";
import { PayrollImportDialog } from "@/features/payrolls/ui/shared/payroll-import-dialog";
import { PayrollTransactionDialog } from "@/features/payrolls/ui/shared/payroll-transaction-dialog";
import type {
  PayrollTransactionItem,
  PayrollTransactionKind,
} from "@/features/payrolls/types/payroll.types";
import { PayrollsErrorState } from "@/features/payrolls/ui/desktop/payrolls-error-state";
import { PayrollExportButton } from "@/features/payrolls/ui/desktop/payrolls-export-button";
import { PayrollFilterDropdown } from "@/features/payrolls/ui/desktop/payrolls-filter-dropdown";
import {
  PayrollFilterBar,
  PayrollFilterControls,
  type PayrollListFilterProps,
  type PayrollObjectFilterProps,
} from "@/features/payrolls/ui/desktop/payrolls-filter-bar";
import { PayrollKpiHeader } from "@/features/payrolls/ui/desktop/payrolls-kpi";
import { PayrollPeriodSwitcher } from "@/features/payrolls/ui/desktop/payrolls-period-switcher";
import { PayrollSearchField } from "@/features/payrolls/ui/desktop/payrolls-search-field";
import {
  PayrollTable,
  type PayrollTableColumn,
} from "@/features/payrolls/ui/desktop/payrolls-table";
import {
  formatPayrollMoney,
  getPeriodLabel,
  getPeriodPhrase,
  payrollAuthorTooltip,
} from "@/features/payrolls/utils/payroll.utils";
import { exportPayrollTransactionsToExcel } from "@/features/payrolls/utils/export-payroll-excel";
import { buildListEmptyText } from "@/features/payrolls/utils/payroll-lists";
import { usePermissions } from "@/hooks/use-permissions";
import { formatRuDate } from "@/features/timesheet/utils/timesheet-date";

type PayrollsTransactionsTabProps = PayrollListFilterProps &
  PayrollObjectFilterProps & {
    kind: PayrollTransactionKind;
    onOpenEmployeeDetails?: (employeeId: string) => void;
  };

/** Вкладка списка премий или удержаний. */
export function PayrollsTransactionsTab({
  kind,
  onOpenEmployeeDetails,
  ...filters
}: PayrollsTransactionsTabProps) {
  const isPenalty = kind === "penalty";
  const { isExporting, exportToExcel } = usePayrollExport();

  const { rows, totals, isLoading, isFetching, isError, error, refetch } =
    usePayrollTransactions({
      kind,
      period: filters.period,
      selectedObjectIds: filters.selectedObjectIds,
      search: filters.search,
    });

  const periodLabel = getPeriodLabel(filters.period);

  const { can } = usePermissions();
  const canDelete = can("payroll", "delete");
  const canUpdate = can("payroll", "update");
  const canCreate = can("payroll", "create");
  const { create, remove } = usePayrollTransactionMutations(kind);
  const subject = isPenalty ? "Удержание" : "Премия";
  const [importOpen, setImportOpen] = useState(false);
  const [pendingEdit, setPendingEdit] =
    useState<PayrollTransactionItem | null>(null);
  const [pendingDelete, setPendingDelete] =
    useState<PayrollTransactionItem | null>(null);

  async function confirmDelete() {
    const row = pendingDelete;
    if (!row) {
      return;
    }
    try {
      await remove.mutateAsync(row.id);
      setPendingDelete(null);
      toast.success(`${subject} удалено`, {
        action: {
          label: "Вернуть",
          onClick: () => {
            void create
              .mutateAsync({
                id: row.id,
                draft: {
                  employeeId: row.employeeId,
                  objectId: row.objectId ?? "",
                  date: row.date,
                  amount: row.amount,
                  reason: row.note || null,
                },
              })
              .catch((error) => {
                toast.error(
                  error instanceof Error
                    ? error.message
                    : "Не удалось вернуть запись"
                );
              });
          },
        },
      });
    } catch (error) {
      toast.error(
        error instanceof Error ? error.message : "Не удалось удалить запись"
      );
    }
  }

  const rowMenu = (row: PayrollTransactionItem) => (
    <>
      <ContextMenuItem
        disabled={!canUpdate}
        onClick={() => setPendingEdit(row)}
      >
        <PencilIcon />
        Изменить
      </ContextMenuItem>
      <ContextMenuSeparator />
      <ContextMenuItem
        variant="destructive"
        disabled={!canDelete}
        onClick={() => setPendingDelete(row)}
      >
        <Trash2Icon />
        Удалить
      </ContextMenuItem>
    </>
  );

  const handleExport = () =>
    exportToExcel({
      rowsCount: rows.length,
      successMessage: isPenalty
        ? "Excel-файл удержаний сформирован"
        : "Excel-файл премий сформирован",
      run: () => exportPayrollTransactionsToExcel({ kind, periodLabel, rows }),
    });

  const amountText = (amount: number) =>
    isPenalty ? `−${formatPayrollMoney(amount)}` : `+${formatPayrollMoney(amount)}`;

  const columns: PayrollTableColumn<PayrollTransactionItem>[] = [
    {
      key: "date",
      label: "Дата",
      align: "left",
      widthClass: "w-28",
      render: (row) => formatRuDate(row.date),
      footer: "Итого",
    },
    {
      key: "employee",
      label: "Сотрудник",
      widthClass: "w-full min-w-[220px]",
      render: (row) =>
        onOpenEmployeeDetails ? (
          <button
            type="button"
            onClick={() => onOpenEmployeeDetails(row.employeeId)}
            title={row.employeeName}
            className="max-w-full cursor-pointer truncate text-left font-medium transition-colors hover:text-primary hover:underline focus:outline-none"
          >
            {row.employeeName}
          </button>
        ) : (
          <span className="block truncate font-medium" title={row.employeeName}>
            {row.employeeName}
          </span>
        ),
    },
    {
      key: "amount",
      label: "Сумма",
      align: "right",
      widthClass: "w-32",
      cellClassName: isPenalty
        ? "font-medium text-destructive"
        : "font-medium text-success",
      render: (row) => amountText(row.amount),
      footer: amountText(totals.amount),
      footerClassName: isPenalty ? "text-destructive" : "text-success",
    },
    {
      key: "object",
      label: "Объект",
      align: "left",
      widthClass: "max-w-48",
      render: (row) =>
        row.objectName ? (
          <span className="block truncate" title={row.objectName}>
            {row.objectName}
          </span>
        ) : (
          <span className="text-muted-foreground/50">—</span>
        ),
    },
    {
      key: "note",
      label: "Примечание",
      align: "left",
      widthClass: "max-w-80",
      render: (row) =>
        row.note ? (
          <span className="block truncate" title={row.note}>
            {row.note}
          </span>
        ) : (
          <span className="text-muted-foreground/50">—</span>
        ),
    },
    {
      key: "author",
      label: "Автор",
      align: "left",
      widthClass: "w-40",
      render: (row) => (
        <span
          className="block truncate text-muted-foreground"
          title={payrollAuthorTooltip(row)}
        >
          {row.createdByName || "—"}
        </span>
      ),
    },
  ];

  const emptyText = buildListEmptyText({
    period: filters.period,
    periodLabel,
    search: filters.search,
    subject: {
      genitivePlural: "записей",
      nominativePlural: "операции",
      genitiveSingular: "записи",
    },
  });

  return (
    <>
      <PayrollKpiHeader
        columns={3}
        isFetching={isFetching}
        items={[
          {
            key: "amount",
            label: isPenalty ? "Удержания" : "Премии",
            value: formatPayrollMoney(totals.amount),
            subtext: `Сумма ${getPeriodPhrase(filters.period)}`,
            icon: isPenalty ? ReceiptIcon : CoinsIcon,
          },
          {
            key: "count",
            label: "Записей",
            value: String(totals.count),
            subtext: periodLabel,
            icon: ListOrderedIcon,
          },
          {
            key: "employees",
            label: "Сотрудников",
            value: String(totals.employees),
            subtext: periodLabel,
            icon: UsersIcon,
          },
        ]}
      />

      <PayrollFilterBar
        controls={
          <PayrollFilterControls>
            <PayrollPeriodSwitcher
              monthLabel={filters.monthLabel}
              isCurrentMonth={filters.isCurrentMonth}
              onPrevMonth={filters.goToPreviousMonth}
              onNextMonth={filters.goToNextMonth}
              allTime={filters.allTime}
              onAllTimeChange={filters.setAllTime}
              disabled={isLoading}
            />
            <PayrollFilterDropdown
              title="Объекты"
              options={filters.objectOptions}
              selectedKeys={filters.selectedObjectIds}
              onChange={filters.setSelectedObjectIds}
              multiple
              disabled={isLoading || filters.objectOptions.length === 0}
            />
          </PayrollFilterControls>
        }
        search={
          <PayrollSearchField
            value={filters.search}
            onChange={filters.setSearch}
            disabled={isLoading}
          />
        }
        actions={
          <>
            {canCreate ? (
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="h-9"
                onClick={() => setImportOpen(true)}
              >
                <UploadIcon data-icon="inline-start" />
                Импорт
              </Button>
            ) : null}
            <PayrollExportButton
              canExport={filters.canExport}
              isExporting={isExporting}
              disabled={rows.length === 0}
              onExport={handleExport}
            />
          </>
        }
      />

      {isError && rows.length === 0 ? (
        <PayrollsErrorState
          title={
            isPenalty ? "Ошибка загрузки удержаний" : "Ошибка загрузки премий"
          }
          message={error?.message}
          onRetry={refetch}
        />
      ) : (
        <PayrollTable
          columns={columns}
          rows={rows}
          rowKey={(row) => row.id}
          rowMenu={rowMenu}
          empty={
            <EmptyState
              icon={isPenalty ? ReceiptIcon : CoinsIcon}
              title={emptyText.title}
              description={emptyText.description}
              action={
                filters.period.mode === "month" ? (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => filters.setAllTime(true)}
                  >
                    {filters.search
                      ? "Искать за всё время"
                      : "Показать за всё время"}
                  </Button>
                ) : null
              }
            />
          }
        />
      )}

      {importOpen ? (
        <PayrollImportDialog
          kind={kind}
          objectOptions={filters.objectOptions}
          defaultObjectId={
            filters.selectedObjectIds.length === 1
              ? filters.selectedObjectIds[0]
              : ""
          }
          onClose={() => setImportOpen(false)}
        />
      ) : null}

      {pendingEdit ? (
        <PayrollTransactionDialog
          kind={kind}
          employee={{
            id: pendingEdit.employeeId,
            fullName: pendingEdit.employeeName,
          }}
          objectOptions={filters.objectOptions}
          defaultObjectId={pendingEdit.objectId ?? ""}
          initial={{
            id: pendingEdit.id,
            date: pendingEdit.date,
            amount: pendingEdit.amount,
            objectId: pendingEdit.objectId,
            reason: pendingEdit.note,
          }}
          onClose={() => setPendingEdit(null)}
        />
      ) : null}

      <PayrollDeleteDialog
        open={Boolean(pendingDelete)}
        title={`Удалить ${isPenalty ? "удержание" : "премию"}?`}
        description={
          pendingDelete
            ? `${formatRuDate(pendingDelete.date)} · ${pendingDelete.employeeName} · ${amountText(pendingDelete.amount)}`
            : ""
        }
        isDeleting={remove.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setPendingDelete(null);
          }
        }}
        onConfirm={() => void confirmDelete()}
      />
    </>
  );
}

"use client";

import {
  BanknoteIcon,
  ListOrderedIcon,
  PencilIcon,
  Trash2Icon,
  TrendingUpIcon,
  UploadIcon,
  WalletIcon,
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
import { usePayrollPayoutMutations } from "@/features/payrolls/hooks/use-payroll-mutations";
import { usePayrollPayouts } from "@/features/payrolls/hooks/use-payroll-payouts";
import { PayrollDeleteDialog } from "@/features/payrolls/ui/shared/payroll-delete-dialog";
import { PayrollImportDialog } from "@/features/payrolls/ui/shared/payroll-import-dialog";
import { PayrollPayoutDialog } from "@/features/payrolls/ui/shared/payroll-payout-dialog";
import type { PayrollPayoutItem } from "@/features/payrolls/types/payroll.types";
import { PayrollsErrorState } from "@/features/payrolls/ui/desktop/payrolls-error-state";
import { PayrollExportButton } from "@/features/payrolls/ui/desktop/payrolls-export-button";
import {
  PayrollFilterBar,
  PayrollFilterControls,
  type PayrollListFilterProps,
} from "@/features/payrolls/ui/desktop/payrolls-filter-bar";
import { PayrollKpiHeader } from "@/features/payrolls/ui/desktop/payrolls-kpi";
import { PayrollPeriodSwitcher } from "@/features/payrolls/ui/desktop/payrolls-period-switcher";
import { PayrollSearchField } from "@/features/payrolls/ui/desktop/payrolls-search-field";
import {
  PayrollTable,
  type PayrollTableColumn,
} from "@/features/payrolls/ui/desktop/payrolls-table";
import {
  buildListEmptyText,
  sumPayoutAmount,
} from "@/features/payrolls/utils/payroll-lists";
import {
  formatPayrollMoney,
  getPeriodLabel,
  getPeriodPhrase,
  payoutMethodLabel,
  payoutTypeLabel,
  payrollAuthorTooltip,
} from "@/features/payrolls/utils/payroll.utils";
import { exportPayrollPayoutsToExcel } from "@/features/payrolls/utils/export-payroll-excel";
import { usePermissions } from "@/hooks/use-permissions";
import { formatRuDate } from "@/features/timesheet/utils/timesheet-date";

type PayrollsPayoutsTabProps = PayrollListFilterProps & {
  onOpenEmployeeDetails?: (employeeId: string) => void;
};

/** Вкладка списка выплат. */
export function PayrollsPayoutsTab({
  onOpenEmployeeDetails,
  ...filters
}: PayrollsPayoutsTabProps) {
  const { isExporting, exportToExcel } = usePayrollExport();

  const { rows, totals, isLoading, isFetching, isError, error, refetch } =
    usePayrollPayouts({
      period: filters.period,
      search: filters.search,
    });

  const periodLabel = getPeriodLabel(filters.period);

  const { can } = usePermissions();
  const canDelete = can("payroll", "delete");
  const canUpdate = can("payroll", "update");
  const canCreate = can("payroll", "create");
  const { create, remove } = usePayrollPayoutMutations();
  const [importOpen, setImportOpen] = useState(false);
  const [pendingEdit, setPendingEdit] = useState<PayrollPayoutItem | null>(null);
  const [pendingDelete, setPendingDelete] = useState<PayrollPayoutItem | null>(
    null
  );

  async function confirmDelete() {
    const row = pendingDelete;
    if (!row) {
      return;
    }
    try {
      await remove.mutateAsync(row.id);
      setPendingDelete(null);
      toast.success("Выплата удалена", {
        action: {
          label: "Вернуть",
          onClick: () => {
            void create
              .mutateAsync({
                id: row.id,
                draft: {
                  employeeId: row.employeeId,
                  date: row.date,
                  amount: row.amount,
                  method: row.method,
                  type: row.type,
                  comment: row.comment || null,
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

  const rowMenu = (row: PayrollPayoutItem) => (
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
      successMessage: "Excel-файл выплат сформирован",
      run: () => exportPayrollPayoutsToExcel({ periodLabel, rows }),
    });

  const columns: PayrollTableColumn<PayrollPayoutItem>[] = [
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
      cellClassName: "font-medium",
      render: (row) => formatPayrollMoney(row.amount),
      footer: formatPayrollMoney(totals.amount),
    },
    {
      key: "method",
      label: "Способ",
      align: "left",
      widthClass: "w-48",
      render: (row) => payoutMethodLabel(row.method),
    },
    {
      key: "type",
      label: "Тип",
      align: "left",
      widthClass: "w-28",
      render: (row) => payoutTypeLabel(row.type),
    },
    {
      key: "comment",
      label: "Комментарий",
      align: "left",
      widthClass: "max-w-80",
      render: (row) =>
        row.comment ? (
          <span className="block truncate" title={row.comment}>
            {row.comment}
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
      genitivePlural: "выплат",
      nominativePlural: "выплаты",
      genitiveSingular: "выплаты",
    },
  });

  return (
    <>
      <PayrollKpiHeader
        isFetching={isFetching}
        items={[
          {
            key: "amount",
            label: "Выплачено",
            value: formatPayrollMoney(totals.amount),
            subtext: `Факт выплат ${getPeriodPhrase(filters.period)}`,
            icon: BanknoteIcon,
          },
          {
            key: "salary",
            label: "Зарплата",
            value: formatPayrollMoney(sumPayoutAmount(rows, "salary")),
            subtext: periodLabel,
            icon: WalletIcon,
          },
          {
            key: "advance",
            label: "Авансы",
            value: formatPayrollMoney(sumPayoutAmount(rows, "advance")),
            subtext: periodLabel,
            icon: TrendingUpIcon,
          },
          {
            key: "count",
            label: "Записей",
            value: String(totals.count),
            subtext: `${totals.employees} сотрудников`,
            icon: ListOrderedIcon,
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
          title="Ошибка загрузки выплат"
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
              icon={BanknoteIcon}
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
          kind="payout"
          objectOptions={[]}
          defaultObjectId=""
          onClose={() => setImportOpen(false)}
        />
      ) : null}

      {pendingEdit ? (
        <PayrollPayoutDialog
          employee={{
            id: pendingEdit.employeeId,
            fullName: pendingEdit.employeeName,
          }}
          defaultAmount=""
          initial={{
            id: pendingEdit.id,
            date: pendingEdit.date,
            amount: pendingEdit.amount,
            method: pendingEdit.method,
            type: pendingEdit.type,
            comment: pendingEdit.comment,
          }}
          onClose={() => setPendingEdit(null)}
        />
      ) : null}

      <PayrollDeleteDialog
        open={Boolean(pendingDelete)}
        title="Удалить выплату?"
        description={
          pendingDelete
            ? `${formatRuDate(pendingDelete.date)} · ${pendingDelete.employeeName} · ${formatPayrollMoney(pendingDelete.amount)}`
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

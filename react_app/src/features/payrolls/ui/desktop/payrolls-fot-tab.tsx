"use client";

import {
  BanknoteIcon,
  CoinsIcon,
  HistoryIcon,
  ReceiptIcon,
  ScaleIcon,
  UserRoundIcon,
  UsersIcon,
  WalletIcon,
} from "lucide-react";
import { useMemo, useState } from "react";

import { EmptyState } from "@/components/shared/empty-state";
import { Button } from "@/components/ui/button";
import {
  ContextMenuItem,
  ContextMenuSeparator,
} from "@/components/ui/context-menu";
import { EmployeeStatusBadge } from "@/features/employees/ui/shared/employee-status-badge";
import { usePayrollExport } from "@/features/payrolls/hooks/use-payroll-export";
import { usePayrolls } from "@/features/payrolls/hooks/use-payrolls";
import {
  PayrollBulkDialog,
  type PayrollBulkKind,
} from "@/features/payrolls/ui/shared/payroll-bulk-dialog";
import { PayrollEmployeeHistoryDialog } from "@/features/payrolls/ui/shared/payroll-employee-history-dialog";
import { PayrollPayoutDialog } from "@/features/payrolls/ui/shared/payroll-payout-dialog";
import { PayrollTransactionDialog } from "@/features/payrolls/ui/shared/payroll-transaction-dialog";
import { usePermissions } from "@/hooks/use-permissions";
import type {
  PayrollEmployeeStatusFilter,
  PayrollGridRow,
  PayrollTableSort,
} from "@/features/payrolls/types/payroll.types";
import { PayrollsErrorState } from "@/features/payrolls/ui/desktop/payrolls-error-state";
import { PayrollExportButton } from "@/features/payrolls/ui/desktop/payrolls-export-button";
import { PayrollFilterDropdown } from "@/features/payrolls/ui/desktop/payrolls-filter-dropdown";
import {
  PayrollFilterBar,
  PayrollFilterControls,
} from "@/features/payrolls/ui/desktop/payrolls-filter-bar";
import { PayrollKpiHeader } from "@/features/payrolls/ui/desktop/payrolls-kpi";
import { PayrollPeriodSwitcher } from "@/features/payrolls/ui/desktop/payrolls-period-switcher";
import { PayrollSearchField } from "@/features/payrolls/ui/desktop/payrolls-search-field";
import {
  PayrollTable,
  type PayrollTableColumn,
} from "@/features/payrolls/ui/desktop/payrolls-table";
import {
  balanceSubtext,
  formatPayrollMoney,
  formatPayrollMoneyOrDash,
  formatPayrollQuantity,
  getPeriodLabel,
} from "@/features/payrolls/utils/payroll.utils";
import { sortPayrollRows } from "@/features/payrolls/utils/payroll-rows";
import { exportPayrollSheetToExcel } from "@/features/payrolls/utils/export-payroll-excel";
import { cn } from "@/lib/utils";

const STATUS_OPTIONS: { key: PayrollEmployeeStatusFilter; label: string }[] = [
  { key: "all", label: "Все" },
  { key: "working", label: "Работает" },
  { key: "fired", label: "Уволен" },
];

type PayrollsFotTabProps = {
  year: number;
  month: number;
  isCurrentMonth: boolean;
  onPrevMonth: () => void;
  onNextMonth: () => void;
  search: string;
  onSearchChange: (query: string) => void;
  objectOptions: { key: string; label: string }[];
  selectedObjectIds: string[];
  onSelectedObjectIdsChange: (ids: string[]) => void;
  canExport: boolean;
  onOpenEmployeeDetails?: (employeeId: string) => void;
};

/** Вкладка ФОТ: ведомость за месяц. */
export function PayrollsFotTab({
  year,
  month,
  isCurrentMonth,
  onPrevMonth,
  onNextMonth,
  search,
  onSearchChange,
  objectOptions,
  selectedObjectIds,
  onSelectedObjectIdsChange,
  canExport,
  onOpenEmployeeDetails,
}: PayrollsFotTabProps) {
  const [status, setStatus] = useState<PayrollEmployeeStatusFilter>("all");
  const [sort, setSort] = useState<PayrollTableSort | null>(null);
  const [operation, setOperation] = useState<{
    kind: "bonus" | "penalty" | "payout";
    employeeId: string;
    fullName: string;
    defaultAmount: string;
    /** Долг компании сотруднику — для предупреждения о переплате. */
    debt: number;
  } | null>(null);
  const [historyEmployee, setHistoryEmployee] = useState<{
    id: string;
    fullName: string;
  } | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [bulkKind, setBulkKind] = useState<PayrollBulkKind | null>(null);
  const { isExporting, exportToExcel } = usePayrollExport();
  const { can } = usePermissions();
  const canCreate = can("payroll", "create");

  const {
    gridRows,
    totals,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
  } = usePayrolls({ year, month, selectedObjectIds, search, status });

  const rows = useMemo(
    () => sortPayrollRows(gridRows, sort),
    [gridRows, sort]
  );

  const monthLabel = getPeriodLabel({ mode: "month", year, month });

  const handleExport = () =>
    exportToExcel({
      rowsCount: rows.length,
      successMessage: "Excel-файл ведомости сформирован",
      run: () => exportPayrollSheetToExcel({ rows, periodLabel: monthLabel }),
    });

  const columns: PayrollTableColumn<PayrollGridRow>[] = [
    {
      key: "employee",
      label: "Сотрудник",
      widthClass: "w-full min-w-[260px] max-w-[360px]",
      sortFirst: "asc",
      render: (row) => (
        <div className="flex min-w-0 items-center gap-2">
          {canCreate ? (
            <input
              type="checkbox"
              className="size-4 shrink-0 accent-foreground"
              checked={selectedIds.has(row.employeeId)}
              aria-label={`Выбрать ${row.fullName}`}
              onChange={() => toggleSelected(row.employeeId)}
            />
          ) : null}
          {onOpenEmployeeDetails ? (
            <button
              type="button"
              onClick={() => onOpenEmployeeDetails(row.employeeId)}
              title={row.fullName}
              className="min-w-0 cursor-pointer truncate text-left font-medium transition-colors hover:text-primary hover:underline focus:outline-none"
            >
              {row.fullName}
            </button>
          ) : (
            <span className="min-w-0 truncate font-medium" title={row.fullName}>
              {row.fullName}
            </span>
          )}
          {row.status ? (
            <EmployeeStatusBadge
              status={row.status}
              compact
              className="shrink-0"
            />
          ) : null}
        </div>
      ),
      footer: "Итого",
    },
    {
      key: "hours",
      label: "Часы",
      hint: "Часы за месяц",
      align: "right",
      widthClass: "w-20",
      groupStart: true,
      render: (row) => formatPayrollQuantity(row.hours),
      footer: formatPayrollQuantity(totals.hours),
    },
    {
      key: "rate",
      label: "Ставка",
      hint: "Ставка на сегодня",
      align: "right",
      widthClass: "w-24",
      render: (row) => formatPayrollMoney(row.hourlyRate),
    },
    {
      key: "base",
      label: "База",
      hint: "Часы × ставка на дату смены",
      align: "right",
      widthClass: "w-28",
      render: (row) => formatPayrollMoney(row.baseSalary),
      footer: formatPayrollMoney(totals.base),
    },
    {
      key: "bonus",
      label: "Премии",
      hint: "Премии за месяц",
      align: "right",
      widthClass: "w-24",
      cellClassName: (row) =>
        row.bonusesTotal > 0 ? "font-medium text-success" : "text-muted-foreground/60",
      render: (row) => formatPayrollMoneyOrDash(row.bonusesTotal),
      footer: formatPayrollMoney(totals.bonus),
      footerClassName: "text-success",
    },
    {
      key: "penalty",
      label: "Удержания",
      hint: "Удержания за месяц",
      align: "right",
      widthClass: "w-24",
      cellClassName: (row) =>
        row.penaltiesTotal > 0
          ? "font-medium text-destructive"
          : "text-muted-foreground/60",
      render: (row) => formatPayrollMoneyOrDash(row.penaltiesTotal),
      footer: formatPayrollMoney(totals.penalty),
      footerClassName: "text-destructive",
    },
    {
      key: "trip",
      label: "Суточные",
      hint: "Суточные за месяц",
      align: "right",
      widthClass: "w-24",
      render: (row) => formatPayrollMoney(row.businessTripTotal),
      footer: formatPayrollMoney(totals.trip),
    },
    {
      key: "net",
      label: "К выплате",
      hint: "База + суточные + премии − удержания",
      align: "right",
      widthClass: "w-28",
      groupStart: true,
      cellClassName: "font-semibold",
      render: (row) => formatPayrollMoney(row.netSalary),
      footer: formatPayrollMoney(totals.amount),
    },
    {
      key: "payout",
      label: "Выплаты",
      hint: "Выплаты, зачтённые в этом месяце",
      align: "right",
      widthClass: "w-24",
      groupStart: true,
      cellClassName: (row) =>
        row.payout > 0 ? undefined : "text-muted-foreground/60",
      render: (row) => formatPayrollMoneyOrDash(row.payout),
      footer: formatPayrollMoney(totals.payout),
    },
    {
      key: "remainder",
      label: "Остаток",
      hint: "К выплате − выплаты",
      align: "right",
      widthClass: "w-28",
      cellClassName: (row) =>
        row.remainder < 0 ? "font-medium text-destructive" : undefined,
      render: (row) => formatPayrollMoney(row.remainder),
      footer: formatPayrollMoney(totals.remainder),
      footerClassName: cn(totals.remainder < 0 && "text-destructive"),
    },
    {
      key: "balance",
      label: "Баланс",
      hint: "Накопленный баланс на конец месяца",
      align: "right",
      widthClass: "w-28",
      groupStart: true,
      cellClassName: (row) =>
        row.balance < 0
          ? "font-semibold text-destructive"
          : row.balance > 0
            ? "font-semibold"
            : "text-muted-foreground/60",
      render: (row) => formatPayrollMoney(row.balance),
      footer: formatPayrollMoney(totals.balance),
      footerClassName: cn(totals.balance < 0 && "text-destructive"),
    },
  ];

  /** Долг компании сотруднику: положительный баланс, иначе ноль. */
  function employeeDebt(row: PayrollGridRow): number {
    return row.balance > 0 ? row.balance : 0;
  }

  function openOperation(
    kind: "bonus" | "penalty" | "payout",
    row: PayrollGridRow
  ) {
    const debt = employeeDebt(row);
    const amountSource = row.remainder > 0 ? row.remainder : debt;
    setOperation({
      kind,
      employeeId: row.employeeId,
      fullName: row.fullName,
      defaultAmount:
        kind === "payout" && amountSource > 0 ? String(amountSource) : "",
      debt,
    });
  }

  /** Быстрая выплата: сумма сразу равна долгу сотрудника. */
  function openPayoutRemainder(row: PayrollGridRow) {
    const debt = employeeDebt(row);
    setOperation({
      kind: "payout",
      employeeId: row.employeeId,
      fullName: row.fullName,
      defaultAmount: debt > 0 ? String(debt) : "",
      debt,
    });
  }

  /** Переключает выбор одного сотрудника. */
  function toggleSelected(employeeId: string) {
    setSelectedIds((current) => {
      const next = new Set(current);
      if (next.has(employeeId)) {
        next.delete(employeeId);
      } else {
        next.add(employeeId);
      }
      return next;
    });
  }

  /** Выбирает всех в текущем списке или снимает выбор. */
  function toggleAll() {
    setSelectedIds((current) => {
      const allIds = rows.map((row) => row.employeeId);
      const allSelected =
        allIds.length > 0 && allIds.every((id) => current.has(id));
      return allSelected ? new Set() : new Set(allIds);
    });
  }

  const selectedEmployees = rows
    .filter((row) => selectedIds.has(row.employeeId))
    .map((row) => ({
      id: row.employeeId,
      fullName: row.fullName,
      debt: employeeDebt(row),
    }));

  const defaultObjectId =
    selectedObjectIds.length === 1 ? selectedObjectIds[0] : "";

  const rowMenu = (row: PayrollGridRow) => {
    const debt = employeeDebt(row);
    return (
      <>
        {canCreate ? (
          <>
            <ContextMenuItem onClick={() => openOperation("bonus", row)}>
              <CoinsIcon />
              Начислить премию
            </ContextMenuItem>
            <ContextMenuItem onClick={() => openOperation("penalty", row)}>
              <ReceiptIcon />
              Добавить удержание
            </ContextMenuItem>
            <ContextMenuItem onClick={() => openOperation("payout", row)}>
              <BanknoteIcon />
              Сделать выплату
            </ContextMenuItem>
            {debt > 0 ? (
              <ContextMenuItem onClick={() => openPayoutRemainder(row)}>
                <WalletIcon />
                Выплатить остаток
              </ContextMenuItem>
            ) : null}
          </>
        ) : null}
        <ContextMenuSeparator />
        <ContextMenuItem
          onClick={() =>
            setHistoryEmployee({ id: row.employeeId, fullName: row.fullName })
          }
        >
          <HistoryIcon />
          История операций
        </ContextMenuItem>
        {onOpenEmployeeDetails ? (
          <ContextMenuItem
            onClick={() => onOpenEmployeeDetails(row.employeeId)}
          >
            <UserRoundIcon />
            Открыть карточку сотрудника
          </ContextMenuItem>
        ) : null}
      </>
    );
  };

  return (
    <>
      <PayrollKpiHeader
        isFetching={isFetching}
        items={[
          {
            key: "amount",
            label: "К выплате",
            value: formatPayrollMoney(totals.amount),
            subtext: `Начислено за ${monthLabel.toLowerCase()}`,
            icon: CoinsIcon,
          },
          {
            key: "payout",
            label: "Выплачено",
            value: formatPayrollMoney(totals.payout),
            subtext: "Зачтено в этом месяце",
            icon: BanknoteIcon,
          },
          {
            key: "remainder",
            label: "Остаток",
            value: formatPayrollMoney(totals.remainder),
            subtext: "К выплате минус выплаты",
            icon: WalletIcon,
          },
          {
            key: "balance",
            label: "Баланс",
            value: formatPayrollMoney(totals.balance),
            subtext: balanceSubtext(totals.balance),
            icon: ScaleIcon,
          },
        ]}
      />

      <PayrollFilterBar
        controls={
          <PayrollFilterControls>
            <PayrollPeriodSwitcher
              monthLabel={monthLabel}
              isCurrentMonth={isCurrentMonth}
              onPrevMonth={onPrevMonth}
              onNextMonth={onNextMonth}
              disabled={isLoading}
            />
            <PayrollFilterDropdown
              title="Объекты"
              options={objectOptions}
              selectedKeys={selectedObjectIds}
              onChange={onSelectedObjectIdsChange}
              multiple
              disabled={isLoading || objectOptions.length === 0}
            />
            <PayrollFilterDropdown
              title="Статус"
              options={STATUS_OPTIONS}
              selectedKeys={[status]}
              onChange={(keys) =>
                setStatus((keys[0] ?? "all") as PayrollEmployeeStatusFilter)
              }
              disabled={isLoading}
            />
          </PayrollFilterControls>
        }
        search={
          <PayrollSearchField
            value={search}
            onChange={onSearchChange}
            disabled={isLoading}
          />
        }
        actions={
          <PayrollExportButton
            canExport={canExport}
            isExporting={isExporting}
            disabled={rows.length === 0}
            onExport={handleExport}
          />
        }
      />

      {canCreate && rows.length > 0 ? (
        <div className="flex flex-wrap items-center gap-2 border-b border-border/80 bg-muted/20 px-4 py-2 sm:px-5">
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={toggleAll}
          >
            {selectedIds.size === rows.length ? "Снять выбор" : "Выбрать всех"}
          </Button>
          <span className="text-xs text-muted-foreground">
            Выбрано: {selectedIds.size}
          </span>
          <div className="ml-auto flex flex-wrap items-center gap-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={selectedIds.size === 0}
              onClick={() => setBulkKind("bonus")}
            >
              Премия
            </Button>
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={selectedIds.size === 0}
              onClick={() => setBulkKind("penalty")}
            >
              Удержание
            </Button>
            <Button
              type="button"
              size="sm"
              disabled={selectedIds.size === 0}
              onClick={() => setBulkKind("payout")}
            >
              Выплатить
            </Button>
            {selectedIds.size > 0 ? (
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => setSelectedIds(new Set())}
              >
                Сбросить
              </Button>
            ) : null}
          </div>
        </div>
      ) : null}

      {isError && gridRows.length === 0 ? (
        <PayrollsErrorState
          title="Ошибка загрузки ФОТ"
          message={error?.message}
          onRetry={refetch}
        />
      ) : (
        <PayrollTable
          columns={columns}
          rows={rows}
          rowKey={(row) => row.employeeId}
          stickyFirstColumn
          minWidth={1240}
          sort={sort}
          onSortChange={setSort}
          rowMenu={rowMenu}
          empty={
            <EmptyState
              icon={UsersIcon}
              title="Данных нет"
              description="Измените месяц или фильтры — или введите другой поисковый запрос."
            />
          }
        />
      )}

      {operation && operation.kind !== "payout" ? (
        <PayrollTransactionDialog
          kind={operation.kind}
          employee={{
            id: operation.employeeId,
            fullName: operation.fullName,
          }}
          objectOptions={objectOptions}
          defaultObjectId={defaultObjectId}
          onClose={() => setOperation(null)}
        />
      ) : null}

      {operation?.kind === "payout" ? (
        <PayrollPayoutDialog
          employee={{
            id: operation.employeeId,
            fullName: operation.fullName,
          }}
          defaultAmount={operation.defaultAmount}
          debt={operation.debt}
          onClose={() => setOperation(null)}
        />
      ) : null}

      {historyEmployee ? (
        <PayrollEmployeeHistoryDialog
          employee={historyEmployee}
          year={year}
          month={month}
          onClose={() => setHistoryEmployee(null)}
        />
      ) : null}

      {bulkKind ? (
        <PayrollBulkDialog
          kind={bulkKind}
          employees={selectedEmployees}
          objectOptions={objectOptions}
          defaultObjectId={defaultObjectId}
          onClose={() => {
            setBulkKind(null);
            setSelectedIds(new Set());
          }}
        />
      ) : null}
    </>
  );
}

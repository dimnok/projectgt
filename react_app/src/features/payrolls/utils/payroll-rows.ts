import type { Employee } from "@/features/employees/types/employee.types";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import type {
  PayrollEmployeeStatusFilter,
  PayrollFifoData,
  PayrollGridRow,
  PayrollMonthRow,
  PayrollTableSort,
  PayrollTotals,
} from "@/features/payrolls/types/payroll.types";
import { lastDayOfMonth } from "@/features/payrolls/utils/payroll.utils";

/** Поиск по ФИО: как `filterEmployeesBySearchQuery` в приложении. */
export function filterEmployeesBySearch(
  employees: Employee[],
  query: string
): Employee[] {
  const search = query.trim().toLowerCase();
  if (!search) {
    return employees;
  }
  return employees.filter((employee) =>
    employeeFullName(employee).toLowerCase().includes(search)
  );
}

/** Статус «Работает» — только `working`, остальные статусы не входят. */
export function filterEmployeesByStatus(
  employees: Employee[],
  status: PayrollEmployeeStatusFilter
): Employee[] {
  if (status === "all") {
    return employees;
  }
  if (status === "fired") {
    return employees.filter((employee) => employee.status === "fired");
  }
  return employees.filter((employee) => employee.status === "working");
}

/** Поиск по ФИО среди строк расчёта: строки без сотрудника отбрасываются. */
export function filterRowsByEmployeeName(
  rows: PayrollMonthRow[],
  employeesById: Map<string, Employee>,
  query: string
): PayrollMonthRow[] {
  const search = query.trim().toLowerCase();
  if (!search) {
    return rows;
  }
  return rows.filter((row) => {
    const employee = employeesById.get(row.employeeId);
    if (!employee) {
      return false;
    }
    return employeeFullName(employee).toLowerCase().includes(search);
  });
}

/** Оставляет строки сотрудников, прошедших фильтр статуса. */
export function filterRowsByEmployeeStatus(
  rows: PayrollMonthRow[],
  employees: Employee[],
  status: PayrollEmployeeStatusFilter
): PayrollMonthRow[] {
  if (status === "all") {
    return rows;
  }
  const allowedIds = new Set(employees.map((employee) => employee.id));
  return rows.filter((row) => allowedIds.has(row.employeeId));
}

/**
 * Дополняет строки RPC сотрудниками без начислений за месяц.
 *
 * Как `_groupPayrolls`: только при «Все объекты»; сотрудник устроен не позже
 * конца месяца и либо ещё не уволен, либо имеет баланс (|баланс| > 0.01).
 */
export function mergeZeroActivityRows(
  rows: PayrollMonthRow[],
  employees: Employee[],
  fifo: Map<string, PayrollFifoData>,
  year: number,
  month: number,
  hasObjectFilter: boolean
): PayrollMonthRow[] {
  const grouped = new Map<string, PayrollMonthRow>();
  for (const row of rows) {
    grouped.set(row.employeeId, row);
  }

  if (hasObjectFilter) {
    return [...grouped.values()];
  }

  const endOfMonth = lastDayOfMonth(year, month);

  for (const employee of employees) {
    if (grouped.has(employee.id)) {
      continue;
    }

    const employmentDate = employee.employmentDate;
    if (employmentDate && employmentDate > endOfMonth) {
      continue;
    }

    const balance = fifo.get(employee.id)?.balances.get(month) ?? 0;
    const isWorking = employee.status !== "fired";
    if (!isWorking && Math.abs(balance) <= 0.01) {
      continue;
    }

    grouped.set(employee.id, {
      employeeId: employee.id,
      fullName: employeeFullName(employee),
      totalHours: 0,
      baseSalary: 0,
      businessTripTotal: 0,
      bonusesTotal: 0,
      penaltiesTotal: 0,
      netSalary: 0,
      currentHourlyRate: employee.currentHourlyRate ?? 0,
    });
  }

  return [...grouped.values()];
}

/** Собирает строки таблицы: ФИО, статус, выплаты и баланс выбранного месяца. */
export function buildPayrollGridRows(
  rows: PayrollMonthRow[],
  employeesById: Map<string, Employee>,
  fifo: Map<string, PayrollFifoData>,
  month: number
): PayrollGridRow[] {
  return rows
    .map((row) => {
      const employee = employeesById.get(row.employeeId);
      const employeeFifo = fifo.get(row.employeeId);
      const payout = employeeFifo?.payouts.get(month) ?? 0;
      const balance = employeeFifo?.balances.get(month) ?? 0;

      return {
        employeeId: row.employeeId,
        fullName: employee ? employeeFullName(employee) : row.fullName.trim(),
        status: employee?.status ?? null,
        hours: row.totalHours,
        hourlyRate: row.currentHourlyRate,
        baseSalary: row.baseSalary,
        bonusesTotal: row.bonusesTotal,
        penaltiesTotal: row.penaltiesTotal,
        businessTripTotal: row.businessTripTotal,
        netSalary: row.netSalary,
        payout,
        balance,
        remainder: row.netSalary - payout,
      };
    })
    .sort((a, b) =>
      a.fullName.localeCompare(b.fullName, "ru", { sensitivity: "base" })
    );
}

/** Значение колонки для сортировки. */
const PAYROLL_SORT_VALUES: Record<
  string,
  (row: PayrollGridRow) => number | string
> = {
  employee: (row) => row.fullName,
  hours: (row) => row.hours,
  rate: (row) => row.hourlyRate,
  base: (row) => row.baseSalary,
  bonus: (row) => row.bonusesTotal,
  penalty: (row) => row.penaltiesTotal,
  trip: (row) => row.businessTripTotal,
  net: (row) => row.netSalary,
  payout: (row) => row.payout,
  remainder: (row) => row.remainder,
  balance: (row) => row.balance,
};

/** Сортировка ведомости по выбранной колонке. Без сортировки порядок — по ФИО. */
export function sortPayrollRows(
  rows: PayrollGridRow[],
  sort: PayrollTableSort | null
): PayrollGridRow[] {
  const getValue = sort ? PAYROLL_SORT_VALUES[sort.key] : undefined;
  if (!sort || !getValue) {
    return rows;
  }

  const direction = sort.direction === "asc" ? 1 : -1;

  return [...rows].sort((a, b) => {
    const left = getValue(a);
    const right = getValue(b);

    if (typeof left === "number" && typeof right === "number") {
      if (left !== right) {
        return (left - right) * direction;
      }
    } else {
      const compared = String(left).localeCompare(String(right), "ru", {
        sensitivity: "base",
      });
      if (compared !== 0) {
        return compared * direction;
      }
    }

    return a.fullName.localeCompare(b.fullName, "ru", { sensitivity: "base" });
  });
}

/** ИТОГО по строкам. Баланс — по всему отфильтрованному списку сотрудников. */
export function calculatePayrollTotals(
  rows: PayrollGridRow[],
  employees: Employee[],
  fifo: Map<string, PayrollFifoData>,
  month: number
): PayrollTotals {
  const totals: PayrollTotals = {
    hours: 0,
    base: 0,
    bonus: 0,
    penalty: 0,
    trip: 0,
    amount: 0,
    payout: 0,
    remainder: 0,
    balance: 0,
  };

  for (const row of rows) {
    totals.hours += row.hours;
    totals.base += row.baseSalary;
    totals.bonus += row.bonusesTotal;
    totals.penalty += row.penaltiesTotal;
    totals.trip += row.businessTripTotal;
    totals.amount += row.netSalary;
    totals.payout += row.payout;
    totals.remainder += row.remainder;
  }

  for (const employee of employees) {
    totals.balance += fifo.get(employee.id)?.balances.get(month) ?? 0;
  }

  return totals;
}

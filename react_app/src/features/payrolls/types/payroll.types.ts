import type { EmployeeStatus } from "@/features/employees/utils/employee-status";

/** Период списков: конкретный месяц или вся история. */
export type PayrollPeriod =
  | { mode: "month"; year: number; month: number }
  | { mode: "all" };

/** Вид операции: премия или удержание — одна сущность с разным знаком. */
export type PayrollTransactionKind = "bonus" | "penalty";

/** Сортировка таблицы по колонке. */
export type PayrollTableSort = {
  key: string;
  direction: "asc" | "desc";
};

/** Строка RPC `calculate_payroll_for_month`. */
export type PayrollMonthRow = {
  employeeId: string;
  fullName: string;
  totalHours: number;
  baseSalary: number;
  businessTripTotal: number;
  bonusesTotal: number;
  penaltiesTotal: number;
  netSalary: number;
  currentHourlyRate: number;
};

/** Строка `payroll_payout`, нужная FIFO-распределению. */
export type PayrollPayoutRow = {
  id: string;
  employeeId: string;
  amount: number;
  payoutDate: string;
};

/** FIFO по сотруднику: выплаты и балансы на конец месяца (1–12). */
export type PayrollFifoData = {
  payouts: Map<number, number>;
  balances: Map<number, number>;
};

/** Фильтр списка ФОТ по статусу сотрудника. */
export type PayrollEmployeeStatusFilter = "all" | "working" | "fired";

/** Строка таблицы ФОТ. */
export type PayrollGridRow = {
  employeeId: string;
  fullName: string;
  status: EmployeeStatus | null;
  hours: number;
  hourlyRate: number;
  baseSalary: number;
  bonusesTotal: number;
  penaltiesTotal: number;
  businessTripTotal: number;
  netSalary: number;
  payout: number;
  balance: number;
  remainder: number;
};

/** Строка ИТОГО вкладки ФОТ. */
export type PayrollTotals = {
  hours: number;
  base: number;
  bonus: number;
  penalty: number;
  trip: number;
  amount: number;
  payout: number;
  remainder: number;
  balance: number;
};

/** Строка списка премий или удержаний. */
export type PayrollTransactionItem = {
  id: string;
  date: string;
  employeeId: string;
  objectId: string | null;
  employeeName: string;
  amount: number;
  objectName: string;
  note: string;
  createdByName: string;
  updatedByName: string;
  updatedAt: string;
};

/** Строка списка выплат. */
export type PayrollPayoutItem = {
  id: string;
  date: string;
  employeeId: string;
  employeeName: string;
  amount: number;
  method: string;
  type: string;
  comment: string;
  createdByName: string;
  updatedByName: string;
  updatedAt: string;
};

/** Итоги по сотруднику за всё время — окно «История операций». */
export type PayrollEmployeeTotals = {
  baseTotal: number;
  tripTotal: number;
  bonusTotal: number;
  penaltyTotal: number;
  payoutTotal: number;
  /** Начислено: база + суточные + премии − удержания. */
  earnedTotal: number;
  /** Остаток: начислено − выплачено. */
  balance: number;
};

/** Итоги списка: сумма, количество записей и число сотрудников. */
export type PayrollListTotals = {
  amount: number;
  count: number;
  employees: number;
};

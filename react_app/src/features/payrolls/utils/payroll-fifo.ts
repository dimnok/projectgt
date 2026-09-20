import type {
  PayrollFifoData,
  PayrollPayoutRow,
} from "@/features/payrolls/types/payroll.types";

/**
 * FIFO-распределение выплат по месяцам года.
 *
 * Порт `payoutsByEmployeeAndMonthFIFOProvider` (`payroll_providers.dart`)
 * и `buildFifoForYear` (`supabase/functions/export-payroll`): выплата гасит
 * сначала долг прошлых лет, затем месяцы 1–12 с положительным начислением.
 * Остаток выплаты, если гасить нечего, относится на календарный месяц выплаты.
 */
export function buildFifoForYear(
  year: number,
  accrualsBeforeYear: Map<string, number>,
  allPayouts: PayrollPayoutRow[],
  netByEmployeeMonth: Map<string, Map<number, number>>
): Map<string, PayrollFifoData> {
  const payoutsByEmployee = new Map<string, PayrollPayoutRow[]>();
  for (const payout of [...allPayouts].sort(comparePayouts)) {
    const list = payoutsByEmployee.get(payout.employeeId);
    if (list) {
      list.push(payout);
    } else {
      payoutsByEmployee.set(payout.employeeId, [payout]);
    }
  }

  const employeeIds = new Set<string>([
    ...accrualsBeforeYear.keys(),
    ...payoutsByEmployee.keys(),
    ...netByEmployeeMonth.keys(),
  ]);

  const result = new Map<string, PayrollFifoData>();

  for (const employeeId of employeeIds) {
    const employeePayouts = payoutsByEmployee.get(employeeId) ?? [];
    const employeePayrolls =
      netByEmployeeMonth.get(employeeId) ?? new Map<number, number>();

    let remainingHistoricalDebt = accrualsBeforeYear.get(employeeId) ?? 0;
    const payoutsForMonth = new Map<number, number>();

    for (const payout of employeePayouts) {
      let remainingPayout = payout.amount;

      if (remainingHistoricalDebt > 0) {
        const toApplyToHistory = Math.min(
          remainingPayout,
          remainingHistoricalDebt
        );
        remainingHistoricalDebt -= toApplyToHistory;
        remainingPayout -= toApplyToHistory;
      }

      if (remainingPayout > 0) {
        for (let month = 1; month <= 12 && remainingPayout > 0; month += 1) {
          const accrualForMonth = employeePayrolls.get(month) ?? 0;
          if (accrualForMonth <= 0) {
            continue;
          }

          const alreadyPaidInMonth = payoutsForMonth.get(month) ?? 0;
          const remainingInMonth = accrualForMonth - alreadyPaidInMonth;
          if (remainingInMonth <= 0) {
            continue;
          }

          const toApplyToMonth = Math.min(remainingPayout, remainingInMonth);
          payoutsForMonth.set(month, alreadyPaidInMonth + toApplyToMonth);
          remainingPayout -= toApplyToMonth;
        }
      }

      if (remainingPayout > 0 && payoutYear(payout.payoutDate) === year) {
        const calendarMonth = payoutMonth(payout.payoutDate);
        payoutsForMonth.set(
          calendarMonth,
          (payoutsForMonth.get(calendarMonth) ?? 0) + remainingPayout
        );
      }
    }

    const balances = new Map<number, number>();
    let runningBalance = remainingHistoricalDebt;
    for (let month = 1; month <= 12; month += 1) {
      runningBalance +=
        (employeePayrolls.get(month) ?? 0) - (payoutsForMonth.get(month) ?? 0);
      balances.set(month, runningBalance);
    }

    result.set(employeeId, { payouts: payoutsForMonth, balances });
  }

  return result;
}

function comparePayouts(a: PayrollPayoutRow, b: PayrollPayoutRow): number {
  if (a.payoutDate !== b.payoutDate) {
    return a.payoutDate < b.payoutDate ? -1 : 1;
  }
  if (a.id === b.id) {
    return 0;
  }
  return a.id < b.id ? -1 : 1;
}

function payoutYear(payoutDate: string): number {
  return Number(payoutDate.slice(0, 4));
}

function payoutMonth(payoutDate: string): number {
  return Number(payoutDate.slice(5, 7));
}

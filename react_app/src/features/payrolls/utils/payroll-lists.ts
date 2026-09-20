import type {
  PayrollListTotals,
  PayrollPayoutItem,
  PayrollPeriod,
} from "@/features/payrolls/types/payroll.types";
import { getPeriodPhrase } from "@/features/payrolls/utils/payroll.utils";

type ListRow = {
  employeeId: string;
  employeeName: string;
  date: string;
  amount: number;
};

/** Поиск по ФИО среди строк списка. */
export function filterListRowsByName<T extends ListRow>(
  rows: T[],
  query: string
): T[] {
  const search = query.trim().toLowerCase();
  if (!search) {
    return rows;
  }
  return rows.filter((row) =>
    row.employeeName.toLowerCase().includes(search)
  );
}

/** Сортировка списка: новые записи сверху. */
export function sortListRowsByDateDesc<T extends ListRow>(rows: T[]): T[] {
  return [...rows].sort((a, b) => {
    if (a.date !== b.date) {
      return a.date < b.date ? 1 : -1;
    }
    return 0;
  });
}

/** Итоги списка: сумма, количество записей, число сотрудников. */
export function calculateListTotals<T extends ListRow>(
  rows: T[]
): PayrollListTotals {
  const employeeIds = new Set<string>();
  let amount = 0;
  for (const row of rows) {
    amount += row.amount;
    employeeIds.add(row.employeeId);
  }
  return { amount, count: rows.length, employees: employeeIds.size };
}

/** Сумма выплат указанного типа: `salary` или `advance`. */
export function sumPayoutAmount(
  rows: PayrollPayoutItem[],
  type: string
): number {
  let total = 0;
  for (const row of rows) {
    if (row.type === type) {
      total += row.amount;
    }
  }
  return total;
}

/**
 * Тексты пустого списка. Одна логика на премии, удержания и выплаты:
 * сначала про поиск, потом про выбранный месяц, потом про всю историю.
 *
 * `subject` — слово в трёх формах: «записей» (родительный, мн. ч.),
 * «операции» (именительный, мн. ч.), «записи» (родительный, ед. ч.).
 */
export function buildListEmptyText({
  period,
  periodLabel,
  search,
  subject,
}: {
  period: PayrollPeriod;
  periodLabel: string;
  search: string;
  subject: {
    genitivePlural: string;
    nominativePlural: string;
    genitiveSingular: string;
  };
}): { title: string; description: string } {
  if (search.trim()) {
    return {
      title: "Ничего не найдено",
      description: `По запросу «${search.trim()}» нет ${subject.genitivePlural} ${getPeriodPhrase(period)}.`,
    };
  }

  if (period.mode === "month") {
    return {
      title: `За ${periodLabel.toLowerCase()} ${subject.genitivePlural} нет`,
      description: `Возможно, ${subject.nominativePlural} были в другом месяце.`,
    };
  }

  const first = subject.genitivePlural.charAt(0).toUpperCase();
  return {
    title: `${first}${subject.genitivePlural.slice(1)} нет`,
    description: `Пока нет ни одной ${subject.genitiveSingular}.`,
  };
}

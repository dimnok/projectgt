export const WORK_JOURNAL_TABLE_STORAGE_KEY = "react-work-journal-table-layout";

export type WorkJournalColumnId =
  | "date"
  | "system"
  | "subsystem"
  | "section"
  | "floor"
  | "name"
  | "unit"
  | "quantity"
  | "price"
  | "total";

export type WorkJournalColumnAlign = "left" | "right" | "center";

export type WorkJournalColumn = {
  id: WorkJournalColumnId;
  label: string;
  minWidth: number;
  align: WorkJournalColumnAlign;
  hideable: boolean;
};

export const WORK_JOURNAL_COLUMNS: readonly WorkJournalColumn[] = [
  { id: "date", label: "Дата", minWidth: 88, align: "center", hideable: false },
  { id: "system", label: "Система", minWidth: 72, align: "left", hideable: true },
  {
    id: "subsystem",
    label: "Подсистема",
    minWidth: 88,
    align: "left",
    hideable: true,
  },
  { id: "section", label: "Участок", minWidth: 72, align: "left", hideable: true },
  { id: "floor", label: "Этаж", minWidth: 56, align: "center", hideable: true },
  {
    id: "name",
    label: "Наименование",
    minWidth: 260,
    align: "left",
    hideable: false,
  },
  { id: "unit", label: "Ед.", minWidth: 48, align: "center", hideable: true },
  { id: "quantity", label: "Кол-во", minWidth: 64, align: "right", hideable: true },
  { id: "price", label: "Цена", minWidth: 80, align: "right", hideable: true },
  { id: "total", label: "Сумма", minWidth: 88, align: "right", hideable: true },
];

export function isWorkJournalColumnId(
  value: string
): value is WorkJournalColumnId {
  return WORK_JOURNAL_COLUMNS.some((column) => column.id === value);
}

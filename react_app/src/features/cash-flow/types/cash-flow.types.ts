/** Тип операции ДДС: приход или расход. */
export type CashFlowType = "income" | "expense";

/** Статья ДДС (справочник движения денежных средств). */
export type CashFlowCategory = {
  id: string;
  name: string;
  /** Тип операций, для которых статья доступна. */
  type: CashFlowType;
};

/** Операция ДДС. */
export type CashFlowTransaction = {
  id: string;
  /** Дата платежа, `ГГГГ-ММ-ДД`. */
  date: string;
  type: CashFlowType;
  amount: number;
  categoryId: string | null;
  /** Название статьи; пусто, если статья не указана. */
  categoryName: string;
  objectId: string | null;
  objectName: string;
  contractId: string | null;
  contractNumber: string;
  contractorId: string | null;
  /** Контрагент: название из справочника, для импортированных — текст из выписки. */
  contractorName: string;
  contractorInn: string;
  comment: string;
  operationHash: string | null;
};

/** Черновик операции из формы. */
export type CashFlowDraft = {
  type: CashFlowType;
  date: string;
  /** Сумма, как её ввёл пользователь. */
  amount: string;
  categoryId: string;
  objectId: string;
  contractorId: string;
  contractId: string;
  comment: string;
};

/**
 * Фильтры реестра: поиск, период и срезы.
 *
 * Пустое значение значит «без фильтра», пустой массив — «все».
 */
export type CashFlowFilters = {
  search: string;
  /** Год периода: он же задаёт границы выборки и аналитики. */
  year: number;
  objectId: string;
  contractorId: string;
  contractIds: string[];
  types: CashFlowType[];
};

/** Итоги реестра за период. */
export type CashFlowSummary = {
  count: number;
  income: number;
  expense: number;
  /** Сальдо: приход минус расход. */
  balance: number;
};

/** Аналитика за месяц. */
export type CashFlowMonthAnalytics = {
  /** Первое число месяца, `ГГГГ-ММ-ДД`. */
  month: string;
  income: number;
  expense: number;
  balance: number;
  /** Разбивка прихода по статьям; ключ — название статьи. */
  incomeByCategory: Record<string, number>;
  expenseByCategory: Record<string, number>;
};

/** Пара «идентификатор — подпись» для выпадающих списков. */
export type CashFlowPickItem = {
  id: string;
  label: string;
};

/** Идентификаторы справочников, по которым есть операции за период. */
export type CashFlowAvailableFilters = {
  objectIds: string[];
  contractorIds: string[];
  contractIds: string[];
};

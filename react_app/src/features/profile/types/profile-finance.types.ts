export type ProfileFinanceMoneyRow = {
  date: string;
  amount: number;
  note: string;
};

export type ProfileFinanceHourRow = {
  date: string;
  hours: number;
};

export type ProfileFinanceUnlinked = {
  linked: false;
};

export type ProfileFinanceLinked = {
  linked: true;
  employeeId: string;
  year: number;
  month: number;
  hours: number;
  baseSalary: number;
  businessTripTotal: number;
  bonusesTotal: number;
  penaltiesTotal: number;
  netSalary: number;
  balance: number;
  bonuses: ProfileFinanceMoneyRow[];
  penalties: ProfileFinanceMoneyRow[];
  payouts: ProfileFinanceMoneyRow[];
  hoursByDate: ProfileFinanceHourRow[];
};

export type ProfileFinance = ProfileFinanceUnlinked | ProfileFinanceLinked;

export type ProfileFinancePeriod = {
  year: number;
  month: number;
};

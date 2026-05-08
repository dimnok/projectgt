-- Индексы для ускорения частых фильтров по (company_id, date)
-- Таблицы маленькие (<400 строк), блокировка при CREATE INDEX миллисекундная.

CREATE INDEX IF NOT EXISTS idx_payroll_bonus_company_date
  ON public.payroll_bonus (company_id, date);

CREATE INDEX IF NOT EXISTS idx_payroll_penalty_company_date
  ON public.payroll_penalty (company_id, date);

CREATE INDEX IF NOT EXISTS idx_payroll_payout_company_date
  ON public.payroll_payout (company_id, payout_date);

CREATE INDEX IF NOT EXISTS idx_employee_rates_employee_company_from
  ON public.employee_rates (employee_id, company_id, valid_from DESC);

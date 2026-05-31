-- Табель: мягкое исключение сотрудника из списка (без часов за период не показывать).
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS include_in_timesheet BOOLEAN NOT NULL DEFAULT true;

COMMENT ON COLUMN public.employees.include_in_timesheet IS
  'Учитывать в табеле. false: скрывать в сетке/Excel, если за период нет записей часов.';

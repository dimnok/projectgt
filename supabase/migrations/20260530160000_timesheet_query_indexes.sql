-- Индексы для запросов модуля «Табель» (work_hours + works, employee_attendance).

BEGIN;

CREATE INDEX IF NOT EXISTS idx_work_hours_company_id
  ON public.work_hours (company_id);

CREATE INDEX IF NOT EXISTS idx_employee_attendance_company_date
  ON public.employee_attendance (company_id, date);

CREATE INDEX IF NOT EXISTS idx_works_company_status_date
  ON public.works (company_id, status, date);

COMMIT;

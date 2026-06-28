-- Табель: чтение открытых смен за сегодня (состав смены) по timesheet.read
-- для контроля выхода сотрудников без доступа к модулю «Смены».

BEGIN;

DROP POLICY IF EXISTS "timesheet_read_open_works_today_select" ON public.works;

CREATE POLICY "timesheet_read_open_works_today_select"
ON public.works FOR SELECT
TO authenticated
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND status = 'open'
  AND date = CURRENT_DATE
  AND public.check_permission(auth.uid(), 'timesheet', 'read')
);

COMMENT ON POLICY "timesheet_read_open_works_today_select" ON public.works IS
  'Табель: просмотр открытых смен только за текущий календарный день (сервер).';

COMMIT;

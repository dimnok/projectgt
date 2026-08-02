-- Уведомления ТМЦ: пользователь видит и обновляет только свои.
DROP POLICY IF EXISTS "tmc_select_tmc_notifications" ON public.tmc_notifications;
CREATE POLICY "tmc_select_tmc_notifications"
ON public.tmc_notifications FOR SELECT
TO authenticated
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND user_id = auth.uid()
);

DROP POLICY IF EXISTS "tmc_update_tmc_notifications" ON public.tmc_notifications;
CREATE POLICY "tmc_update_tmc_notifications"
ON public.tmc_notifications FOR UPDATE
TO authenticated
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND user_id = auth.uid()
)
WITH CHECK (
  company_id IN (SELECT public.get_my_company_ids())
  AND user_id = auth.uid()
);

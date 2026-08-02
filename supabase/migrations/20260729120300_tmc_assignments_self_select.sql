-- Сотрудник видит свои выдачи ТМЦ в профиле без права tmc.read.
DROP POLICY IF EXISTS "tmc_select_own_assignments" ON public.tmc_assignments;
CREATE POLICY "tmc_select_own_assignments"
ON public.tmc_assignments FOR SELECT
TO authenticated
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND employee_id IN (
    SELECT (p.object->>'employee_id')::uuid
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.object ? 'employee_id'
      AND NULLIF(p.object->>'employee_id', '') IS NOT NULL
  )
);

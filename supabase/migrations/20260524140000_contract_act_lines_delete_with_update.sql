-- Удаление строк акта КС-2 — тем же правом, что правка объёмов (update), не delete всего акта.

BEGIN;

DROP POLICY IF EXISTS "Strict DELETE for contract_act_lines" ON public.contract_act_lines;
CREATE POLICY "Strict DELETE for contract_act_lines"
ON public.contract_act_lines FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'update')
);

COMMIT;

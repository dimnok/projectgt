-- Разделение RBAC: «Контрагенты» (contractors) и «Подрядчики» (subcontractors).
-- Ранее оба сценария использовали module_code = contractors.

BEGIN;

INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('subcontractors', 'Подрядчики', 'wrench', 83, true)
ON CONFLICT (code) DO UPDATE
SET
  name = EXCLUDED.name,
  icon_key = EXCLUDED.icon_key,
  sort_order = EXCLUDED.sort_order,
  is_active = true;

UPDATE public.app_modules
SET name = 'Контрагенты', is_active = true
WHERE code = 'contractors';

INSERT INTO public.role_permissions (role_id, company_id, module_code, permission_code, is_enabled)
SELECT s.role_id, s.company_id, 'subcontractors'::text, s.permission_code, s.is_enabled
FROM public.role_permissions s
WHERE s.module_code = 'contractors'
  AND NOT EXISTS (
    SELECT 1
    FROM public.role_permissions e
    WHERE e.role_id = s.role_id
      AND e.module_code = 'subcontractors'
      AND e.permission_code = s.permission_code
      AND (e.company_id IS NOT DISTINCT FROM s.company_id)
  );

DROP POLICY IF EXISTS "contractors_select estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_select estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR SELECT
    TO authenticated
    USING (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'subcontractors', 'read')
    );

DROP POLICY IF EXISTS "contractors_insert estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_insert estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR INSERT
    TO authenticated
    WITH CHECK (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'subcontractors', 'create')
        AND EXISTS (
            SELECT 1
            FROM public.estimates e
            WHERE e.id = estimate_id
              AND e.company_id = company_id
        )
        AND EXISTS (
            SELECT 1
            FROM public.contractors c
            WHERE c.id = contractor_id
              AND c.company_id = company_id
        )
    );

DROP POLICY IF EXISTS "contractors_update estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_update estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR UPDATE
    TO authenticated
    USING (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'subcontractors', 'update')
    )
    WITH CHECK (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'subcontractors', 'update')
        AND EXISTS (
            SELECT 1
            FROM public.estimates e
            WHERE e.id = estimate_id
              AND e.company_id = company_id
        )
        AND EXISTS (
            SELECT 1
            FROM public.contractors c
            WHERE c.id = contractor_id
              AND c.company_id = company_id
        )
    );

DROP POLICY IF EXISTS "contractors_delete estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_delete estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR DELETE
    TO authenticated
    USING (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'subcontractors', 'delete')
    );

COMMIT;

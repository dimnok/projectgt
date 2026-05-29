-- Убрать политики, обходящие RBAC (участник компании ≠ право на изменение).
-- Суточные в карточке сотрудника — только при employees.update.

BEGIN;

DROP POLICY IF EXISTS "Users can manage employees of their companies" ON public.employees;
DROP POLICY IF EXISTS "Users can view employees of their companies" ON public.employees;
DROP POLICY IF EXISTS "Only admins can create employees" ON public.employees;
DROP POLICY IF EXISTS "Only admins can update employees" ON public.employees;
DROP POLICY IF EXISTS "Only admins can delete employees" ON public.employees;
DROP POLICY IF EXISTS "Users can view employees" ON public.employees;

DROP POLICY IF EXISTS "Users can manage employee rates of their companies" ON public.employee_rates;

DROP POLICY IF EXISTS "Users can view business trip rates" ON public.business_trip_rates;
DROP POLICY IF EXISTS "Users can insert business trip rates" ON public.business_trip_rates;
DROP POLICY IF EXISTS "Users can update business trip rates" ON public.business_trip_rates;
DROP POLICY IF EXISTS "Users can delete business trip rates" ON public.business_trip_rates;
DROP POLICY IF EXISTS "Users can manage trip rates of their companies" ON public.business_trip_rates;
DROP POLICY IF EXISTS "Users can view trip rates of their companies" ON public.business_trip_rates;

DROP POLICY IF EXISTS "business_trip_rates_select" ON public.business_trip_rates;
CREATE POLICY "business_trip_rates_select"
ON public.business_trip_rates FOR SELECT
TO public
USING (
  company_id IN (SELECT get_my_company_ids())
  AND (
    check_permission(uid(), 'employees', 'read')
    OR check_permission(uid(), 'payroll', 'read')
  )
);

DROP POLICY IF EXISTS "business_trip_rates_insert" ON public.business_trip_rates;
CREATE POLICY "business_trip_rates_insert"
ON public.business_trip_rates FOR INSERT
TO public
WITH CHECK (
  company_id IN (SELECT get_my_company_ids())
  AND check_permission(uid(), 'employees', 'update')
);

DROP POLICY IF EXISTS "business_trip_rates_update" ON public.business_trip_rates;
CREATE POLICY "business_trip_rates_update"
ON public.business_trip_rates FOR UPDATE
TO public
USING (
  company_id IN (SELECT get_my_company_ids())
  AND check_permission(uid(), 'employees', 'update')
)
WITH CHECK (
  company_id IN (SELECT get_my_company_ids())
  AND check_permission(uid(), 'employees', 'update')
);

DROP POLICY IF EXISTS "business_trip_rates_delete" ON public.business_trip_rates;
CREATE POLICY "business_trip_rates_delete"
ON public.business_trip_rates FOR DELETE
TO public
USING (
  company_id IN (SELECT get_my_company_ids())
  AND check_permission(uid(), 'employees', 'update')
);

COMMIT;

-- Catalog and extra lines for the Works module without estimates.* on the role.
-- Estimates screen / RPC get_estimate_groups still require estimates.read.
-- UPDATE/DELETE of estimates stay estimates.update / estimates.delete.

CREATE OR REPLACE FUNCTION public.can_use_works_estimate_catalog()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT COALESCE(
    public.check_permission((SELECT auth.uid()), 'works', 'read')
    OR public.check_permission((SELECT auth.uid()), 'works', 'create')
    OR public.check_permission((SELECT auth.uid()), 'works', 'update'),
    false
  );
$$;

CREATE OR REPLACE FUNCTION public.can_add_work_estimate_line()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT COALESCE(
    public.check_permission((SELECT auth.uid()), 'works', 'create')
    OR public.check_permission((SELECT auth.uid()), 'works', 'update'),
    false
  );
$$;

COMMENT ON FUNCTION public.can_use_works_estimate_catalog() IS
  'Picklist сметы в смене: works.read / create / update.';

COMMENT ON FUNCTION public.can_add_work_estimate_line() IS
  'Строка «Новый материал» из смены: works.create / update.';

GRANT EXECUTE ON FUNCTION public.can_use_works_estimate_catalog() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_add_work_estimate_line() TO authenticated;

DROP POLICY IF EXISTS "Strict SELECT for estimates" ON public.estimates;

CREATE POLICY "Strict SELECT for estimates"
ON public.estimates
FOR SELECT
TO authenticated
USING (
  estimates.company_id IN (SELECT public.get_my_company_ids())
  AND (
    public.check_permission((SELECT auth.uid()), 'estimates', 'read')
    OR (SELECT public.can_use_works_estimate_catalog())
  )
  AND (
    EXISTS (
      SELECT 1
      FROM public.company_members cm
      WHERE cm.user_id = (SELECT auth.uid())
        AND cm.company_id = estimates.company_id
        AND cm.is_owner = true
    )
    OR (
      estimates.object_id IS NOT NULL
      AND estimates.object_id IN (
        SELECT unnest(p.object_ids)
        FROM public.profiles p
        WHERE p.id = (SELECT auth.uid())
      )
    )
  )
);

DROP POLICY IF EXISTS "Strict INSERT for estimates" ON public.estimates;

CREATE POLICY "Strict INSERT for estimates"
ON public.estimates
FOR INSERT
TO authenticated
WITH CHECK (
  estimates.company_id IN (SELECT public.get_my_company_ids())
  AND (
    public.check_permission((SELECT auth.uid()), 'estimates', 'create')
    OR (
      (SELECT public.can_add_work_estimate_line())
      AND estimates.object_id IS NOT NULL
      AND (
        EXISTS (
          SELECT 1
          FROM public.company_members cm
          WHERE cm.user_id = (SELECT auth.uid())
            AND cm.company_id = estimates.company_id
            AND cm.is_owner = true
        )
        OR estimates.object_id IN (
          SELECT unnest(p.object_ids)
          FROM public.profiles p
          WHERE p.id = (SELECT auth.uid())
        )
      )
    )
  )
);

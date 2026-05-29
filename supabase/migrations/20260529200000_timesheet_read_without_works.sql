-- Табель: чтение закрытых смен и справочника объектов по timesheet.read
-- без works.read и без profiles.object_ids.
-- Аналог picklist объектов для «Сотрудники»
-- (см. 20260529190000_employees_objects_picklist_rls.sql).

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Закрытые смены — SELECT для табеля (не открывает CRUD модуля «Работы»)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "timesheet_read_closed_works_select" ON public.works;

CREATE POLICY "timesheet_read_closed_works_select"
ON public.works FOR SELECT
TO authenticated
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND status = 'closed'
  AND public.check_permission(uid(), 'timesheet', 'read')
);

-- ---------------------------------------------------------------------------
-- 2. Справочник объектов — picklist фильтра табеля без objects.read
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "objects_select" ON public.objects;

CREATE POLICY "objects_select"
ON public.objects FOR SELECT
TO public
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND (
    public.check_permission(uid(), 'objects', 'read')
    OR id IN (
      SELECT unnest(p.object_ids)
      FROM public.profiles p
      WHERE p.id = uid()
    )
    OR public.check_permission(uid(), 'employees', 'read')
    OR public.check_permission(uid(), 'employees', 'create')
    OR public.check_permission(uid(), 'employees', 'update')
    OR public.check_permission(uid(), 'timesheet', 'read')
  )
);

COMMIT;

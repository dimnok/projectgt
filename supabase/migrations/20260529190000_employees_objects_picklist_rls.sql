-- Picklist объектов для модуля «Сотрудники» без права objects.read.
-- Экран «Объекты» и CRUD по-прежнему требуют objects.*.

BEGIN;

DROP POLICY IF EXISTS "objects_select" ON public.objects;

CREATE POLICY "objects_select"
ON public.objects FOR SELECT
TO public
USING (
  company_id IN (SELECT get_my_company_ids())
  AND (
    check_permission(uid(), 'objects', 'read')
    OR id IN (
      SELECT unnest(p.object_ids)
      FROM public.profiles p
      WHERE p.id = uid()
    )
    OR check_permission(uid(), 'employees', 'read')
    OR check_permission(uid(), 'employees', 'create')
    OR check_permission(uid(), 'employees', 'update')
  )
);

COMMIT;

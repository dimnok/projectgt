-- Разрешить удаление черновика ВОР создателю без права estimates.delete.
-- Владелец компании по-прежнему проходит через check_permission (is_owner = true).

BEGIN;

DROP POLICY IF EXISTS "Strict DELETE for vors" ON public.vors;
CREATE POLICY "Strict DELETE for vors"
ON public.vors FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND status = 'draft'
    AND (
        public.check_permission(auth.uid(), 'estimates', 'delete')
        OR created_by = auth.uid()
    )
);

DROP POLICY IF EXISTS "Strict DELETE for vor_items" ON public.vor_items;
CREATE POLICY "Strict DELETE for vor_items"
ON public.vor_items FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1
        FROM public.vors v
        WHERE v.id = vor_items.vor_id
          AND v.status = 'draft'
          AND (
              public.check_permission(auth.uid(), 'estimates', 'delete')
              OR v.created_by = auth.uid()
          )
    )
);

DROP POLICY IF EXISTS "Strict DELETE for vor_systems" ON public.vor_systems;
CREATE POLICY "Strict DELETE for vor_systems"
ON public.vor_systems FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1
        FROM public.vors v
        WHERE v.id = vor_systems.vor_id
          AND v.status = 'draft'
          AND (
              public.check_permission(auth.uid(), 'estimates', 'delete')
              OR v.created_by = auth.uid()
          )
    )
);

DROP POLICY IF EXISTS "Strict DELETE for vor_status_history" ON public.vor_status_history;
CREATE POLICY "Strict DELETE for vor_status_history"
ON public.vor_status_history FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1
        FROM public.vors v
        WHERE v.id = vor_status_history.vor_id
          AND v.status = 'draft'
          AND (
              public.check_permission(auth.uid(), 'estimates', 'delete')
              OR v.created_by = auth.uid()
          )
    )
);

COMMIT;

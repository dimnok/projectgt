-- Удаление доп. соглашения (addendum): шапка может быть `approved` до переноса в `estimates`.
-- Расширяем DELETE для `estimate_revisions` и `estimate_revision_items`, чтобы CASCADE
-- при удалении шапки не упирался в RLS (раньше разрешалось только при `status = 'draft'`).

BEGIN;

DROP POLICY IF EXISTS "Strict DELETE for estimate_revisions" ON public.estimate_revisions;

CREATE POLICY "Strict DELETE for estimate_revisions"
ON public.estimate_revisions FOR DELETE
TO authenticated
USING (
    estimate_revisions.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'delete')
    AND (
      (
        estimate_revisions.status = 'draft'
      )
      OR (
        estimate_revisions.revision_type = 'addendum'
        AND estimate_revisions.status = 'approved'
        AND estimate_revisions.applied_to_estimates_at IS NULL
      )
    )
    AND (
      EXISTS (
        SELECT 1
        FROM public.company_members cm
        WHERE cm.user_id = auth.uid()
          AND cm.company_id = estimate_revisions.company_id
          AND cm.is_owner = true
      )
      OR EXISTS (
        SELECT 1
        FROM public.contracts c
        JOIN public.profiles p ON p.id = auth.uid()
        WHERE c.id = estimate_revisions.contract_id
          AND c.object_id IS NOT NULL
          AND c.object_id = ANY(COALESCE(p.object_ids, '{}'::UUID[]))
      )
    )
);

DROP POLICY IF EXISTS "Strict DELETE for estimate_revision_items" ON public.estimate_revision_items;

CREATE POLICY "Strict DELETE for estimate_revision_items"
ON public.estimate_revision_items FOR DELETE
TO authenticated
USING (
    estimate_revision_items.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'delete')
    AND EXISTS (
      SELECT 1
      FROM public.estimate_revisions er
      WHERE er.id = estimate_revision_items.revision_id
        AND er.company_id = estimate_revision_items.company_id
        AND (
          er.status = 'draft'
          OR (
            er.revision_type = 'addendum'
            AND er.status = 'approved'
            AND er.applied_to_estimates_at IS NULL
          )
        )
    )
);

COMMIT;

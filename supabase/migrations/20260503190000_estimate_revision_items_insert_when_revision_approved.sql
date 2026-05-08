-- Импорт LC/ДС: шапка ревизии создаётся со статусом `approved`, строки вставляются сразу после.
-- Прежняя policy разрешала INSERT только при `estimate_revisions.status = 'draft'`, из‑за чего
-- PostgREST возвращал 42501 (RLS) на шаге сохранения.

BEGIN;

DROP POLICY IF EXISTS "Strict INSERT for estimate_revision_items" ON public.estimate_revision_items;

CREATE POLICY "Strict INSERT for estimate_revision_items"
ON public.estimate_revision_items FOR INSERT
TO authenticated
WITH CHECK (
    estimate_revision_items.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'create')
    AND EXISTS (
      SELECT 1
      FROM public.estimate_revisions er
      WHERE er.id = estimate_revision_items.revision_id
        AND er.company_id = estimate_revision_items.company_id
        AND (
          er.status = 'draft'
          OR (
            er.status = 'approved'
            AND er.revision_type = 'addendum'
            AND er.applied_to_estimates_at IS NULL
          )
        )
    )
);

COMMIT;

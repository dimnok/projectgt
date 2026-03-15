-- ===================================================================
-- Миграция: удаление рекурсивной policy у estimate_revision_items
-- ===================================================================
-- Дата: 08.03.2026
-- Описание:
--   Убирает policy с self-reference, которая вызывала
--   `infinite recursion detected in policy for relation estimate_revision_items`.
--   Вставка строк разрешена только для draft-ревизий.
-- ===================================================================

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
        AND er.status = 'draft'
    )
);

COMMIT;

-- ===================================================================
-- Миграция: hotfix policy для дозаполнения базовой ревизии сметы
-- ===================================================================
-- Дата: 08.03.2026
-- Описание:
--   Горячая правка policy для вставки строк ревизии сметы.
--   Финальный вариант оставляет вставку только для `draft`-ревизий.
--   Базовая ревизия `Основная` теперь наполняется строками до перевода в `approved`
--   на уровне application-логики, без recursion в RLS.
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

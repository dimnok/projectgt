-- Журнал ручных правок сметной позиции (форма «Редактирование», не Excel).

CREATE TABLE IF NOT EXISTS public.estimate_item_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  estimate_id UUID NOT NULL REFERENCES public.estimates(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL CHECK (action IN ('updated')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.estimate_item_history IS
  'Ручные изменения позиции сметы из формы. Импорт Excel и RPC bulk update сюда не пишутся.';

CREATE INDEX IF NOT EXISTS idx_estimate_item_history_estimate
  ON public.estimate_item_history (estimate_id, created_at);

ALTER TABLE public.estimate_item_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Strict SELECT for estimate_item_history"
ON public.estimate_item_history FOR SELECT
TO authenticated
USING (
  company_id IN (SELECT public.get_my_company_ids())
  AND public.check_permission((SELECT auth.uid()), 'estimates', 'read')
  AND EXISTS (
    SELECT 1
    FROM public.estimates e
    WHERE e.id = estimate_item_history.estimate_id
      AND e.company_id = estimate_item_history.company_id
      AND (
        EXISTS (
          SELECT 1
          FROM public.company_members cm
          WHERE cm.user_id = (SELECT auth.uid())
            AND cm.company_id = e.company_id
            AND cm.is_owner = true
        )
        OR (
          e.object_id IS NOT NULL
          AND e.object_id = ANY (
            SELECT unnest(object_ids)
            FROM public.profiles
            WHERE id = (SELECT auth.uid())
          )
        )
      )
  )
);

CREATE POLICY "Strict INSERT for estimate_item_history"
ON public.estimate_item_history FOR INSERT
TO authenticated
WITH CHECK (
  company_id IN (SELECT public.get_my_company_ids())
  AND user_id = (SELECT auth.uid())
  AND public.check_permission((SELECT auth.uid()), 'estimates', 'update')
  AND EXISTS (
    SELECT 1
    FROM public.estimates e
    WHERE e.id = estimate_item_history.estimate_id
      AND e.company_id = estimate_item_history.company_id
      AND (
        EXISTS (
          SELECT 1
          FROM public.company_members cm
          WHERE cm.user_id = (SELECT auth.uid())
            AND cm.company_id = e.company_id
            AND cm.is_owner = true
        )
        OR (
          e.object_id IS NOT NULL
          AND e.object_id = ANY (
            SELECT unnest(object_ids)
            FROM public.profiles
            WHERE id = (SELECT auth.uid())
          )
        )
      )
  )
);

GRANT SELECT, INSERT ON public.estimate_item_history TO authenticated;
REVOKE UPDATE, DELETE ON public.estimate_item_history FROM authenticated;

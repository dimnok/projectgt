-- ===================================================================
-- Миграция: Версии смет и черновой поток LC / ДС
-- ===================================================================
-- Дата: 08.03.2026
-- Описание:
--   1. Добавляет безопасные таблицы версий сметы, не ломая текущий поток `estimates`
--   2. Добавляет `position_id` для сквозной идентификации позиции сметы
--   3. Добавляет `baseline_revision_id` в `vors` для будущей привязки ВОР к версии
--   4. Старый импорт сметы, текущие ВОР и факт работ продолжают работать как раньше
-- ===================================================================

BEGIN;

-- -------------------------------------------------------------------
-- 1. Совместимые доработки существующих таблиц
-- -------------------------------------------------------------------

ALTER TABLE public.estimates
ADD COLUMN IF NOT EXISTS position_id UUID;

UPDATE public.estimates
SET position_id = gen_random_uuid()
WHERE position_id IS NULL;

ALTER TABLE public.estimates
ALTER COLUMN position_id SET DEFAULT gen_random_uuid();

ALTER TABLE public.estimates
ALTER COLUMN position_id SET NOT NULL;

ALTER TABLE public.vors
ADD COLUMN IF NOT EXISTS baseline_revision_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS uq_estimates_company_contract_position
ON public.estimates(company_id, contract_id, position_id);

CREATE INDEX IF NOT EXISTS idx_vors_baseline_revision_id
ON public.vors(baseline_revision_id);

-- -------------------------------------------------------------------
-- 2. Таблица версий сметы (шапка)
-- -------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.estimate_revisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    contract_id UUID NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    estimate_title TEXT NOT NULL,
    revision_no INTEGER NOT NULL CHECK (revision_no >= 0),
    revision_label TEXT NOT NULL,
    revision_type TEXT NOT NULL CHECK (revision_type IN ('original', 'addendum')),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'archived')),
    based_on_revision_id UUID REFERENCES public.estimate_revisions(id) ON DELETE SET NULL,
    source_file_path TEXT,
    effective_from DATE,
    approved_at TIMESTAMPTZ,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_estimate_revisions_contract_title_revision
      UNIQUE (contract_id, estimate_title, revision_no)
);

-- -------------------------------------------------------------------
-- 3. Таблица строк версии сметы
-- -------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.estimate_revision_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    revision_id UUID NOT NULL REFERENCES public.estimate_revisions(id) ON DELETE CASCADE,
    position_id UUID NOT NULL,
    source_estimate_id UUID REFERENCES public.estimates(id) ON DELETE SET NULL,
    row_no INTEGER NOT NULL DEFAULT 0,
    system TEXT NOT NULL DEFAULT '',
    subsystem TEXT NOT NULL DEFAULT '',
    number TEXT NOT NULL DEFAULT '',
    name TEXT NOT NULL DEFAULT '',
    article TEXT NOT NULL DEFAULT '',
    manufacturer TEXT NOT NULL DEFAULT '',
    unit TEXT NOT NULL DEFAULT '',
    quantity DOUBLE PRECISION NOT NULL DEFAULT 0,
    price DOUBLE PRECISION NOT NULL DEFAULT 0,
    total DOUBLE PRECISION NOT NULL DEFAULT 0,
    change_type TEXT NOT NULL DEFAULT 'unchanged'
      CHECK (change_type IN ('unchanged', 'qty_changed', 'price_changed', 'added', 'removed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_estimate_revisions_company_contract
ON public.estimate_revisions(company_id, contract_id);

CREATE INDEX IF NOT EXISTS idx_estimate_revisions_contract_title_status
ON public.estimate_revisions(contract_id, estimate_title, status);

CREATE INDEX IF NOT EXISTS idx_estimate_revision_items_revision
ON public.estimate_revision_items(revision_id);

CREATE INDEX IF NOT EXISTS idx_estimate_revision_items_position
ON public.estimate_revision_items(position_id);

-- -------------------------------------------------------------------
-- 4. Внешний ключ в `vors` после создания таблицы ревизий
-- -------------------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'vors_baseline_revision_id_fkey'
  ) THEN
    ALTER TABLE public.vors
    ADD CONSTRAINT vors_baseline_revision_id_fkey
    FOREIGN KEY (baseline_revision_id)
    REFERENCES public.estimate_revisions(id)
    ON DELETE SET NULL;
  END IF;
END $$;

-- -------------------------------------------------------------------
-- 5. Триггер updated_at для ревизий
-- -------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_estimate_revisions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_estimate_revisions_updated_at ON public.estimate_revisions;
CREATE TRIGGER tr_estimate_revisions_updated_at
    BEFORE UPDATE ON public.estimate_revisions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_estimate_revisions_updated_at();

-- -------------------------------------------------------------------
-- 6. RLS
-- -------------------------------------------------------------------

ALTER TABLE public.estimate_revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimate_revision_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Strict SELECT for estimate_revisions" ON public.estimate_revisions;
CREATE POLICY "Strict SELECT for estimate_revisions"
ON public.estimate_revisions FOR SELECT
TO authenticated
USING (
    estimate_revisions.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
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

DROP POLICY IF EXISTS "Strict INSERT for estimate_revisions" ON public.estimate_revisions;
CREATE POLICY "Strict INSERT for estimate_revisions"
ON public.estimate_revisions FOR INSERT
TO authenticated
WITH CHECK (
    estimate_revisions.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'create')
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

DROP POLICY IF EXISTS "Strict UPDATE for estimate_revisions" ON public.estimate_revisions;
CREATE POLICY "Strict UPDATE for estimate_revisions"
ON public.estimate_revisions FOR UPDATE
TO authenticated
USING (
    estimate_revisions.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
    AND status = 'draft'
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
)
WITH CHECK (
    estimate_revisions.company_id IN (SELECT public.get_my_company_ids())
    AND status IN ('draft', 'approved', 'archived')
);

DROP POLICY IF EXISTS "Strict DELETE for estimate_revisions" ON public.estimate_revisions;
CREATE POLICY "Strict DELETE for estimate_revisions"
ON public.estimate_revisions FOR DELETE
TO authenticated
USING (
    estimate_revisions.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'delete')
    AND status = 'draft'
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

DROP POLICY IF EXISTS "Strict SELECT for estimate_revision_items" ON public.estimate_revision_items;
CREATE POLICY "Strict SELECT for estimate_revision_items"
ON public.estimate_revision_items FOR SELECT
TO authenticated
USING (
    estimate_revision_items.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
    AND EXISTS (
      SELECT 1
      FROM public.estimate_revisions er
      WHERE er.id = estimate_revision_items.revision_id
    )
);

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
        AND er.status = 'draft'
        AND er.company_id = estimate_revision_items.company_id
    )
);

DROP POLICY IF EXISTS "Strict UPDATE for estimate_revision_items" ON public.estimate_revision_items;
CREATE POLICY "Strict UPDATE for estimate_revision_items"
ON public.estimate_revision_items FOR UPDATE
TO authenticated
USING (
    estimate_revision_items.company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
    AND EXISTS (
      SELECT 1
      FROM public.estimate_revisions er
      WHERE er.id = estimate_revision_items.revision_id
        AND er.status = 'draft'
        AND er.company_id = estimate_revision_items.company_id
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
        AND er.status = 'draft'
        AND er.company_id = estimate_revision_items.company_id
    )
);

COMMIT;

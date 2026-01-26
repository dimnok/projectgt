-- ===================================================================
-- Миграция: Структура данных для Журнала КС-6а (v2 - Strict Multi-tenancy)
-- ===================================================================
-- Дата: 25.01.2026
-- ===================================================================

BEGIN;

-- 1. Тип статуса периода
DO $$ BEGIN
    CREATE TYPE public.ks6a_status AS ENUM ('draft', 'approved');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Таблица заголовков периодов
CREATE TABLE IF NOT EXISTS public.ks6a_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    contract_id UUID NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status public.ks6a_status NOT NULL DEFAULT 'draft',
    title TEXT,
    total_amount DOUBLE PRECISION DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    
    CONSTRAINT date_range_check CHECK (end_date >= start_date)
);

-- 3. Таблица строк периода (ДОБАВЛЕН company_id)
CREATE TABLE IF NOT EXISTS public.ks6a_period_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    period_id UUID NOT NULL REFERENCES public.ks6a_periods(id) ON DELETE CASCADE,
    estimate_id UUID NOT NULL REFERENCES public.estimates(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL DEFAULT 0,
    price_snapshot DOUBLE PRECISION NOT NULL DEFAULT 0,
    amount DOUBLE PRECISION GENERATED ALWAYS AS (quantity * price_snapshot) STORED,
    
    UNIQUE(period_id, estimate_id)
);

-- 4. Включение RLS
ALTER TABLE public.ks6a_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ks6a_period_items ENABLE ROW LEVEL SECURITY;

-- 5. Индексы
CREATE INDEX IF NOT EXISTS idx_ks6a_periods_contract ON public.ks6a_periods(contract_id);
CREATE INDEX IF NOT EXISTS idx_ks6a_periods_company ON public.ks6a_periods(company_id);
CREATE INDEX IF NOT EXISTS idx_ks6a_period_items_period ON public.ks6a_period_items(period_id);
CREATE INDEX IF NOT EXISTS idx_ks6a_period_items_company ON public.ks6a_period_items(company_id);

-- 6. RLS Политики для ks6a_periods
DROP POLICY IF EXISTS "Strict SELECT for ks6a_periods" ON public.ks6a_periods;
CREATE POLICY "Strict SELECT for ks6a_periods"
ON public.ks6a_periods FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for ks6a_periods" ON public.ks6a_periods;
CREATE POLICY "Strict INSERT for ks6a_periods"
ON public.ks6a_periods FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'create')
);

DROP POLICY IF EXISTS "Strict UPDATE for ks6a_periods" ON public.ks6a_periods;
CREATE POLICY "Strict UPDATE for ks6a_periods"
ON public.ks6a_periods FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
    AND status = 'draft'
);

DROP POLICY IF EXISTS "Strict DELETE for ks6a_periods" ON public.ks6a_periods;
CREATE POLICY "Strict DELETE for ks6a_periods"
ON public.ks6a_periods FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'delete')
    AND status = 'draft'
);

-- 7. RLS Политики для ks6a_period_items (ОБНОВЛЕНО на прямой company_id)
DROP POLICY IF EXISTS "Strict SELECT for ks6a_period_items" ON public.ks6a_period_items;
CREATE POLICY "Strict SELECT for ks6a_period_items"
ON public.ks6a_period_items FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for ks6a_period_items" ON public.ks6a_period_items;
CREATE POLICY "Strict INSERT for ks6a_period_items"
ON public.ks6a_period_items FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'create')
    AND EXISTS (SELECT 1 FROM public.ks6a_periods p WHERE p.id = period_id AND p.status = 'draft')
);

DROP POLICY IF EXISTS "Strict UPDATE for ks6a_period_items" ON public.ks6a_period_items;
CREATE POLICY "Strict UPDATE for ks6a_period_items"
ON public.ks6a_period_items FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
    AND EXISTS (SELECT 1 FROM public.ks6a_periods p WHERE p.id = period_id AND p.status = 'draft')
);

DROP POLICY IF EXISTS "Strict DELETE for ks6a_period_items" ON public.ks6a_period_items;
CREATE POLICY "Strict DELETE for ks6a_period_items"
ON public.ks6a_period_items FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'delete')
    AND EXISTS (SELECT 1 FROM public.ks6a_periods p WHERE p.id = period_id AND p.status = 'draft')
);

COMMIT;

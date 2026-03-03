-- ===================================================================
-- Миграция: Структура данных для Ведомостей Объемов Работ (ВОР)
-- ===================================================================
-- Дата: 31.01.2026
-- Описание: Создание таблиц для ВОР с поддержкой мультиарендности (company_id),
--           статусной модели и RLS политик.
-- ===================================================================

BEGIN;

-- 1. Тип статуса ВОР
DO $$ BEGIN
    CREATE TYPE public.vor_status AS ENUM ('draft', 'pending', 'approved');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Таблица заголовков ВОР
CREATE TABLE IF NOT EXISTS public.vors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    contract_id UUID NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    number TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status public.vor_status NOT NULL DEFAULT 'draft',
    excel_url TEXT,
    pdf_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES public.profiles(id),
    
    CONSTRAINT date_range_check CHECK (end_date >= start_date)
);

-- 3. Таблица позиций ВОР
CREATE TABLE IF NOT EXISTS public.vor_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vor_id UUID NOT NULL REFERENCES public.vors(id) ON DELETE CASCADE,
    estimate_item_id UUID REFERENCES public.estimates(id) ON DELETE SET NULL,
    name TEXT,
    unit TEXT,
    quantity DOUBLE PRECISION NOT NULL DEFAULT 0,
    is_extra BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Либо привязка к смете, либо ручное название
    CONSTRAINT name_or_estimate_check CHECK (estimate_item_id IS NOT NULL OR name IS NOT NULL)
);

-- 4. Таблица выбранных систем для ВОР (храним как текст, так как нет отдельного справочника)
CREATE TABLE IF NOT EXISTS public.vor_systems (
    vor_id UUID NOT NULL REFERENCES public.vors(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    system_name TEXT NOT NULL,
    PRIMARY KEY (vor_id, system_name)
);

-- 5. Таблица истории статусов
CREATE TABLE IF NOT EXISTS public.vor_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    vor_id UUID NOT NULL REFERENCES public.vors(id) ON DELETE CASCADE,
    status public.vor_status NOT NULL,
    user_id UUID REFERENCES public.profiles(id),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Включение RLS
ALTER TABLE public.vors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vor_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vor_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vor_status_history ENABLE ROW LEVEL SECURITY;

-- 7. Индексы для производительности
CREATE INDEX IF NOT EXISTS idx_vors_contract ON public.vors(contract_id);
CREATE INDEX IF NOT EXISTS idx_vors_company ON public.vors(company_id);
CREATE INDEX IF NOT EXISTS idx_vor_items_vor ON public.vor_items(vor_id);
CREATE INDEX IF NOT EXISTS idx_vor_items_company ON public.vor_items(company_id);
CREATE INDEX IF NOT EXISTS idx_vor_status_history_vor ON public.vor_status_history(vor_id);

-- 8. RLS Политики для vors
DROP POLICY IF EXISTS "Strict SELECT for vors" ON public.vors;
CREATE POLICY "Strict SELECT for vors"
ON public.vors FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for vors" ON public.vors;
CREATE POLICY "Strict INSERT for vors"
ON public.vors FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'create')
);

DROP POLICY IF EXISTS "Strict UPDATE for vors" ON public.vors;
CREATE POLICY "Strict UPDATE for vors"
ON public.vors FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
    AND status IN ('draft', 'pending')
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND status IN ('draft', 'pending', 'approved')
);

DROP POLICY IF EXISTS "Strict DELETE for vors" ON public.vors;
CREATE POLICY "Strict DELETE for vors"
ON public.vors FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'delete')
    AND status = 'draft'
);

-- 9. RLS Политики для vor_items
DROP POLICY IF EXISTS "Strict SELECT for vor_items" ON public.vor_items;
CREATE POLICY "Strict SELECT for vor_items"
ON public.vor_items FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for vor_items" ON public.vor_items;
CREATE POLICY "Strict INSERT for vor_items"
ON public.vor_items FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'create')
    AND EXISTS (SELECT 1 FROM public.vors v WHERE v.id = vor_id AND v.status = 'draft')
);

DROP POLICY IF EXISTS "Strict UPDATE for vor_items" ON public.vor_items;
CREATE POLICY "Strict UPDATE for vor_items"
ON public.vor_items FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'update')
    AND EXISTS (SELECT 1 FROM public.vors v WHERE v.id = vor_id AND v.status = 'draft')
);

DROP POLICY IF EXISTS "Strict DELETE for vor_items" ON public.vor_items;
CREATE POLICY "Strict DELETE for vor_items"
ON public.vor_items FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'estimates', 'delete')
    AND EXISTS (SELECT 1 FROM public.vors v WHERE v.id = vor_id AND v.status = 'draft')
);

-- 10. RLS Политики для vor_systems
DROP POLICY IF EXISTS "Strict SELECT for vor_systems" ON public.vor_systems;
CREATE POLICY "Strict SELECT for vor_systems"
ON public.vor_systems FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
);

DROP POLICY IF EXISTS "Strict INSERT for vor_systems" ON public.vor_systems;
CREATE POLICY "Strict INSERT for vor_systems"
ON public.vor_systems FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
);

-- 11. RLS Политики для vor_status_history
DROP POLICY IF EXISTS "Strict SELECT for vor_status_history" ON public.vor_status_history;
CREATE POLICY "Strict SELECT for vor_status_history"
ON public.vor_status_history FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
);

DROP POLICY IF EXISTS "Strict INSERT for vor_status_history" ON public.vor_status_history;
CREATE POLICY "Strict INSERT for vor_status_history"
ON public.vor_status_history FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
);

-- 12. Триггер для обновления updated_at
CREATE OR REPLACE FUNCTION public.handle_vors_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_vors_updated_at ON public.vors;
CREATE TRIGGER tr_vors_updated_at
    BEFORE UPDATE ON public.vors
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_vors_updated_at();

-- 13. Функция для автоматической нумерации ВОР
CREATE OR REPLACE FUNCTION public.get_next_vor_number(p_company_id UUID, p_contract_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_max_number INTEGER;
    v_next_number TEXT;
BEGIN
    -- Находим максимальный номер среди существующих ВОР для данного договора
    SELECT MAX(NULLIF(regexp_replace(number, '\D', '', 'g'), '')::INTEGER)
    INTO v_max_number
    FROM public.vors
    WHERE company_id = p_company_id 
      AND contract_id = p_contract_id;

    IF v_max_number IS NULL THEN
        v_max_number := 0;
    END IF;

    v_next_number := 'ВОР-' || LPAD((v_max_number + 1)::TEXT, 3, '0');

    RETURN v_next_number;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;

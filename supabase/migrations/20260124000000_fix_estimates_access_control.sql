-- ===================================================================
-- Миграция: Исправление контроля доступа к сметам (v3 - финальная с материалами)
-- ===================================================================
-- Дата: 24.01.2026
-- 
-- ПРОБЛЕМА:
-- 1. Пользователи без назначенных объектов в профиле видели все сметы
-- 2. В таблице выполнения пропали данные "Материал получено" и "Материал остаток"
--
-- РЕШЕНИЕ:
-- 1. Исправлены RLS политики: строгая фильтрация по object_id
-- 2. Обновлены RPC функции: явная проверка is_owner и object_ids
-- 3. Добавлен LEFT JOIN с v_materials_grouped_by_estimate для расчета материалов
-- 4. Сметы "Без объекта" видны только Владельцу компании
-- ===================================================================

BEGIN;

-- ===================================================================
-- 1. Исправление RLS для таблицы estimates
-- ===================================================================

-- Удаляем старые политики
DROP POLICY IF EXISTS "Allow delete for users with access to contract or object" ON public.estimates;
DROP POLICY IF EXISTS "Allow select for users with access to contract or object" ON public.estimates;
DROP POLICY IF EXISTS "Allow update for users with access to contract or object" ON public.estimates;
DROP POLICY IF EXISTS "Users can view data of their companies" ON public.estimates;
DROP POLICY IF EXISTS "Users can manage data of their companies" ON public.estimates;
DROP POLICY IF EXISTS "Strict SELECT for estimates" ON public.estimates;
DROP POLICY IF EXISTS "Strict INSERT for estimates" ON public.estimates;
DROP POLICY IF EXISTS "Strict UPDATE for estimates" ON public.estimates;
DROP POLICY IF EXISTS "Strict DELETE for estimates" ON public.estimates;

-- А) Политика на ЧТЕНИЕ (SELECT)
CREATE POLICY "Strict SELECT for estimates"
ON public.estimates FOR SELECT
TO authenticated
USING (
  estimates.company_id IN (SELECT public.get_my_company_ids())
  AND (
    public.check_permission(auth.uid(), 'estimates', 'read')
    AND (
      EXISTS (SELECT 1 FROM public.company_members cm WHERE cm.user_id = auth.uid() AND cm.company_id = estimates.company_id AND cm.is_owner = true)
      OR (estimates.object_id IS NOT NULL AND estimates.object_id = ANY(SELECT unnest(object_ids) FROM public.profiles WHERE id = auth.uid()))
    )
  )
);

-- Б) Политика на ВСТАВКУ (INSERT)
CREATE POLICY "Strict INSERT for estimates"
ON public.estimates FOR INSERT
TO authenticated
WITH CHECK (
  estimates.company_id IN (SELECT public.get_my_company_ids())
  AND public.check_permission(auth.uid(), 'estimates', 'create')
);

-- В) Политика на ОБНОВЛЕНИЕ (UPDATE)
CREATE POLICY "Strict UPDATE for estimates"
ON public.estimates FOR UPDATE
TO authenticated
USING (
  estimates.company_id IN (SELECT public.get_my_company_ids())
  AND public.check_permission(auth.uid(), 'estimates', 'update')
  AND (
    EXISTS (SELECT 1 FROM public.company_members cm WHERE cm.user_id = auth.uid() AND cm.company_id = estimates.company_id AND cm.is_owner = true)
    OR (estimates.object_id IS NOT NULL AND estimates.object_id = ANY(SELECT unnest(object_ids) FROM public.profiles WHERE id = auth.uid()))
  )
);

-- Г) Политика на УДАЛЕНИЕ (DELETE)
CREATE POLICY "Strict DELETE for estimates"
ON public.estimates FOR DELETE
TO authenticated
USING (
  estimates.company_id IN (SELECT public.get_my_company_ids())
  AND public.check_permission(auth.uid(), 'estimates', 'delete')
  AND (
    EXISTS (SELECT 1 FROM public.company_members cm WHERE cm.user_id = auth.uid() AND cm.company_id = estimates.company_id AND cm.is_owner = true)
    OR (estimates.object_id IS NOT NULL AND estimates.object_id = ANY(SELECT unnest(object_ids) FROM public.profiles WHERE id = auth.uid()))
  )
);

-- ===================================================================
-- 2. Обновление RPC функций
-- ===================================================================

-- 2.1. get_estimate_groups (Sidebar)
DROP FUNCTION IF EXISTS public.get_estimate_groups(UUID);

CREATE OR REPLACE FUNCTION public.get_estimate_groups(p_company_id UUID)
RETURNS TABLE (
  estimate_title TEXT,
  object_id UUID,
  contract_id UUID,
  contract_number TEXT,
  items_count BIGINT,
  total_amount DOUBLE PRECISION
) AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  IF NOT public.check_permission(v_user_id, 'estimates', 'read') THEN
    RETURN;
  END IF;

  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT 
    COALESCE(e.estimate_title, 'Без названия')::TEXT as estimate_title,
    e.object_id,
    e.contract_id,
    c.number::TEXT as contract_number,
    COUNT(*)::BIGINT as items_count,
    COALESCE(SUM(e.total), 0)::DOUBLE PRECISION as total_amount
  FROM public.estimates e
  LEFT JOIN public.contracts c ON e.contract_id = c.id
  WHERE e.company_id = p_company_id
    AND (
      v_is_owner = true 
      OR (e.object_id IS NOT NULL AND e.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
  GROUP BY e.estimate_title, e.object_id, e.contract_id, c.number
  ORDER BY e.estimate_title;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2.2. get_estimate_completion_paginated (Отчеты)
DROP FUNCTION IF EXISTS public.get_estimate_completion_paginated(UUID, INT, INT, UUID[], UUID[], TEXT[], TEXT[], TEXT);
DROP FUNCTION IF EXISTS public.get_estimate_completion_paginated(UUID, INT, INT, UUID[], UUID[], TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.get_estimate_completion_paginated(
  p_company_id UUID,
  p_offset INT DEFAULT 0,
  p_limit INT DEFAULT 50,
  p_object_ids UUID[] DEFAULT NULL,
  p_contract_ids UUID[] DEFAULT NULL,
  p_search TEXT DEFAULT NULL,
  p_system TEXT DEFAULT NULL,
  p_subsystem TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
  v_total_count INT;
  v_data JSONB;
  v_has_next BOOLEAN;
BEGIN
  IF NOT public.check_permission(v_user_id, 'estimates', 'read') THEN
    RETURN JSONB_BUILD_OBJECT('data', '[]'::JSONB, 'total_count', 0, 'has_next', false);
  END IF;

  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  SELECT COUNT(*) INTO v_total_count
  FROM public.estimates e
  WHERE e.company_id = p_company_id
    AND (v_is_owner = true OR (e.object_id IS NOT NULL AND e.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[]))))
    AND (p_object_ids IS NULL OR e.object_id = ANY(p_object_ids))
    AND (p_contract_ids IS NULL OR e.contract_id = ANY(p_contract_ids))
    AND (p_search IS NULL OR e.name ILIKE '%' || p_search || '%')
    AND (p_system IS NULL OR e.system = p_system)
    AND (p_subsystem IS NULL OR e.subsystem = p_subsystem);

  v_has_next := (p_offset + p_limit) < v_total_count;

  SELECT COALESCE(JSONB_AGG(row_to_json(t.*) ORDER BY t.system, t.subsystem, t.number), '[]'::JSONB)
  INTO v_data
  FROM (
    SELECT
      e.id AS estimate_id,
      e.object_id,
      e.contract_id,
      e.system,
      e.subsystem,
      COALESCE(e.number::TEXT, '') AS number,
      COALESCE(e.name, '') AS name,
      COALESCE(e.unit, '') AS unit,
      COALESCE(e.quantity, 0.0) AS quantity,
      COALESCE(e.total, 0.0) AS total,
      COALESCE(SUM(wi.quantity), 0.0) AS completed_quantity,
      COALESCE(SUM(wi.total), 0.0) AS completed_total,
      CASE 
        WHEN COALESCE(e.quantity, 0) = 0 THEN 0
        ELSE ROUND((COALESCE(SUM(wi.quantity), 0.0) / COALESCE(e.quantity, 1)) * 100)
      END AS percentage,
      COALESCE(e.quantity, 0) - COALESCE(SUM(wi.quantity), 0.0) AS remaining_quantity,
      COALESCE(m.total_incoming, 0.0) AS material_received,
      COALESCE(m.total_remaining, 0.0) AS material_remaining
    FROM public.estimates e
    LEFT JOIN public.work_items wi ON e.id = wi.estimate_id
    LEFT JOIN public.v_materials_grouped_by_estimate m ON e.id = m.estimate_id
    WHERE e.company_id = p_company_id
      AND (v_is_owner = true OR (e.object_id IS NOT NULL AND e.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[]))))
      AND (p_object_ids IS NULL OR e.object_id = ANY(p_object_ids))
      AND (p_contract_ids IS NULL OR e.contract_id = ANY(p_contract_ids))
      AND (p_search IS NULL OR e.name ILIKE '%' || p_search || '%')
      AND (p_system IS NULL OR e.system = p_system)
      AND (p_subsystem IS NULL OR e.subsystem = p_subsystem)
    GROUP BY e.id, e.object_id, e.contract_id, e.system, e.subsystem, e.number, e.name, e.unit, e.quantity, e.total, m.total_incoming, m.total_remaining
    ORDER BY e.system, e.subsystem, e.number
    LIMIT p_limit OFFSET p_offset
  ) t;

  RETURN JSONB_BUILD_OBJECT(
    'data', COALESCE(v_data, '[]'::jsonb),
    'total_count', v_total_count,
    'has_next', v_has_next
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2.3. get_estimate_completion_by_ids
DROP FUNCTION IF EXISTS public.get_estimate_completion_by_ids(UUID, UUID[]);
DROP FUNCTION IF EXISTS public.get_estimate_completion_by_ids(UUID[], UUID);

CREATE OR REPLACE FUNCTION public.get_estimate_completion_by_ids(
  p_company_id UUID,
  p_estimate_ids UUID[]
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
  v_data JSONB;
BEGIN
  IF NOT public.check_permission(v_user_id, 'estimates', 'read') THEN
    RETURN '[]'::JSONB;
  END IF;

  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  SELECT JSONB_AGG(t.*)
  INTO v_data
  FROM (
    SELECT
      e.id AS estimate_id,
      e.object_id,
      e.contract_id,
      e.system,
      e.subsystem,
      COALESCE(e.number::TEXT, '') AS number,
      COALESCE(e.name, '') AS name,
      COALESCE(e.unit, '') AS unit,
      COALESCE(e.quantity, 0.0) AS quantity,
      COALESCE(e.total, 0.0) AS total,
      COALESCE(SUM(wi.quantity), 0.0) AS completed_quantity,
      COALESCE(SUM(wi.total), 0.0) AS completed_total,
      CASE 
        WHEN COALESCE(e.quantity, 0) = 0 THEN 0
        ELSE (COALESCE(SUM(wi.quantity), 0.0) / COALESCE(e.quantity, 1)) * 100
      END AS percentage,
      COALESCE(e.quantity, 0) - COALESCE(SUM(wi.quantity), 0.0) AS remaining_quantity,
      COALESCE(m.total_incoming, 0.0) AS material_received,
      COALESCE(m.total_remaining, 0.0) AS material_remaining
    FROM public.estimates e
    LEFT JOIN public.work_items wi ON e.id = wi.estimate_id
    LEFT JOIN public.v_materials_grouped_by_estimate m ON e.id = m.estimate_id
    WHERE e.company_id = p_company_id
      AND e.id = ANY(p_estimate_ids)
      AND (
        v_is_owner = true 
        OR (e.object_id IS NOT NULL AND e.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
      )
    GROUP BY e.id, e.object_id, e.contract_id, e.system, e.subsystem, e.number, e.name, e.unit, e.quantity, e.total, m.total_incoming, m.total_remaining
  ) t;

  RETURN COALESCE(v_data, '[]'::JSONB);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2.4. get_estimate_completion_report (Legacy fallback)
DROP FUNCTION IF EXISTS public.get_estimate_completion_report();

CREATE OR REPLACE FUNCTION public.get_estimate_completion_report()
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_company_id UUID;
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
  v_data JSONB;
BEGIN
  SELECT last_company_id INTO v_company_id FROM public.profiles WHERE id = v_user_id;
  
  IF v_company_id IS NULL OR NOT public.check_permission(v_user_id, 'estimates', 'read') THEN
    RETURN '[]'::JSONB;
  END IF;

  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = v_company_id
  WHERE p.id = v_user_id;

  SELECT JSONB_AGG(t.*)
  INTO v_data
  FROM (
    SELECT
      e.id AS estimate_id,
      e.object_id,
      e.contract_id,
      e.system,
      e.subsystem,
      COALESCE(e.number::TEXT, '') AS number,
      COALESCE(e.name, '') AS name,
      COALESCE(e.unit, '') AS unit,
      COALESCE(e.quantity, 0.0) AS quantity,
      COALESCE(e.total, 0.0) AS total,
      COALESCE(SUM(wi.quantity), 0.0) AS completed_quantity,
      COALESCE(SUM(wi.total), 0.0) AS completed_total,
      CASE 
        WHEN COALESCE(e.quantity, 0) = 0 THEN 0
        ELSE (COALESCE(SUM(wi.quantity), 0.0) / COALESCE(e.quantity, 1)) * 100
      END AS percentage,
      COALESCE(e.quantity, 0) - COALESCE(SUM(wi.quantity), 0.0) AS remaining_quantity,
      COALESCE(m.total_incoming, 0.0) AS material_received,
      COALESCE(m.total_remaining, 0.0) AS material_remaining
    FROM public.estimates e
    LEFT JOIN public.work_items wi ON e.id = wi.estimate_id
    LEFT JOIN public.v_materials_grouped_by_estimate m ON e.id = m.estimate_id
    WHERE e.company_id = v_company_id
      AND (v_is_owner = true OR (e.object_id IS NOT NULL AND e.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[]))))
    GROUP BY e.id, e.object_id, e.contract_id, e.system, e.subsystem, e.number, e.name, e.unit, e.quantity, e.total, m.total_incoming, m.total_remaining
  ) t;

  RETURN COALESCE(v_data, '[]'::JSONB);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;
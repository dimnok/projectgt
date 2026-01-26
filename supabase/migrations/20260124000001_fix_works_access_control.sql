-- ===================================================================
-- Миграция: Исправление контроля доступа к сменам (Works) v2
-- ===================================================================
-- Дата: 24.01.2026
-- 
-- ПРОБЛЕМА:
-- 1. Пользователи видели все смены компании из-за конфликтующих permissive политик.
-- 2. RPC функции суммарной статистики не учитывали ограничения по объектам.
--
-- РЕШЕНИЕ:
-- 1. Внедрение Strict политик по аналогии с модулем Estimates.
-- 2. Сохранение бизнес-логики редактирования только открытых смен через check_work_editable.
-- 3. Обновление RPC функций с явной фильтрацией по object_ids пользователя.
-- ===================================================================

BEGIN;

-- ===================================================================
-- 1. Исправление RLS для таблицы works
-- ===================================================================

-- Удаляем все старые политики для таблицы works
DROP POLICY IF EXISTS "Users can view works" ON public.works;
DROP POLICY IF EXISTS "Users can insert works" ON public.works;
DROP POLICY IF EXISTS "Users can update their works" ON public.works;
DROP POLICY IF EXISTS "Users can delete their works" ON public.works;
DROP POLICY IF EXISTS "Allow access to own objects works" ON public.works;
DROP POLICY IF EXISTS "Allow delete for own objects" ON public.works;
DROP POLICY IF EXISTS "Allow insert for own objects" ON public.works;
DROP POLICY IF EXISTS "Allow update for own objects" ON public.works;
DROP POLICY IF EXISTS "Users can view works of their companies" ON public.works;
DROP POLICY IF EXISTS "Users can manage works of their companies" ON public.works;
DROP POLICY IF EXISTS "works_select" ON public.works;
DROP POLICY IF EXISTS "works_insert" ON public.works;
DROP POLICY IF EXISTS "works_update" ON public.works;
DROP POLICY IF EXISTS "works_delete" ON public.works;
DROP POLICY IF EXISTS "Strict SELECT for works" ON public.works;
DROP POLICY IF EXISTS "Strict INSERT for works" ON public.works;
DROP POLICY IF EXISTS "Strict UPDATE for works" ON public.works;
DROP POLICY IF EXISTS "Strict DELETE for works" ON public.works;

-- А) Политика на ЧТЕНИЕ (SELECT)
CREATE POLICY "Strict SELECT for works"
ON public.works FOR SELECT
TO authenticated
USING (
  works.company_id IN (SELECT public.get_my_company_ids())
  AND (
    public.check_permission(auth.uid(), 'works', 'read')
    AND (
      EXISTS (SELECT 1 FROM public.company_members cm WHERE cm.user_id = auth.uid() AND cm.company_id = works.company_id AND cm.is_owner = true)
      OR (works.object_id IS NOT NULL AND works.object_id = ANY(SELECT unnest(object_ids) FROM public.profiles WHERE id = auth.uid()))
    )
  )
);

-- Б) Политика на ВСТАВКУ (INSERT)
CREATE POLICY "Strict INSERT for works"
ON public.works FOR INSERT
TO authenticated
WITH CHECK (
  works.company_id IN (SELECT public.get_my_company_ids())
  AND public.check_permission(auth.uid(), 'works', 'create')
  AND (
    EXISTS (SELECT 1 FROM public.company_members cm WHERE cm.user_id = auth.uid() AND cm.company_id = works.company_id AND cm.is_owner = true)
    OR (works.object_id IS NOT NULL AND works.object_id = ANY(SELECT unnest(object_ids) FROM public.profiles WHERE id = auth.uid()))
  )
);

-- В) Политика на ОБНОВЛЕНИЕ (UPDATE)
CREATE POLICY "Strict UPDATE for works"
ON public.works FOR UPDATE
TO authenticated
USING (
  works.company_id IN (SELECT public.get_my_company_ids())
  AND public.check_permission(auth.uid(), 'works', 'update')
  AND public.check_work_editable(id, auth.uid())
  AND (
    EXISTS (SELECT 1 FROM public.company_members cm WHERE cm.user_id = auth.uid() AND cm.company_id = works.company_id AND cm.is_owner = true)
    OR (works.object_id IS NOT NULL AND works.object_id = ANY(SELECT unnest(object_ids) FROM public.profiles WHERE id = auth.uid()))
  )
);

-- Г) Политика на УДАЛЕНИЕ (DELETE)
CREATE POLICY "Strict DELETE for works"
ON public.works FOR DELETE
TO authenticated
USING (
  works.company_id IN (SELECT public.get_my_company_ids())
  AND public.check_permission(auth.uid(), 'works', 'delete')
  AND public.check_work_editable(id, auth.uid())
  AND (
    EXISTS (SELECT 1 FROM public.company_members cm WHERE cm.user_id = auth.uid() AND cm.company_id = works.company_id AND cm.is_owner = true)
    OR (works.object_id IS NOT NULL AND works.object_id = ANY(SELECT unnest(object_ids) FROM public.profiles WHERE id = auth.uid()))
  )
);

-- ===================================================================
-- 2. Исправление RLS для дочерних таблиц
-- ===================================================================

-- Функция для проверки доступа к родительской смене (для оптимизации политик)
CREATE OR REPLACE FUNCTION public.check_work_access(p_work_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.works w
    WHERE w.id = p_work_id
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY INVOKER;

-- 2.1. work_hours
ALTER TABLE public.work_hours ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow access to shift_hours via shifts" ON public.work_hours;
DROP POLICY IF EXISTS "Allow access to work_hours via works" ON public.work_hours;
DROP POLICY IF EXISTS "Allow delete for shift_hours via shifts" ON public.work_hours;
DROP POLICY IF EXISTS "Allow delete for work_hours via works" ON public.work_hours;
DROP POLICY IF EXISTS "Allow insert for shift_hours via shifts" ON public.work_hours;
DROP POLICY IF EXISTS "Allow insert for work_hours via works" ON public.work_hours;
DROP POLICY IF EXISTS "Allow update for shift_hours via shifts" ON public.work_hours;
DROP POLICY IF EXISTS "Allow update for work_hours via works" ON public.work_hours;
DROP POLICY IF EXISTS "Users can view work_hours" ON public.work_hours;
DROP POLICY IF EXISTS "Users can insert work_hours" ON public.work_hours;
DROP POLICY IF EXISTS "Users can update their work_hours" ON public.work_hours;
DROP POLICY IF EXISTS "Users can delete their work_hours" ON public.work_hours;
DROP POLICY IF EXISTS "Strict SELECT for work_hours" ON public.work_hours;
DROP POLICY IF EXISTS "Strict INSERT for work_hours" ON public.work_hours;
DROP POLICY IF EXISTS "Strict UPDATE for work_hours" ON public.work_hours;
DROP POLICY IF EXISTS "Strict DELETE for work_hours" ON public.work_hours;

CREATE POLICY "Strict SELECT for work_hours" ON public.work_hours FOR SELECT TO authenticated USING (public.check_work_access(work_id));
CREATE POLICY "Strict INSERT for work_hours" ON public.work_hours FOR INSERT TO authenticated WITH CHECK (public.check_work_access(work_id));
CREATE POLICY "Strict UPDATE for work_hours" ON public.work_hours FOR UPDATE TO authenticated USING (public.check_work_access(work_id));
CREATE POLICY "Strict DELETE for work_hours" ON public.work_hours FOR DELETE TO authenticated USING (public.check_work_access(work_id));

-- 2.2. work_items
ALTER TABLE public.work_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow access to work_items via works" ON public.work_items;
DROP POLICY IF EXISTS "Allow delete for work_items via works" ON public.work_items;
DROP POLICY IF EXISTS "Allow insert for work_items via works" ON public.work_items;
DROP POLICY IF EXISTS "Allow update for work_items via works" ON public.work_items;
DROP POLICY IF EXISTS "Users can view work_items" ON public.work_items;
DROP POLICY IF EXISTS "Users can insert work_items" ON public.work_items;
DROP POLICY IF EXISTS "Users can update their work_items" ON public.work_items;
DROP POLICY IF EXISTS "Users can delete their work_items" ON public.work_items;
DROP POLICY IF EXISTS "Strict SELECT for work_items" ON public.work_items;
DROP POLICY IF EXISTS "Strict INSERT for work_items" ON public.work_items;
DROP POLICY IF EXISTS "Strict UPDATE for work_items" ON public.work_items;
DROP POLICY IF EXISTS "Strict DELETE for work_items" ON public.work_items;

CREATE POLICY "Strict SELECT for work_items" ON public.work_items FOR SELECT TO authenticated USING (public.check_work_access(work_id));
CREATE POLICY "Strict INSERT for work_items" ON public.work_items FOR INSERT TO authenticated WITH CHECK (public.check_work_access(work_id));
CREATE POLICY "Strict UPDATE for work_items" ON public.work_items FOR UPDATE TO authenticated USING (public.check_work_access(work_id));
CREATE POLICY "Strict DELETE for work_items" ON public.work_items FOR DELETE TO authenticated USING (public.check_work_access(work_id));

-- 2.3. work_materials
ALTER TABLE public.work_materials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow access to work_materials via works" ON public.work_materials;
DROP POLICY IF EXISTS "Allow delete for work_materials via works" ON public.work_materials;
DROP POLICY IF EXISTS "Allow insert for work_materials via works" ON public.work_materials;
DROP POLICY IF EXISTS "Allow update for work_materials via works" ON public.work_materials;
DROP POLICY IF EXISTS "Users can view work_materials" ON public.work_materials;
DROP POLICY IF EXISTS "Users can insert work_materials" ON public.work_materials;
DROP POLICY IF EXISTS "Users can update their work_materials" ON public.work_materials;
DROP POLICY IF EXISTS "Users can delete their work_materials" ON public.work_materials;
DROP POLICY IF EXISTS "Strict SELECT for work_materials" ON public.work_materials;
DROP POLICY IF EXISTS "Strict INSERT for work_materials" ON public.work_materials;
DROP POLICY IF EXISTS "Strict UPDATE for work_materials" ON public.work_materials;
DROP POLICY IF EXISTS "Strict DELETE for work_materials" ON public.work_materials;

CREATE POLICY "Strict SELECT for work_materials" ON public.work_materials FOR SELECT TO authenticated USING (public.check_work_access(work_id));
CREATE POLICY "Strict INSERT for work_materials" ON public.work_materials FOR INSERT TO authenticated WITH CHECK (public.check_work_access(work_id));
CREATE POLICY "Strict UPDATE for work_materials" ON public.work_materials FOR UPDATE TO authenticated USING (public.check_work_access(work_id));
CREATE POLICY "Strict DELETE for work_materials" ON public.work_materials FOR DELETE TO authenticated USING (public.check_work_access(work_id));

-- ===================================================================
-- 3. Обновление RPC функций с фильтрацией по объектам
-- ===================================================================

-- 3.1. get_months_summary
CREATE OR REPLACE FUNCTION public.get_months_summary(p_company_id UUID)
RETURNS TABLE (
  month DATE,
  works_count BIGINT,
  total_amount_sum NUMERIC
) AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  IF NOT public.check_permission(v_user_id, 'works', 'read') THEN
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
    DATE_TRUNC('month', w.date)::DATE as month,
    COUNT(*)::BIGINT as works_count,
    COALESCE(SUM(w.total_amount), 0)::NUMERIC as total_amount_sum
  FROM public.works w
  WHERE w.company_id = p_company_id
    AND (
      v_is_owner = true 
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
  GROUP BY DATE_TRUNC('month', w.date)
  ORDER BY month DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 3.2. get_month_employees_summary
CREATE OR REPLACE FUNCTION public.get_month_employees_summary(p_month DATE, p_company_id UUID)
RETURNS TABLE (total_employees BIGINT) AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT COUNT(DISTINCT wh.employee_id)::BIGINT
  FROM public.work_hours wh
  JOIN public.works w ON w.id = wh.work_id
  WHERE w.company_id = p_company_id
    AND DATE_TRUNC('month', w.date) = DATE_TRUNC('month', p_month)
    AND (
      v_is_owner = true 
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND public.check_permission(v_user_id, 'works', 'read');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 3.3. get_month_hours_summary
CREATE OR REPLACE FUNCTION public.get_month_hours_summary(p_month DATE, p_company_id UUID)
RETURNS TABLE (total_hours DOUBLE PRECISION) AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT COALESCE(SUM(wh.hours), 0)::DOUBLE PRECISION
  FROM public.work_hours wh
  JOIN public.works w ON w.id = wh.work_id
  WHERE w.company_id = p_company_id
    AND DATE_TRUNC('month', w.date) = DATE_TRUNC('month', p_month)
    AND (
      v_is_owner = true 
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND public.check_permission(v_user_id, 'works', 'read');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 3.4. get_month_objects_summary
CREATE OR REPLACE FUNCTION public.get_month_objects_summary(p_month DATE, p_company_id UUID)
RETURNS TABLE (
  object_id UUID,
  object_name TEXT,
  works_count BIGINT,
  total_amount DOUBLE PRECISION
) AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT 
    o.id,
    o.name,
    COUNT(w.id)::BIGINT,
    COALESCE(SUM(w.total_amount), 0)::DOUBLE PRECISION
  FROM public.works w
  JOIN public.objects o ON o.id = w.object_id
  WHERE w.company_id = p_company_id
    AND DATE_TRUNC('month', w.date) = DATE_TRUNC('month', p_month)
    AND (
      v_is_owner = true 
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND public.check_permission(v_user_id, 'works', 'read')
  GROUP BY o.id, o.name
  ORDER BY COALESCE(SUM(w.total_amount), 0) DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 3.5. get_month_systems_summary
CREATE OR REPLACE FUNCTION public.get_month_systems_summary(p_month DATE, p_company_id UUID)
RETURNS TABLE (
  system TEXT,
  works_count BIGINT,
  items_count BIGINT,
  total_amount DOUBLE PRECISION
) AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  SELECT 
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p 
  LEFT JOIN public.company_members cm ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT 
    wi.system,
    COUNT(DISTINCT w.id)::BIGINT,
    COUNT(wi.id)::BIGINT,
    COALESCE(SUM(wi.total), 0)::DOUBLE PRECISION
  FROM public.work_items wi
  JOIN public.works w ON w.id = wi.work_id
  WHERE w.company_id = p_company_id
    AND DATE_TRUNC('month', w.date) = DATE_TRUNC('month', p_month)
    AND (
      v_is_owner = true 
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND public.check_permission(v_user_id, 'works', 'read')
  GROUP BY wi.system
  ORDER BY COALESCE(SUM(wi.total), 0) DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

COMMIT;

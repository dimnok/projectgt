-- Опциональный фильтр p_object_id для сводок месяца (график/KPI справа).
-- null = все объекты, как раньше. Список смен слева не использует эти функции.

DROP FUNCTION IF EXISTS public.get_month_employees_summary(date, uuid);
DROP FUNCTION IF EXISTS public.get_month_hours_summary(date, uuid);
DROP FUNCTION IF EXISTS public.get_month_systems_summary(date, uuid);

CREATE FUNCTION public.get_month_employees_summary(
  p_month date,
  p_company_id uuid,
  p_object_id uuid DEFAULT NULL
)
RETURNS TABLE(total_employees bigint)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  SELECT COALESCE(cm.is_owner, false), p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p
  LEFT JOIN public.company_members cm
    ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT COUNT(DISTINCT wh.employee_id)::BIGINT
  FROM public.work_hours wh
  JOIN public.works w ON w.id = wh.work_id
  WHERE w.company_id = p_company_id
    AND DATE_TRUNC('month', w.date) = DATE_TRUNC('month', p_month)
    AND (p_object_id IS NULL OR w.object_id = p_object_id)
    AND (
      v_is_owner = true
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND public.check_permission(v_user_id, 'works', 'read');
END;
$function$;

CREATE FUNCTION public.get_month_hours_summary(
  p_month date,
  p_company_id uuid,
  p_object_id uuid DEFAULT NULL
)
RETURNS TABLE(total_hours double precision)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  SELECT COALESCE(cm.is_owner, false), p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p
  LEFT JOIN public.company_members cm
    ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT COALESCE(SUM(wh.hours), 0)::DOUBLE PRECISION
  FROM public.work_hours wh
  JOIN public.works w ON w.id = wh.work_id
  WHERE w.company_id = p_company_id
    AND DATE_TRUNC('month', w.date) = DATE_TRUNC('month', p_month)
    AND (p_object_id IS NULL OR w.object_id = p_object_id)
    AND (
      v_is_owner = true
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND public.check_permission(v_user_id, 'works', 'read');
END;
$function$;

CREATE FUNCTION public.get_month_systems_summary(
  p_month date,
  p_company_id uuid,
  p_object_id uuid DEFAULT NULL
)
RETURNS TABLE(
  system text,
  works_count bigint,
  items_count bigint,
  total_amount double precision
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID := auth.uid();
  v_is_owner BOOLEAN;
  v_user_objects UUID[];
BEGIN
  SELECT COALESCE(cm.is_owner, false), p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p
  LEFT JOIN public.company_members cm
    ON cm.user_id = p.id AND cm.company_id = p_company_id
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
    AND (p_object_id IS NULL OR w.object_id = p_object_id)
    AND (
      v_is_owner = true
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND public.check_permission(v_user_id, 'works', 'read')
  GROUP BY wi.system
  ORDER BY COALESCE(SUM(wi.total), 0) DESC;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.get_month_employees_summary(date, uuid, uuid) TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_month_employees_summary(date, uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_month_employees_summary(date, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_month_employees_summary(date, uuid, uuid) TO service_role;

GRANT EXECUTE ON FUNCTION public.get_month_hours_summary(date, uuid, uuid) TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_month_hours_summary(date, uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_month_hours_summary(date, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_month_hours_summary(date, uuid, uuid) TO service_role;

GRANT EXECUTE ON FUNCTION public.get_month_systems_summary(date, uuid, uuid) TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_month_systems_summary(date, uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_month_systems_summary(date, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_month_systems_summary(date, uuid, uuid) TO service_role;

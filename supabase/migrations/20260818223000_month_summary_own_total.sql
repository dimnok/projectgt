-- KPI месяца: отдельно общая сумма (мы + подрядчики) и наша сумма
-- (только строки work_items без contractor_id = works.own_total_amount).
-- RETURNS TABLE меняется — DROP, затем CREATE.

DROP FUNCTION IF EXISTS public.get_months_summary(uuid, uuid);
DROP FUNCTION IF EXISTS public.get_month_objects_summary(date, uuid);

CREATE FUNCTION public.get_months_summary(
  p_company_id UUID,
  p_opened_by UUID DEFAULT NULL
)
RETURNS TABLE (
  month DATE,
  works_count BIGINT,
  total_amount_sum NUMERIC,
  own_total_amount_sum NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
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
    DATE_TRUNC('month', w.date)::DATE AS month,
    COUNT(*)::BIGINT AS works_count,
    COALESCE(SUM(w.total_amount), 0)::NUMERIC AS total_amount_sum,
    COALESCE(SUM(w.own_total_amount), 0)::NUMERIC AS own_total_amount_sum
  FROM public.works w
  WHERE w.company_id = p_company_id
    AND (
      v_is_owner = true
      OR (w.object_id IS NOT NULL AND w.object_id = ANY(COALESCE(v_user_objects, '{}'::UUID[])))
    )
    AND (
      p_opened_by IS NULL
      OR (p_opened_by = v_user_id AND w.opened_by = p_opened_by)
    )
  GROUP BY DATE_TRUNC('month', w.date)
  ORDER BY month DESC;
END;
$$;

COMMENT ON FUNCTION public.get_months_summary(uuid, uuid) IS
  'Сводка месяцев: число смен, сумма всех работ, сумма собственного выполнения (без подрядчиков).';

CREATE FUNCTION public.get_month_objects_summary(
  p_month DATE,
  p_company_id UUID
)
RETURNS TABLE (
  object_id UUID,
  object_name TEXT,
  works_count BIGINT,
  total_amount DOUBLE PRECISION,
  own_total_amount DOUBLE PRECISION
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
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
    COALESCE(SUM(w.total_amount), 0)::DOUBLE PRECISION,
    COALESCE(SUM(w.own_total_amount), 0)::DOUBLE PRECISION
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
$$;

COMMENT ON FUNCTION public.get_month_objects_summary(date, uuid) IS
  'Сводка месяца по объектам: число смен, общая сумма, сумма собственного выполнения.';

GRANT EXECUTE ON FUNCTION public.get_months_summary(uuid, uuid) TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_months_summary(uuid, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_months_summary(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_months_summary(uuid, uuid) TO service_role;

GRANT EXECUTE ON FUNCTION public.get_month_objects_summary(date, uuid) TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_month_objects_summary(date, uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_month_objects_summary(date, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_month_objects_summary(date, uuid) TO service_role;

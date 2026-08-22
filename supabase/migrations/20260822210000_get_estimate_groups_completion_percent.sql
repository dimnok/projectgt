-- Добавляет процент выполнения сметы в get_estimate_groups для карточек в Sidebar.
-- Формула совпадает с desktop-заголовком: SUM(факт) / SUM(план) * 100 по объёму.
-- Postgres не позволяет добавить колонку в RETURNS TABLE через CREATE OR REPLACE.

DROP FUNCTION IF EXISTS public.get_estimate_groups(UUID);

CREATE FUNCTION public.get_estimate_groups(p_company_id UUID)
RETURNS TABLE (
  estimate_title TEXT,
  object_id UUID,
  contract_id UUID,
  contract_number TEXT,
  items_count BIGINT,
  total_amount DOUBLE PRECISION,
  completion_percent DOUBLE PRECISION
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
  IF NOT public.check_permission(v_user_id, 'estimates', 'read') THEN
    RETURN;
  END IF;

  SELECT
    COALESCE(cm.is_owner, false),
    p.object_ids
  INTO v_is_owner, v_user_objects
  FROM public.profiles p
  LEFT JOIN public.company_members cm
    ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT
    COALESCE(e.estimate_title, 'Без названия')::TEXT AS estimate_title,
    e.object_id,
    e.contract_id,
    c.number::TEXT AS contract_number,
    COUNT(*)::BIGINT AS items_count,
    COALESCE(SUM(e.total), 0)::DOUBLE PRECISION AS total_amount,
    CASE
      WHEN COALESCE(SUM(e.quantity), 0) = 0 THEN 0::DOUBLE PRECISION
      ELSE (
        COALESCE(SUM(COALESCE(wi_agg.completed_quantity, 0)), 0)
        / SUM(e.quantity)
      ) * 100
    END::DOUBLE PRECISION AS completion_percent
  FROM public.estimates e
  LEFT JOIN public.contracts c ON e.contract_id = c.id
  LEFT JOIN (
    SELECT
      wi.estimate_id,
      SUM(wi.quantity) AS completed_quantity
    FROM public.work_items wi
    WHERE wi.company_id = p_company_id
    GROUP BY wi.estimate_id
  ) wi_agg ON e.id = wi_agg.estimate_id
  WHERE e.company_id = p_company_id
    AND e.visible_in_estimates_module = true
    AND (
      v_is_owner = true
      OR (
        e.object_id IS NOT NULL
        AND e.object_id = ANY (COALESCE(v_user_objects, '{}'::UUID[]))
      )
    )
  GROUP BY e.estimate_title, e.object_id, e.contract_id, c.number
  ORDER BY e.estimate_title;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_estimate_groups(UUID) TO anon;
GRANT EXECUTE ON FUNCTION public.get_estimate_groups(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_estimate_groups(UUID) TO service_role;

-- Опциональная фильтрация сводки по месяцам: только смены, открытые текущим пользователем.
-- p_opened_by игнорируется, если не равен auth.uid() (защита от подстановки чужого id).
--
-- Старую перегрузку get_months_summary(uuid) нужно удалить: иначе PostgREST (PGRST203)
-- не выберет функцию при вызове только с p_company_id.

DROP FUNCTION IF EXISTS public.get_months_summary(uuid);

CREATE OR REPLACE FUNCTION public.get_months_summary(
  p_company_id UUID,
  p_opened_by UUID DEFAULT NULL
)
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
    DATE_TRUNC('month', w.date)::DATE AS month,
    COUNT(*)::BIGINT AS works_count,
    COALESCE(SUM(w.total_amount), 0)::NUMERIC AS total_amount_sum
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
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

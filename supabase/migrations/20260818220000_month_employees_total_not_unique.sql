-- KPI «Специалистов» в сводке месяца: общее число выходов в смены,
-- а не уникальные люди. Сигнатура RPC не меняется.

CREATE OR REPLACE FUNCTION public.get_month_employees_summary(
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
  SELECT COUNT(wh.employee_id)::BIGINT
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

COMMENT ON FUNCTION public.get_month_employees_summary(date, uuid, uuid) IS
  'Сводка месяца: общее число записей work_hours (выходов специалистов в смены), не уникальные employee_id.';

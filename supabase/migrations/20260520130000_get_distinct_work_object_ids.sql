-- Уникальные object_id из смен компании (модуль «Выгрузка», чипы объектов).

CREATE OR REPLACE FUNCTION public.get_distinct_work_object_ids(p_company_id UUID)
RETURNS TABLE (object_id UUID)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
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
  LEFT JOIN public.company_members cm
    ON cm.user_id = p.id AND cm.company_id = p_company_id
  WHERE p.id = v_user_id;

  RETURN QUERY
  SELECT DISTINCT w.object_id
  FROM public.works w
  WHERE w.object_id IS NOT NULL
    AND w.company_id = p_company_id
    AND (
      v_is_owner = true
      OR w.object_id = ANY (COALESCE(v_user_objects, '{}'::UUID[]))
    );
END;
$$;

COMMENT ON FUNCTION public.get_distinct_work_object_ids(UUID) IS
    'Список объектов, по которым есть смены (для модуля выгрузки).';

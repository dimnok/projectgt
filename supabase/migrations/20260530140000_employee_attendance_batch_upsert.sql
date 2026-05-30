-- Массовый upsert ручной посещаемости (диалог табеля): один запрос вместо N×(SELECT+WRITE).

CREATE OR REPLACE FUNCTION public.upsert_employee_attendance_batch(p_rows jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF p_rows IS NULL OR jsonb_typeof(p_rows) <> 'array' OR jsonb_array_length(p_rows) = 0 THEN
    RETURN;
  END IF;

  INSERT INTO public.employee_attendance (
    company_id,
    employee_id,
    object_id,
    date,
    hours,
    attendance_type,
    comment,
    created_by
  )
  SELECT
    r.company_id,
    r.employee_id,
    r.object_id,
    r.date::date,
    r.hours,
    COALESCE(NULLIF(trim(r.attendance_type), ''), 'work'),
    r.comment,
    auth.uid()
  FROM jsonb_to_recordset(p_rows) AS r(
    company_id uuid,
    employee_id uuid,
    object_id uuid,
    date text,
    hours numeric,
    attendance_type text,
    comment text
  )
  ON CONFLICT ON CONSTRAINT unique_employee_object_date DO UPDATE SET
    hours = EXCLUDED.hours,
    attendance_type = EXCLUDED.attendance_type,
    comment = EXCLUDED.comment,
    company_id = EXCLUDED.company_id;
END;
$$;

COMMENT ON FUNCTION public.upsert_employee_attendance_batch(jsonb) IS
  'Пакетный upsert employee_attendance по ключу (employee_id, object_id, date). created_by только при вставке.';

GRANT EXECUTE ON FUNCTION public.upsert_employee_attendance_batch(jsonb) TO authenticated;

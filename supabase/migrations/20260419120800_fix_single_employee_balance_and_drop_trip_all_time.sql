-- 1) Удаляем легаси calculate_business_trip_all_time() — парная к уже удалённой calculate_base_salary_all_time(),
--    нигде не используется, без фильтра по компании.
DROP FUNCTION IF EXISTS public.calculate_business_trip_all_time();

-- 2) Исправляем calculate_single_employee_balance: единая логика приоритета суточных
--    (индивидуальная > общая, но при недоборе minimum_hours падаем на следующий уровень).
CREATE OR REPLACE FUNCTION public.calculate_single_employee_balance(p_employee_id uuid, p_company_id uuid)
RETURNS numeric
LANGUAGE plpgsql
STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_total_base NUMERIC := 0;
  v_total_trip NUMERIC := 0;
  v_total_bonus NUMERIC := 0;
  v_total_penalty NUMERIC := 0;
  v_total_payout NUMERIC := 0;
BEGIN
  SELECT SUM(ahd.hours * COALESCE((
    SELECT er.hourly_rate FROM employee_rates er
    WHERE er.employee_id = p_employee_id
      AND ahd.work_date >= er.valid_from
      AND (er.valid_to IS NULL OR ahd.work_date <= er.valid_to)
      AND er.company_id = p_company_id
    ORDER BY er.valid_from DESC LIMIT 1
  ), 0)) INTO v_total_base
  FROM (
    SELECT wh.hours, w.date AS work_date
    FROM work_hours wh JOIN works w ON wh.work_id = w.id
    WHERE wh.employee_id = p_employee_id AND w.status = 'closed' AND w.company_id = p_company_id
    UNION ALL
    SELECT ea.hours, ea.date AS work_date
    FROM employee_attendance ea
    WHERE ea.employee_id = p_employee_id AND ea.company_id = p_company_id
  ) ahd;

  SELECT SUM(COALESCE((
    SELECT btr.rate FROM business_trip_rates btr
    WHERE btr.object_id = ahd.obj_id
      AND btr.company_id = p_company_id
      AND (btr.employee_id = p_employee_id OR btr.employee_id IS NULL)
      AND ahd.work_date >= btr.valid_from
      AND (btr.valid_to IS NULL OR ahd.work_date <= btr.valid_to)
      AND ahd.hours >= COALESCE(btr.minimum_hours, 0)
    ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1
  ), 0)) INTO v_total_trip
  FROM (
    SELECT wh.hours, w.object_id AS obj_id, w.date AS work_date
    FROM work_hours wh JOIN works w ON wh.work_id = w.id
    WHERE wh.employee_id = p_employee_id AND w.status = 'closed' AND w.object_id IS NOT NULL AND w.company_id = p_company_id
    UNION ALL
    SELECT ea.hours, ea.object_id AS obj_id, ea.date AS work_date
    FROM employee_attendance ea
    WHERE ea.employee_id = p_employee_id AND ea.object_id IS NOT NULL AND ea.company_id = p_company_id
  ) ahd;

  SELECT COALESCE(SUM(pb.amount), 0) INTO v_total_bonus
  FROM payroll_bonus pb
  WHERE pb.employee_id = p_employee_id AND pb.company_id = p_company_id;

  SELECT COALESCE(SUM(pp.amount), 0) INTO v_total_penalty
  FROM payroll_penalty pp
  WHERE pp.employee_id = p_employee_id AND pp.company_id = p_company_id;

  SELECT COALESCE(SUM(po.amount), 0) INTO v_total_payout
  FROM payroll_payout po
  WHERE po.employee_id = p_employee_id AND po.company_id = p_company_id;

  RETURN (COALESCE(v_total_base, 0) + COALESCE(v_total_trip, 0) + COALESCE(v_total_bonus, 0) - COALESCE(v_total_penalty, 0) - COALESCE(v_total_payout, 0))::NUMERIC;
END;
$function$;

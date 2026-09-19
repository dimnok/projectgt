-- Итоги по одному сотруднику за всё время: база, суточные, премии, удержания,
-- выплаты, начислено и остаток. Нужно для окна «История операций».
-- Логика ставки и суточных совпадает с calculate_employee_balances_before_date.

CREATE OR REPLACE FUNCTION public.get_employee_payroll_totals(
  p_employee_id uuid,
  p_company_id uuid
)
RETURNS TABLE(
  base_total numeric,
  trip_total numeric,
  bonus_total numeric,
  penalty_total numeric,
  payout_total numeric,
  earned_total numeric,
  balance numeric
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
  RETURN QUERY
  WITH base_calc AS (
    SELECT COALESCE(SUM(ahd.hours * COALESCE((
      SELECT er.hourly_rate FROM employee_rates er
      WHERE er.employee_id = p_employee_id
        AND ahd.work_date >= er.valid_from
        AND (er.valid_to IS NULL OR ahd.work_date <= er.valid_to)
        AND er.company_id = p_company_id
      ORDER BY er.valid_from DESC LIMIT 1
    ), 0)), 0) AS total_base
    FROM (
      SELECT wh.hours AS hours, w.date AS work_date
      FROM work_hours wh JOIN works w ON wh.work_id = w.id
      WHERE wh.employee_id = p_employee_id
        AND w.status = 'closed'
        AND w.company_id = p_company_id
      UNION ALL
      SELECT ea.hours AS hours, ea.date AS work_date
      FROM employee_attendance ea
      WHERE ea.employee_id = p_employee_id AND ea.company_id = p_company_id
    ) ahd
  ),
  trip_calc AS (
    SELECT COALESCE(SUM(COALESCE((
      SELECT btr.rate FROM business_trip_rates btr
      WHERE btr.object_id = ahd.obj_id
        AND btr.company_id = p_company_id
        AND (btr.employee_id = p_employee_id OR btr.employee_id IS NULL)
        AND ahd.work_date >= btr.valid_from
        AND (btr.valid_to IS NULL OR ahd.work_date <= btr.valid_to)
        AND ahd.hours >= COALESCE(btr.minimum_hours, 0)
      ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1
    ), 0)), 0) AS total_trip
    FROM (
      SELECT wh.hours AS hours, w.object_id AS obj_id, w.date AS work_date
      FROM work_hours wh JOIN works w ON wh.work_id = w.id
      WHERE wh.employee_id = p_employee_id
        AND w.status = 'closed'
        AND w.object_id IS NOT NULL
        AND w.company_id = p_company_id
      UNION ALL
      SELECT ea.hours AS hours, ea.object_id AS obj_id, ea.date AS work_date
      FROM employee_attendance ea
      WHERE ea.employee_id = p_employee_id
        AND ea.object_id IS NOT NULL
        AND ea.company_id = p_company_id
    ) ahd
  ),
  bonus_calc AS (
    SELECT COALESCE(SUM(pb.amount), 0) AS total_bonus
    FROM payroll_bonus pb
    WHERE pb.employee_id = p_employee_id AND pb.company_id = p_company_id
  ),
  penalty_calc AS (
    SELECT COALESCE(SUM(pp.amount), 0) AS total_penalty
    FROM payroll_penalty pp
    WHERE pp.employee_id = p_employee_id AND pp.company_id = p_company_id
  ),
  payout_calc AS (
    SELECT COALESCE(SUM(po.amount), 0) AS total_payout
    FROM payroll_payout po
    WHERE po.employee_id = p_employee_id AND po.company_id = p_company_id
  )
  SELECT
    bc.total_base,
    tc.total_trip,
    bo.total_bonus,
    pe.total_penalty,
    po.total_payout,
    (bc.total_base + tc.total_trip + bo.total_bonus - pe.total_penalty),
    (bc.total_base + tc.total_trip + bo.total_bonus - pe.total_penalty - po.total_payout)
  FROM base_calc bc, trip_calc tc, bonus_calc bo, penalty_calc pe, payout_calc po;
END;
$function$;

COMMENT ON FUNCTION public.get_employee_payroll_totals(uuid, uuid) IS
  'Итоги по сотруднику за всё время: база, суточные, премии, удержания, выплаты, начислено, остаток.';

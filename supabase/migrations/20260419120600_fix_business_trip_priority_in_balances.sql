-- Единая логика приоритета суточных в calculate_employee_balances и _before_date.
-- См. комментарий в 20260419120500_fix_business_trip_priority_in_payroll_for_month.sql.

CREATE OR REPLACE FUNCTION public.calculate_employee_balances(p_company_id uuid)
RETURNS TABLE(employee_id uuid, balance numeric)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  WITH
  base_salary_calc AS (
    SELECT ahd.emp_id,
      SUM(ahd.hours * COALESCE((
        SELECT er.hourly_rate FROM employee_rates er
        WHERE er.employee_id = ahd.emp_id
          AND ahd.work_date >= er.valid_from
          AND (er.valid_to IS NULL OR ahd.work_date <= er.valid_to)
          AND er.company_id = p_company_id
        ORDER BY er.valid_from DESC LIMIT 1
      ), 0)) AS total_base
    FROM (
      SELECT wh.employee_id AS emp_id, wh.hours, w.date AS work_date
      FROM work_hours wh JOIN works w ON wh.work_id = w.id
      WHERE w.status = 'closed' AND w.company_id = p_company_id
      UNION ALL
      SELECT ea.employee_id AS emp_id, ea.hours, ea.date AS work_date
      FROM employee_attendance ea WHERE ea.company_id = p_company_id
    ) ahd
    GROUP BY ahd.emp_id
  ),
  trip_calc AS (
    SELECT ahd.emp_id,
      SUM(COALESCE((
        SELECT btr.rate FROM business_trip_rates btr
        WHERE btr.object_id = ahd.obj_id
          AND btr.company_id = p_company_id
          AND (btr.employee_id = ahd.emp_id OR btr.employee_id IS NULL)
          AND ahd.work_date >= btr.valid_from
          AND (btr.valid_to IS NULL OR ahd.work_date <= btr.valid_to)
          AND ahd.hours >= COALESCE(btr.minimum_hours, 0)
        ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1
      ), 0)) AS total_trip
    FROM (
      SELECT wh.employee_id AS emp_id, wh.hours, w.object_id AS obj_id, w.date AS work_date
      FROM work_hours wh JOIN works w ON wh.work_id = w.id
      WHERE w.status = 'closed' AND w.object_id IS NOT NULL AND w.company_id = p_company_id
      UNION ALL
      SELECT ea.employee_id AS emp_id, ea.hours, ea.object_id AS obj_id, ea.date AS work_date
      FROM employee_attendance ea WHERE ea.object_id IS NOT NULL AND ea.company_id = p_company_id
    ) ahd
    GROUP BY ahd.emp_id
  ),
  bonus_calc AS (
    SELECT pb.employee_id AS emp_id, COALESCE(SUM(pb.amount), 0) AS total_bonus
    FROM payroll_bonus pb WHERE pb.company_id = p_company_id GROUP BY pb.employee_id
  ),
  penalty_calc AS (
    SELECT pp.employee_id AS emp_id, COALESCE(SUM(pp.amount), 0) AS total_penalty
    FROM payroll_penalty pp WHERE pp.company_id = p_company_id GROUP BY pp.employee_id
  ),
  payout_calc AS (
    SELECT po.employee_id AS emp_id, COALESCE(SUM(po.amount), 0) AS total_payout
    FROM payroll_payout po WHERE po.company_id = p_company_id GROUP BY po.employee_id
  ),
  all_employees AS (
    SELECT emp_id FROM base_salary_calc UNION SELECT emp_id FROM trip_calc UNION SELECT emp_id FROM bonus_calc UNION SELECT emp_id FROM penalty_calc UNION SELECT emp_id FROM payout_calc
  )
  SELECT ae.emp_id,
    (COALESCE(bs.total_base, 0) + COALESCE(tc.total_trip, 0) + COALESCE(bc.total_bonus, 0) - COALESCE(pc.total_penalty, 0) - COALESCE(po.total_payout, 0))::NUMERIC
  FROM all_employees ae
  LEFT JOIN base_salary_calc bs ON ae.emp_id = bs.emp_id
  LEFT JOIN trip_calc tc ON ae.emp_id = tc.emp_id
  LEFT JOIN bonus_calc bc ON ae.emp_id = bc.emp_id
  LEFT JOIN penalty_calc pc ON ae.emp_id = pc.emp_id
  LEFT JOIN payout_calc po ON ae.emp_id = po.emp_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_employee_balances_before_date(
  p_before_date timestamp with time zone,
  p_company_id uuid
)
RETURNS TABLE(employee_id uuid, accruals_sum numeric, payouts_sum numeric, balance numeric)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  WITH
  base_salary_calc AS (
    SELECT ahd.emp_id,
      SUM(ahd.hours * COALESCE((
        SELECT er.hourly_rate FROM employee_rates er
        WHERE er.employee_id = ahd.emp_id
          AND ahd.work_date >= er.valid_from
          AND (er.valid_to IS NULL OR ahd.work_date <= er.valid_to)
          AND er.company_id = p_company_id
        ORDER BY er.valid_from DESC LIMIT 1
      ), 0)) AS total_base
    FROM (
      SELECT wh.employee_id AS emp_id, wh.hours, w.date AS work_date
      FROM work_hours wh JOIN works w ON wh.work_id = w.id
      WHERE w.status = 'closed' AND w.date < p_before_date AND w.company_id = p_company_id
      UNION ALL
      SELECT ea.employee_id AS emp_id, ea.hours, ea.date AS work_date
      FROM employee_attendance ea WHERE ea.date < p_before_date AND ea.company_id = p_company_id
    ) ahd
    GROUP BY ahd.emp_id
  ),
  trip_calc AS (
    SELECT ahd.emp_id,
      SUM(COALESCE((
        SELECT btr.rate FROM business_trip_rates btr
        WHERE btr.object_id = ahd.obj_id
          AND btr.company_id = p_company_id
          AND (btr.employee_id = ahd.emp_id OR btr.employee_id IS NULL)
          AND ahd.work_date >= btr.valid_from
          AND (btr.valid_to IS NULL OR ahd.work_date <= btr.valid_to)
          AND ahd.hours >= COALESCE(btr.minimum_hours, 0)
        ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1
      ), 0)) AS total_trip
    FROM (
      SELECT wh.employee_id AS emp_id, wh.hours, w.object_id AS obj_id, w.date AS work_date
      FROM work_hours wh JOIN works w ON wh.work_id = w.id
      WHERE w.status = 'closed' AND w.object_id IS NOT NULL AND w.date < p_before_date AND w.company_id = p_company_id
      UNION ALL
      SELECT ea.employee_id AS emp_id, ea.hours, ea.object_id AS obj_id, ea.date AS work_date
      FROM employee_attendance ea WHERE ea.object_id IS NOT NULL AND ea.date < p_before_date AND ea.company_id = p_company_id
    ) ahd
    GROUP BY ahd.emp_id
  ),
  bonus_calc AS (
    SELECT pb.employee_id AS emp_id, COALESCE(SUM(pb.amount), 0) AS total_bonus
    FROM payroll_bonus pb WHERE pb.date < p_before_date AND pb.company_id = p_company_id GROUP BY pb.employee_id
  ),
  penalty_calc AS (
    SELECT pp.employee_id AS emp_id, COALESCE(SUM(pp.amount), 0) AS total_penalty
    FROM payroll_penalty pp WHERE pp.date < p_before_date AND pp.company_id = p_company_id GROUP BY pp.employee_id
  ),
  payout_calc AS (
    SELECT po.employee_id AS emp_id, COALESCE(SUM(po.amount), 0) AS total_payout
    FROM payroll_payout po WHERE po.payout_date < p_before_date AND po.company_id = p_company_id GROUP BY po.employee_id
  ),
  all_employees AS (
    SELECT emp_id FROM base_salary_calc UNION SELECT emp_id FROM trip_calc UNION SELECT emp_id FROM bonus_calc UNION SELECT emp_id FROM penalty_calc UNION SELECT emp_id FROM payout_calc
  )
  SELECT ae.emp_id AS employee_id,
    (COALESCE(bs.total_base, 0) + COALESCE(tc.total_trip, 0) + COALESCE(bc.total_bonus, 0) - COALESCE(pc.total_penalty, 0))::NUMERIC AS accruals_sum,
    COALESCE(po.total_payout, 0)::NUMERIC AS payouts_sum,
    (COALESCE(bs.total_base, 0) + COALESCE(tc.total_trip, 0) + COALESCE(bc.total_bonus, 0) - COALESCE(pc.total_penalty, 0) - COALESCE(po.total_payout, 0))::NUMERIC AS balance
  FROM all_employees ae
  LEFT JOIN base_salary_calc bs ON ae.emp_id = bs.emp_id
  LEFT JOIN trip_calc tc ON ae.emp_id = tc.emp_id
  LEFT JOIN bonus_calc bc ON ae.emp_id = bc.emp_id
  LEFT JOIN penalty_calc pc ON ae.emp_id = pc.emp_id
  LEFT JOIN payout_calc po ON ae.emp_id = po.emp_id;
END;
$function$;

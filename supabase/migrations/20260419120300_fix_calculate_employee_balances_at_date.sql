-- Добавляем фильтр company_id в подзапросах к employee_rates и business_trip_rates.
-- Причина: без фильтра балансы будут считаться некорректно, когда сотрудник окажется в нескольких компаниях.
-- На текущих данных результат не меняется.

CREATE OR REPLACE FUNCTION public.calculate_employee_balances_at_date(
  p_date timestamp with time zone,
  p_company_id uuid
)
RETURNS TABLE(employee_id uuid, balance numeric)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  WITH
  all_hours_data AS (
    SELECT wh.employee_id AS eid, wh.hours AS whours, w.object_id AS oid, w.date AS wdate
    FROM work_hours wh JOIN works w ON wh.work_id = w.id
    WHERE w.status = 'closed' AND w.company_id = p_company_id AND w.date <= p_date
    UNION ALL
    SELECT ea.employee_id AS eid, ea.hours AS whours, ea.object_id AS oid, ea.date AS wdate
    FROM employee_attendance ea WHERE ea.company_id = p_company_id AND ea.date <= p_date
  ),
  accruals_calc AS (
    SELECT ahd.eid AS a_eid,
      SUM(ahd.whours * COALESCE((
        SELECT er.hourly_rate FROM employee_rates er
        WHERE er.employee_id = ahd.eid
          AND er.company_id = p_company_id
          AND ahd.wdate >= er.valid_from
          AND (er.valid_to IS NULL OR ahd.wdate <= er.valid_to)
        ORDER BY er.valid_from DESC LIMIT 1
      ), 0)) AS total_base,
      SUM(COALESCE((
        SELECT btr.rate FROM business_trip_rates btr
        WHERE btr.object_id = ahd.oid
          AND btr.company_id = p_company_id
          AND (btr.employee_id = ahd.eid OR btr.employee_id IS NULL)
          AND ahd.wdate >= btr.valid_from
          AND (btr.valid_to IS NULL OR ahd.wdate <= btr.valid_to)
          AND ahd.whours >= COALESCE(btr.minimum_hours, 0)
        ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1
      ), 0)) AS total_trip
    FROM all_hours_data ahd GROUP BY ahd.eid
  ),
  extras_calc AS (
    SELECT t.ex_eid,
      SUM(CASE WHEN t.etype = 'bonus' THEN t.eamount ELSE 0 END) AS bonuses,
      SUM(CASE WHEN t.etype = 'penalty' THEN t.eamount ELSE 0 END) AS penalties
    FROM (
      SELECT pb.employee_id AS ex_eid, pb.amount AS eamount, 'bonus' AS etype FROM payroll_bonus pb WHERE pb.company_id = p_company_id AND pb.date <= p_date
      UNION ALL
      SELECT pp.employee_id AS ex_eid, pp.amount AS eamount, 'penalty' AS etype FROM payroll_penalty pp WHERE pp.company_id = p_company_id AND pp.date <= p_date
    ) AS t GROUP BY t.ex_eid
  ),
  payouts_calc AS (
    SELECT po.employee_id AS p_eid, SUM(po.amount) AS total_paid
    FROM payroll_payout po WHERE po.company_id = p_company_id GROUP BY po.employee_id
  ),
  all_emp_ids AS (
    SELECT a_eid AS final_eid FROM accruals_calc
    UNION SELECT ex_eid FROM extras_calc
    UNION SELECT p_eid FROM payouts_calc
  )
  SELECT
    ae.final_eid,
    (COALESCE(ac.total_base, 0) + COALESCE(ac.total_trip, 0) + COALESCE(ex.bonuses, 0) - COALESCE(ex.penalties, 0) - COALESCE(pc.total_paid, 0))::NUMERIC
  FROM all_emp_ids ae
  LEFT JOIN accruals_calc ac ON ae.final_eid = ac.a_eid
  LEFT JOIN extras_calc ex ON ae.final_eid = ex.ex_eid
  LEFT JOIN payouts_calc pc ON ae.final_eid = pc.p_eid;
END;
$function$;

-- ФОТ: показывать строку за месяц, если у сотрудника есть выплата(и) в этом месяце
-- (даже без часов, премий и штрафов). У таблицы payroll_payout нет object_id —
-- фильтр p_object_ids на этот признак не накладывается (как и для «голых» выплат в UI).

CREATE OR REPLACE FUNCTION public.calculate_payroll_for_month(
  p_year integer,
  p_month integer,
  p_object_ids uuid[] DEFAULT NULL::uuid[]
)
RETURNS TABLE(
  employee_id uuid,
  employee_name text,
  total_hours numeric,
  base_salary numeric,
  business_trip_total numeric,
  bonuses_total numeric,
  penalties_total numeric,
  net_salary numeric,
  current_hourly_rate numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  WITH
  all_hours AS (
    SELECT
      wh.employee_id AS emp_id,
      w.date AS work_date,
      w.object_id AS obj_id,
      wh.hours AS work_hours
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE EXTRACT(YEAR FROM w.date) = p_year
      AND EXTRACT(MONTH FROM w.date) = p_month
      AND w.status = 'closed'
      AND (p_object_ids IS NULL OR w.object_id = ANY(p_object_ids))

    UNION ALL

    SELECT
      ea.employee_id AS emp_id,
      ea.date AS work_date,
      ea.object_id AS obj_id,
      ea.hours AS work_hours
    FROM employee_attendance ea
    WHERE EXTRACT(YEAR FROM ea.date) = p_year
      AND EXTRACT(MONTH FROM ea.date) = p_month
      AND (p_object_ids IS NULL OR ea.object_id = ANY(p_object_ids))
  ),

  base_calc AS (
    SELECT
      ah.emp_id,
      SUM(ah.work_hours) AS hours_sum,
      SUM(ah.work_hours * COALESCE(
        (SELECT er.hourly_rate
         FROM employee_rates er
         WHERE er.employee_id = ah.emp_id
           AND ah.work_date >= er.valid_from
           AND (er.valid_to IS NULL OR ah.work_date <= er.valid_to)
         ORDER BY er.valid_from DESC
         LIMIT 1), 0)
      ) AS base_sal
    FROM all_hours ah
    GROUP BY ah.emp_id
  ),

  trip_calc AS (
    SELECT
      ah.emp_id,
      SUM(
        CASE
          WHEN btr_individual.rate IS NOT NULL
               AND ah.work_hours >= COALESCE(btr_individual.minimum_hours, 0)
          THEN btr_individual.rate
          WHEN btr_general.rate IS NOT NULL
               AND ah.work_hours >= COALESCE(btr_general.minimum_hours, 0)
          THEN btr_general.rate
          ELSE 0
        END
      ) AS trip_total
    FROM all_hours ah
    LEFT JOIN business_trip_rates btr_individual
      ON btr_individual.object_id = ah.obj_id
      AND btr_individual.employee_id = ah.emp_id
      AND ah.work_date >= btr_individual.valid_from
      AND (btr_individual.valid_to IS NULL OR ah.work_date <= btr_individual.valid_to)
    LEFT JOIN business_trip_rates btr_general
      ON btr_general.object_id = ah.obj_id
      AND btr_general.employee_id IS NULL
      AND ah.work_date >= btr_general.valid_from
      AND (btr_general.valid_to IS NULL OR ah.work_date <= btr_general.valid_to)
    WHERE ah.obj_id IS NOT NULL
    GROUP BY ah.emp_id
  ),

  bonus_calc AS (
    SELECT
      pb.employee_id AS emp_id,
      COALESCE(SUM(pb.amount), 0) AS bonuses
    FROM payroll_bonus pb
    WHERE EXTRACT(YEAR FROM pb.date) = p_year
      AND EXTRACT(MONTH FROM pb.date) = p_month
      AND (p_object_ids IS NULL OR pb.object_id IS NULL OR pb.object_id = ANY(p_object_ids))
    GROUP BY pb.employee_id
  ),

  penalty_calc AS (
    SELECT
      pp.employee_id AS emp_id,
      COALESCE(SUM(pp.amount), 0) AS penalties
    FROM payroll_penalty pp
    WHERE EXTRACT(YEAR FROM pp.date) = p_year
      AND EXTRACT(MONTH FROM pp.date) = p_month
      AND (p_object_ids IS NULL OR pp.object_id IS NULL OR pp.object_id = ANY(p_object_ids))
    GROUP BY pp.employee_id
  ),

  payout_emps AS (
    SELECT DISTINCT po.employee_id AS emp_id
    FROM payroll_payout po
    WHERE EXTRACT(YEAR FROM po.payout_date) = p_year
      AND EXTRACT(MONTH FROM po.payout_date) = p_month
  ),

  current_rates AS (
    SELECT DISTINCT ON (er.employee_id)
      er.employee_id AS emp_id,
      er.hourly_rate AS current_rate
    FROM employee_rates er
    WHERE er.valid_from <= CURRENT_DATE
      AND (er.valid_to IS NULL OR er.valid_to >= CURRENT_DATE)
    ORDER BY er.employee_id, er.valid_from DESC
  )

  SELECT
    e.id,
    CONCAT(e.last_name, ' ', e.first_name, ' ', COALESCE(e.middle_name, ''))::text AS employee_name,
    COALESCE(bc.hours_sum, 0)::NUMERIC,
    COALESCE(bc.base_sal, 0)::NUMERIC,
    COALESCE(tc.trip_total, 0)::NUMERIC,
    COALESCE(bonus.bonuses, 0)::NUMERIC,
    COALESCE(pen.penalties, 0)::NUMERIC,
    (COALESCE(bc.base_sal, 0)
     + COALESCE(tc.trip_total, 0)
     + COALESCE(bonus.bonuses, 0)
     - COALESCE(pen.penalties, 0))::NUMERIC,
    COALESCE(cr.current_rate, 0)::NUMERIC
  FROM employees e
  LEFT JOIN base_calc bc ON e.id = bc.emp_id
  LEFT JOIN trip_calc tc ON e.id = tc.emp_id
  LEFT JOIN bonus_calc bonus ON e.id = bonus.emp_id
  LEFT JOIN penalty_calc pen ON e.id = pen.emp_id
  LEFT JOIN payout_emps pout ON e.id = pout.emp_id
  LEFT JOIN current_rates cr ON e.id = cr.emp_id
  WHERE bc.emp_id IS NOT NULL
     OR bonus.emp_id IS NOT NULL
     OR pen.emp_id IS NOT NULL
     OR pout.emp_id IS NOT NULL
  ORDER BY e.last_name, e.first_name;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_payroll_for_month(
  p_year integer,
  p_month integer,
  p_object_ids uuid[] DEFAULT NULL::uuid[],
  p_company_id uuid DEFAULT NULL::uuid
)
RETURNS TABLE(
  employee_id uuid,
  full_name text,
  total_hours numeric,
  base_salary numeric,
  business_trip_total numeric,
  bonuses_total numeric,
  penalties_total numeric,
  net_salary numeric,
  current_hourly_rate numeric
)
LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  WITH
  all_hours AS (
    SELECT
      wh.employee_id AS emp_id,
      w.date AS work_date,
      w.object_id AS obj_id,
      wh.hours AS work_hours
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE EXTRACT(YEAR FROM w.date) = p_year
      AND EXTRACT(MONTH FROM w.date) = p_month
      AND w.status = 'closed'
      AND (p_object_ids IS NULL OR w.object_id = ANY(p_object_ids))
      AND (p_company_id IS NULL OR w.company_id = p_company_id)

    UNION ALL

    SELECT
      ea.employee_id AS emp_id,
      ea.date AS work_date,
      ea.object_id AS obj_id,
      ea.hours AS work_hours
    FROM employee_attendance ea
    WHERE EXTRACT(YEAR FROM ea.date) = p_year
      AND EXTRACT(MONTH FROM ea.date) = p_month
      AND (p_object_ids IS NULL OR ea.object_id = ANY(p_object_ids))
      AND (p_company_id IS NULL OR ea.company_id = p_company_id)
  ),

  base_calc AS (
    SELECT
      ah.emp_id,
      SUM(ah.work_hours) AS hours_sum,
      SUM(ah.work_hours * COALESCE(
        (SELECT er.hourly_rate
         FROM employee_rates er
         WHERE er.employee_id = ah.emp_id
           AND ah.work_date >= er.valid_from
           AND (er.valid_to IS NULL OR ah.work_date <= er.valid_to)
           AND (p_company_id IS NULL OR er.company_id = p_company_id)
         ORDER BY er.valid_from DESC
         LIMIT 1), 0)
      ) AS base_sal
    FROM all_hours ah
    GROUP BY ah.emp_id
  ),

  trip_calc AS (
    SELECT
      ah.emp_id,
      SUM(
        CASE
          WHEN btr_individual.rate IS NOT NULL
               AND ah.work_hours >= COALESCE(btr_individual.minimum_hours, 0)
          THEN btr_individual.rate
          WHEN btr_general.rate IS NOT NULL
               AND ah.work_hours >= COALESCE(btr_general.minimum_hours, 0)
          THEN btr_general.rate
          ELSE 0
        END
      ) AS trip_total
    FROM all_hours ah
    LEFT JOIN business_trip_rates btr_individual
      ON btr_individual.object_id = ah.obj_id
      AND btr_individual.employee_id = ah.emp_id
      AND ah.work_date >= btr_individual.valid_from
      AND (btr_individual.valid_to IS NULL OR ah.work_date <= btr_individual.valid_to)
      AND (p_company_id IS NULL OR btr_individual.company_id = p_company_id)
    LEFT JOIN business_trip_rates btr_general
      ON btr_general.object_id = ah.obj_id
      AND btr_general.employee_id IS NULL
      AND ah.work_date >= btr_general.valid_from
      AND (btr_general.valid_to IS NULL OR ah.work_date <= btr_general.valid_to)
      AND (p_company_id IS NULL OR btr_general.company_id = p_company_id)
    WHERE ah.obj_id IS NOT NULL
    GROUP BY ah.emp_id
  ),

  bonus_calc AS (
    SELECT
      pb.employee_id AS emp_id,
      COALESCE(SUM(pb.amount), 0) AS bonuses
    FROM payroll_bonus pb
    WHERE EXTRACT(YEAR FROM pb.date) = p_year
      AND EXTRACT(MONTH FROM pb.date) = p_month
      AND (p_object_ids IS NULL OR pb.object_id IS NULL OR pb.object_id = ANY(p_object_ids))
      AND (p_company_id IS NULL OR pb.company_id = p_company_id)
    GROUP BY pb.employee_id
  ),

  penalty_calc AS (
    SELECT
      pp.employee_id AS emp_id,
      COALESCE(SUM(pp.amount), 0) AS penalties
    FROM payroll_penalty pp
    WHERE EXTRACT(YEAR FROM pp.date) = p_year
      AND EXTRACT(MONTH FROM pp.date) = p_month
      AND (p_object_ids IS NULL OR pp.object_id IS NULL OR pp.object_id = ANY(p_object_ids))
      AND (p_company_id IS NULL OR pp.company_id = p_company_id)
    GROUP BY pp.employee_id
  ),

  payout_emps AS (
    SELECT DISTINCT po.employee_id AS emp_id
    FROM payroll_payout po
    WHERE EXTRACT(YEAR FROM po.payout_date) = p_year
      AND EXTRACT(MONTH FROM po.payout_date) = p_month
      AND (p_company_id IS NULL OR po.company_id = p_company_id)
  ),

  current_rates AS (
    SELECT DISTINCT ON (er.employee_id)
      er.employee_id AS emp_id,
      er.hourly_rate AS current_rate
    FROM employee_rates er
    WHERE er.valid_from <= CURRENT_DATE
      AND (er.valid_to IS NULL OR er.valid_to >= CURRENT_DATE)
      AND (p_company_id IS NULL OR er.company_id = p_company_id)
    ORDER BY er.employee_id, er.valid_from DESC
  )

  SELECT
    e.id,
    CONCAT(e.last_name, ' ', e.first_name, ' ', COALESCE(e.middle_name, ''))::text AS full_name,
    COALESCE(bc.hours_sum, 0)::NUMERIC,
    COALESCE(bc.base_sal, 0)::NUMERIC,
    COALESCE(tc.trip_total, 0)::NUMERIC,
    COALESCE(bonus.bonuses, 0)::NUMERIC,
    COALESCE(pen.penalties, 0)::NUMERIC,
    (COALESCE(bc.base_sal, 0)
     + COALESCE(tc.trip_total, 0)
     + COALESCE(bonus.bonuses, 0)
     - COALESCE(pen.penalties, 0))::NUMERIC,
    COALESCE(cr.current_rate, 0)::NUMERIC
  FROM employees e
  LEFT JOIN base_calc bc ON e.id = bc.emp_id
  LEFT JOIN trip_calc tc ON e.id = tc.emp_id
  LEFT JOIN bonus_calc bonus ON e.id = bonus.emp_id
  LEFT JOIN penalty_calc pen ON e.id = pen.emp_id
  LEFT JOIN payout_emps pout ON e.id = pout.emp_id
  LEFT JOIN current_rates cr ON e.id = cr.emp_id
  WHERE (bc.emp_id IS NOT NULL OR bonus.emp_id IS NOT NULL OR pen.emp_id IS NOT NULL
         OR pout.emp_id IS NOT NULL)
    AND (p_company_id IS NULL OR e.company_id = p_company_id)
  ORDER BY e.last_name, e.first_name;
END;
$function$;

COMMENT ON FUNCTION public.calculate_payroll_for_month(integer, integer, uuid[]) IS
'ФОТ за месяц: часы, суточные, премии, штрафы; строка также если есть выплата в календарном месяце без начислений.';

COMMENT ON FUNCTION public.calculate_payroll_for_month(integer, integer, uuid[], uuid) IS
'ФОТ за месяц (company_id, object_ids); строка также при выплате в месяце без часов/премий/штрафов.';

-- Миграция: Интеграция employee_attendance в расчёт ФОТ
-- Дата: 2025-10-05
-- Описание: Обновление функций расчёта ФОТ для учёта часов из employee_attendance

-- =====================================================
-- Функция: calculate_payroll_for_month (обновлённая)
-- Назначение: Рассчитывает ФОТ с учётом часов из work_hours И employee_attendance
-- =====================================================

-- Удаляем старую функцию
DROP FUNCTION IF EXISTS calculate_payroll_for_month(INT, INT);

CREATE OR REPLACE FUNCTION calculate_payroll_for_month(
  p_year INT,
  p_month INT
)
RETURNS TABLE (
  employee_id UUID,
  employee_name TEXT,
  total_hours NUMERIC,
  base_salary NUMERIC,
  business_trip_total NUMERIC,
  bonuses_total NUMERIC,
  penalties_total NUMERIC,
  net_salary NUMERIC,
  current_hourly_rate NUMERIC
) 
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
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
    
    UNION ALL
    
    SELECT 
      ea.employee_id AS emp_id,
      ea.date AS work_date,
      ea.object_id AS obj_id,
      ea.hours AS work_hours
    FROM employee_attendance ea
    WHERE EXTRACT(YEAR FROM ea.date) = p_year
      AND EXTRACT(MONTH FROM ea.date) = p_month
  ),
  
  base_calc AS (
    SELECT 
      ah.emp_id,
      SUM(ah.work_hours) as hours_sum,
      SUM(ah.work_hours * COALESCE(
        (SELECT er.hourly_rate 
         FROM employee_rates er 
         WHERE er.employee_id = ah.emp_id
           AND ah.work_date >= er.valid_from 
           AND (er.valid_to IS NULL OR ah.work_date <= er.valid_to)
         ORDER BY er.valid_from DESC
         LIMIT 1), 0)
      ) as base_sal
    FROM all_hours ah
    GROUP BY ah.emp_id
  ),
  
  trip_calc AS (
    SELECT 
      ah.emp_id,
      SUM(
        CASE
          -- Приоритет 1: Индивидуальная ставка (если hours >= minimum_hours)
          WHEN btr_individual.rate IS NOT NULL 
               AND ah.work_hours >= COALESCE(btr_individual.minimum_hours, 0)
          THEN btr_individual.rate
          
          -- Приоритет 2: Общая ставка (если hours >= minimum_hours)
          WHEN btr_general.rate IS NOT NULL 
               AND ah.work_hours >= COALESCE(btr_general.minimum_hours, 0)
          THEN btr_general.rate
          
          ELSE 0
        END
      ) as trip_total
    FROM all_hours ah
    
    -- LEFT JOIN для индивидуальных ставок
    LEFT JOIN business_trip_rates btr_individual
      ON btr_individual.object_id = ah.obj_id
      AND btr_individual.employee_id = ah.emp_id
      AND ah.work_date >= btr_individual.valid_from
      AND (btr_individual.valid_to IS NULL OR ah.work_date <= btr_individual.valid_to)
    
    -- LEFT JOIN для общих ставок (employee_id IS NULL)
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
      COALESCE(SUM(pb.amount), 0) as bonuses
    FROM payroll_bonus pb
    WHERE EXTRACT(YEAR FROM pb.date) = p_year
      AND EXTRACT(MONTH FROM pb.date) = p_month
    GROUP BY pb.employee_id
  ),
  
  penalty_calc AS (
    SELECT 
      pp.employee_id AS emp_id,
      COALESCE(SUM(pp.amount), 0) as penalties
    FROM payroll_penalty pp
    WHERE EXTRACT(YEAR FROM pp.date) = p_year
      AND EXTRACT(MONTH FROM pp.date) = p_month
    GROUP BY pp.employee_id
  ),
  
  current_rates AS (
    SELECT DISTINCT ON (er.employee_id)
      er.employee_id AS emp_id,
      er.hourly_rate as current_rate
    FROM employee_rates er
    WHERE er.valid_from <= CURRENT_DATE
      AND (er.valid_to IS NULL OR er.valid_to >= CURRENT_DATE)
    ORDER BY er.employee_id, er.valid_from DESC
  )
  
  SELECT 
    e.id,
    CONCAT(e.last_name, ' ', e.first_name, ' ', COALESCE(e.middle_name, '')) AS full_name,
    COALESCE(bc.hours_sum, 0)::NUMERIC,
    COALESCE(bc.base_sal, 0)::NUMERIC,
    COALESCE(tc.trip_total, 0)::NUMERIC,
    COALESCE(bonus.bonuses, 0)::NUMERIC,
    COALESCE(pen.penalties, 0)::NUMERIC,
    (COALESCE(bc.base_sal, 0) + 
     COALESCE(tc.trip_total, 0) + 
     COALESCE(bonus.bonuses, 0) - 
     COALESCE(pen.penalties, 0))::NUMERIC,
    COALESCE(cr.current_rate, 0)::NUMERIC
  FROM employees e
  LEFT JOIN base_calc bc ON e.id = bc.emp_id
  LEFT JOIN trip_calc tc ON e.id = tc.emp_id
  LEFT JOIN bonus_calc bonus ON e.id = bonus.emp_id
  LEFT JOIN penalty_calc pen ON e.id = pen.emp_id
  LEFT JOIN current_rates cr ON e.id = cr.emp_id
  WHERE bc.emp_id IS NOT NULL
  ORDER BY e.last_name, e.first_name;
END;
$$;

COMMENT ON FUNCTION calculate_payroll_for_month(INT, INT) IS 
'Рассчитывает ФОТ для всех сотрудников за указанный месяц. Включает часы из смен (work_hours) и ручного ввода (employee_attendance), командировочные с учётом индивидуальных и общих ставок, премии и штрафы.';

-- =====================================================
-- Функция: calculate_base_salary_all_time (обновлённая)
-- Назначение: Рассчитывает базовую зарплату за всё время с учётом employee_attendance
-- =====================================================

DROP FUNCTION IF EXISTS calculate_base_salary_all_time();

CREATE OR REPLACE FUNCTION calculate_base_salary_all_time()
RETURNS TABLE (
  employee_id UUID,
  base_salary NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH all_hours AS (
    SELECT 
      wh.employee_id,
      w.date,
      wh.hours
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE w.status = 'closed'
    
    UNION ALL
    
    SELECT 
      ea.employee_id,
      ea.date,
      ea.hours
    FROM employee_attendance ea
  )
  SELECT 
    ah.employee_id,
    SUM(ah.hours * COALESCE(
      (SELECT hourly_rate 
       FROM employee_rates er 
       WHERE er.employee_id = ah.employee_id 
         AND ah.date >= er.valid_from 
         AND (er.valid_to IS NULL OR ah.date <= er.valid_to)
       ORDER BY er.valid_from DESC
       LIMIT 1), 0)
    )::NUMERIC as base_sal
  FROM all_hours ah
  GROUP BY ah.employee_id;
END;
$$;

COMMENT ON FUNCTION calculate_base_salary_all_time() IS 
'Рассчитывает базовую зарплату (часы × ставка) для всех сотрудников за всё время. Включает часы из work_hours и employee_attendance.';

-- =====================================================
-- Функция: calculate_business_trip_all_time (обновлённая)
-- Назначение: Рассчитывает командировочные за всё время с учётом employee_attendance
-- =====================================================

DROP FUNCTION IF EXISTS calculate_business_trip_all_time();

CREATE OR REPLACE FUNCTION calculate_business_trip_all_time()
RETURNS TABLE (
  employee_id UUID,
  business_trip_total NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH all_hours_data AS (
    -- Часы из смен
    SELECT 
      wh.employee_id,
      wh.hours,
      w.object_id,
      w.date as work_date
    FROM work_hours wh
    INNER JOIN works w ON wh.work_id = w.id
    WHERE w.status = 'closed'
      AND w.object_id IS NOT NULL
      AND wh.hours IS NOT NULL
    
    UNION ALL
    
    -- Часы из ручного ввода
    SELECT 
      ea.employee_id,
      ea.hours,
      ea.object_id,
      ea.date as work_date
    FROM employee_attendance ea
    WHERE ea.object_id IS NOT NULL
      AND ea.hours IS NOT NULL
  ),
  trip_rates_calc AS (
    SELECT 
      ahd.employee_id,
      SUM(
        CASE
          -- Приоритет 1: Индивидуальная ставка (если hours >= minimum_hours)
          WHEN btr_individual.rate IS NOT NULL 
               AND ahd.hours >= COALESCE(btr_individual.minimum_hours, 0)
          THEN btr_individual.rate
          
          -- Приоритет 2: Общая ставка (если hours >= minimum_hours)
          WHEN btr_general.rate IS NOT NULL 
               AND ahd.hours >= COALESCE(btr_general.minimum_hours, 0)
          THEN btr_general.rate
          
          ELSE 0
        END
      ) as total_trip
    FROM all_hours_data ahd
    
    -- LEFT JOIN для индивидуальных ставок
    LEFT JOIN business_trip_rates btr_individual
      ON btr_individual.object_id = ahd.object_id
      AND btr_individual.employee_id = ahd.employee_id
      AND ahd.work_date >= btr_individual.valid_from
      AND (btr_individual.valid_to IS NULL OR ahd.work_date <= btr_individual.valid_to)
    
    -- LEFT JOIN для общих ставок (employee_id IS NULL)
    LEFT JOIN business_trip_rates btr_general
      ON btr_general.object_id = ahd.object_id
      AND btr_general.employee_id IS NULL
      AND ahd.work_date >= btr_general.valid_from
      AND (btr_general.valid_to IS NULL OR ahd.work_date <= btr_general.valid_to)
    
    GROUP BY ahd.employee_id
  )
  SELECT 
    trc.employee_id,
    COALESCE(trc.total_trip, 0)::NUMERIC as trip_total
  FROM trip_rates_calc trc;
END;
$$;

COMMENT ON FUNCTION calculate_business_trip_all_time() IS 
'Рассчитывает командировочные выплаты для всех сотрудников за всё время. Включает записи из work_hours и employee_attendance, учитывает индивидуальные и общие ставки, minimum_hours.';

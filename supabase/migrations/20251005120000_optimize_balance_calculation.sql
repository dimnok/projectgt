-- Миграция: Оптимизация расчёта баланса сотрудников
-- Дата: 2025-10-05
-- Описание: Единая функция для быстрого расчёта баланса всех сотрудников одним запросом

-- Удаляем старую функцию, если существует
DROP FUNCTION IF EXISTS calculate_employee_balances();

-- Оптимизированная функция для быстрого расчёта баланса
CREATE OR REPLACE FUNCTION calculate_employee_balances()
RETURNS TABLE (
  employee_id UUID,
  balance NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH 
  -- 1. Базовая зарплата за всё время
  base_salary_calc AS (
    SELECT 
      ahd.emp_id,
      SUM(ahd.hours * COALESCE(
        (SELECT er.hourly_rate 
         FROM employee_rates er 
         WHERE er.employee_id = ahd.emp_id
           AND ahd.work_date >= er.valid_from 
           AND (er.valid_to IS NULL OR ahd.work_date <= er.valid_to)
         ORDER BY er.valid_from DESC
         LIMIT 1), 0)
      ) as total_base
    FROM (
      -- Часы из смен
      SELECT 
        wh.employee_id AS emp_id,
        wh.hours,
        w.date as work_date
      FROM work_hours wh
      JOIN works w ON wh.work_id = w.id
      WHERE w.status = 'closed'
      
      UNION ALL
      
      -- Часы из ручного ввода
      SELECT 
        ea.employee_id AS emp_id,
        ea.hours,
        ea.date as work_date
      FROM employee_attendance ea
    ) ahd
    GROUP BY ahd.emp_id
  ),
  
  -- 2. Суточные за всё время
  trip_calc AS (
    SELECT 
      ahd.emp_id,
      SUM(
        CASE
          WHEN btr_individual.rate IS NOT NULL 
               AND ahd.hours >= COALESCE(btr_individual.minimum_hours, 0)
          THEN btr_individual.rate
          WHEN btr_general.rate IS NOT NULL 
               AND ahd.hours >= COALESCE(btr_general.minimum_hours, 0)
          THEN btr_general.rate
          ELSE 0
        END
      ) as total_trip
    FROM (
      -- Часы из смен
      SELECT 
        wh.employee_id AS emp_id,
        wh.hours,
        w.object_id AS obj_id,
        w.date as work_date
      FROM work_hours wh
      JOIN works w ON wh.work_id = w.id
      WHERE w.status = 'closed'
        AND w.object_id IS NOT NULL
      
      UNION ALL
      
      -- Часы из ручного ввода
      SELECT 
        ea.employee_id AS emp_id,
        ea.hours,
        ea.object_id AS obj_id,
        ea.date as work_date
      FROM employee_attendance ea
      WHERE ea.object_id IS NOT NULL
    ) ahd
    
    LEFT JOIN business_trip_rates btr_individual
      ON btr_individual.object_id = ahd.obj_id
      AND btr_individual.employee_id = ahd.emp_id
      AND ahd.work_date >= btr_individual.valid_from
      AND (btr_individual.valid_to IS NULL OR ahd.work_date <= btr_individual.valid_to)
    
    LEFT JOIN business_trip_rates btr_general
      ON btr_general.object_id = ahd.obj_id
      AND btr_general.employee_id IS NULL
      AND ahd.work_date >= btr_general.valid_from
      AND (btr_general.valid_to IS NULL OR ahd.work_date <= btr_general.valid_to)
    
    GROUP BY ahd.emp_id
  ),
  
  -- 3. Премии за всё время
  bonus_calc AS (
    SELECT 
      pb.employee_id AS emp_id,
      COALESCE(SUM(pb.amount), 0) as total_bonus
    FROM payroll_bonus pb
    GROUP BY pb.employee_id
  ),
  
  -- 4. Штрафы за всё время
  penalty_calc AS (
    SELECT 
      pp.employee_id AS emp_id,
      COALESCE(SUM(pp.amount), 0) as total_penalty
    FROM payroll_penalty pp
    GROUP BY pp.employee_id
  ),
  
  -- 5. Выплаты за всё время
  payout_calc AS (
    SELECT 
      po.employee_id AS emp_id,
      COALESCE(SUM(po.amount), 0) as total_payout
    FROM payroll_payout po
    GROUP BY po.employee_id
  ),
  
  -- 6. Все сотрудники с транзакциями
  all_employees AS (
    SELECT DISTINCT emp_id FROM base_salary_calc
    UNION
    SELECT DISTINCT emp_id FROM trip_calc
    UNION
    SELECT DISTINCT emp_id FROM bonus_calc
    UNION
    SELECT DISTINCT emp_id FROM penalty_calc
    UNION
    SELECT DISTINCT emp_id FROM payout_calc
  )
  
  -- Финальный расчёт баланса
  SELECT 
    ae.emp_id,
    (COALESCE(bs.total_base, 0) +
     COALESCE(tc.total_trip, 0) +
     COALESCE(bc.total_bonus, 0) -
     COALESCE(pc.total_penalty, 0) -
     COALESCE(po.total_payout, 0))::NUMERIC
  FROM all_employees ae
  LEFT JOIN base_salary_calc bs ON ae.emp_id = bs.emp_id
  LEFT JOIN trip_calc tc ON ae.emp_id = tc.emp_id
  LEFT JOIN bonus_calc bc ON ae.emp_id = bc.emp_id
  LEFT JOIN penalty_calc pc ON ae.emp_id = pc.emp_id
  LEFT JOIN payout_calc po ON ae.emp_id = po.emp_id;
END;
$$;

COMMENT ON FUNCTION calculate_employee_balances() IS 
'Быстро рассчитывает баланс (к выплате - выплачено) для всех сотрудников одним запросом. Включает work_hours, employee_attendance, бонусы, штрафы, суточные с учётом индивидуальных и общих ставок, и выплаты. Используется для мгновенного обновления колонки Баланс в модуле ФОТ.';


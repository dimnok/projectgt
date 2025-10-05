-- Миграция: Оптимизация расчётов ФОТ
-- Дата: 2025-10-04
-- Описание: Создание PostgreSQL функции для батч-расчёта ФОТ за месяц

-- =====================================================
-- Функция: calculate_payroll_for_month
-- Назначение: Рассчитывает ФОТ для всех сотрудников за указанный месяц
-- Возвращает: Таблицу с расчётами по каждому сотруднику
-- =====================================================

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
  -- 1. Базовая зарплата (часы × ставка с учётом истории)
  base_calc AS (
    SELECT 
      wh.employee_id,
      SUM(wh.hours) as hours,
      SUM(wh.hours * COALESCE(
        (SELECT hourly_rate 
         FROM employee_rates er 
         WHERE er.employee_id = wh.employee_id 
           AND w.date >= er.valid_from 
           AND (er.valid_to IS NULL OR w.date <= er.valid_to)
         ORDER BY er.valid_from DESC
         LIMIT 1), 0)
      ) as base_sal
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE EXTRACT(YEAR FROM w.date) = p_year
      AND EXTRACT(MONTH FROM w.date) = p_month
    GROUP BY wh.employee_id
  ),
  
  -- 2. Командировочные выплаты
  trip_calc AS (
    SELECT 
      wh.employee_id,
      SUM(COALESCE(
        (SELECT rate 
         FROM business_trip_rates btr 
         WHERE btr.object_id = w.object_id 
           AND w.date >= btr.valid_from 
           AND (btr.valid_to IS NULL OR w.date <= btr.valid_to)
         ORDER BY btr.valid_from DESC
         LIMIT 1), 0)
      ) as trip_total
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE EXTRACT(YEAR FROM w.date) = p_year
      AND EXTRACT(MONTH FROM w.date) = p_month
      AND w.object_id IS NOT NULL
    GROUP BY wh.employee_id
  ),
  
  -- 3. Премии за месяц
  bonus_calc AS (
    SELECT 
      employee_id,
      COALESCE(SUM(amount), 0) as bonuses
    FROM payroll_bonus
    WHERE EXTRACT(YEAR FROM date) = p_year
      AND EXTRACT(MONTH FROM date) = p_month
    GROUP BY employee_id
  ),
  
  -- 4. Штрафы за месяц
  penalty_calc AS (
    SELECT 
      employee_id,
      COALESCE(SUM(amount), 0) as penalties
    FROM payroll_penalty
    WHERE EXTRACT(YEAR FROM date) = p_year
      AND EXTRACT(MONTH FROM date) = p_month
    GROUP BY employee_id
  ),
  
  -- 5. Текущая ставка сотрудника (для отображения)
  current_rates AS (
    SELECT DISTINCT ON (er.employee_id)
      er.employee_id,
      er.hourly_rate as current_rate
    FROM employee_rates er
    WHERE er.valid_from <= CURRENT_DATE
      AND (er.valid_to IS NULL OR er.valid_to >= CURRENT_DATE)
    ORDER BY er.employee_id, er.valid_from DESC
  )
  
  -- Финальный расчёт: объединяем все компоненты
  SELECT 
    e.id,
    e.full_name,
    COALESCE(bc.hours, 0)::NUMERIC,
    COALESCE(bc.base_sal, 0)::NUMERIC,
    COALESCE(tc.trip_total, 0)::NUMERIC,
    COALESCE(bonus.bonuses, 0)::NUMERIC,
    COALESCE(pen.penalties, 0)::NUMERIC,
    (COALESCE(bc.base_sal, 0) + 
     COALESCE(tc.trip_total, 0) + 
     COALESCE(bonus.bonuses, 0) - 
     COALESCE(pen.penalties, 0))::NUMERIC as net_salary,
    COALESCE(cr.current_rate, 0)::NUMERIC
  FROM employees e
  LEFT JOIN base_calc bc ON e.id = bc.employee_id
  LEFT JOIN trip_calc tc ON e.id = tc.employee_id
  LEFT JOIN bonus_calc bonus ON e.id = bonus.employee_id
  LEFT JOIN penalty_calc pen ON e.id = pen.employee_id
  LEFT JOIN current_rates cr ON e.id = cr.employee_id
  WHERE bc.employee_id IS NOT NULL  -- Только сотрудники с отработанными часами
  ORDER BY e.full_name;
END;
$$;

-- Комментарий к функции
COMMENT ON FUNCTION calculate_payroll_for_month(INT, INT) IS 
'Рассчитывает ФОТ для всех сотрудников за указанный месяц. Включает базовую зарплату, командировочные, премии и штрафы.';

-- Пример использования:
-- SELECT * FROM calculate_payroll_for_month(2025, 10);


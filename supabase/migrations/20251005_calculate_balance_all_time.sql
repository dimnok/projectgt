-- Миграция: Функции для расчёта накопительного баланса за всё время
-- Дата: 05.10.2025
-- Описание: Создаём функции для расчёта baseSalary и businessTrip за всю историю

-- ============================================================================
-- Функция 1: Расчёт базовой зарплаты (work_hours * hourly_rate) за всё время
-- ============================================================================
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
  WITH work_hours_data AS (
    -- Получаем все отработанные часы с датами смен
    SELECT 
      wh.employee_id,
      wh.hours,
      w.date as work_date
    FROM work_hours wh
    INNER JOIN works w ON wh.work_id = w.id
    WHERE w.status = 'closed' -- Только закрытые смены
      AND wh.hours IS NOT NULL
      AND wh.hours > 0
  ),
  rates_with_dates AS (
    -- Получаем исторические ставки сотрудников
    SELECT 
      er.employee_id,
      er.hourly_rate,
      er.valid_from,
      COALESCE(er.valid_to, '9999-12-31'::DATE) as valid_to
    FROM employee_rates er
  ),
  calculated_salaries AS (
    -- Считаем базовую зарплату для каждой смены с учётом исторической ставки
    SELECT 
      whd.employee_id,
      SUM(whd.hours * COALESCE(rwd.hourly_rate, 0)) as total_base_salary
    FROM work_hours_data whd
    LEFT JOIN rates_with_dates rwd 
      ON whd.employee_id = rwd.employee_id
      AND whd.work_date >= rwd.valid_from
      AND whd.work_date <= rwd.valid_to
    GROUP BY whd.employee_id
  )
  SELECT 
    cs.employee_id,
    COALESCE(cs.total_base_salary, 0) as base_salary
  FROM calculated_salaries cs;
END;
$$;

COMMENT ON FUNCTION calculate_base_salary_all_time IS 'Рассчитывает базовую зарплату (work_hours * hourly_rate) за всё время с учётом исторических ставок';

-- ============================================================================
-- Функция 2: Расчёт суточных (business trip) за всё время
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_business_trip_all_time()
RETURNS TABLE (
  employee_id UUID,
  trip_total NUMERIC
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH work_hours_data AS (
    -- Получаем все смены с объектами
    SELECT 
      wh.employee_id,
      wh.hours,
      w.object_id,
      w.date as work_date
    FROM work_hours wh
    INNER JOIN works w ON wh.work_id = w.id
    WHERE w.status = 'closed' -- Только закрытые смены
      AND w.object_id IS NOT NULL
      AND wh.hours IS NOT NULL
  ),
  trip_rates_calc AS (
    -- Применяем ставки суточных с учётом приоритета индивидуальных ставок
    SELECT 
      whd.employee_id,
      SUM(
        CASE
          -- Приоритет 1: Индивидуальная ставка для сотрудника (если hours >= minimum_hours)
          WHEN btr_individual.rate IS NOT NULL 
               AND whd.hours >= COALESCE(btr_individual.minimum_hours, 0)
          THEN btr_individual.rate
          
          -- Приоритет 2: Общая ставка для объекта (если hours >= minimum_hours)
          WHEN btr_general.rate IS NOT NULL 
               AND whd.hours >= COALESCE(btr_general.minimum_hours, 0)
          THEN btr_general.rate
          
          -- Иначе 0
          ELSE 0
        END
      ) as total_trip
    FROM work_hours_data whd
    
    -- LEFT JOIN для индивидуальных ставок
    LEFT JOIN business_trip_rates btr_individual
      ON btr_individual.object_id = whd.object_id
      AND btr_individual.employee_id = whd.employee_id
      AND whd.work_date >= btr_individual.valid_from
      AND (btr_individual.valid_to IS NULL OR whd.work_date <= btr_individual.valid_to)
    
    -- LEFT JOIN для общих ставок (employee_id IS NULL)
    LEFT JOIN business_trip_rates btr_general
      ON btr_general.object_id = whd.object_id
      AND btr_general.employee_id IS NULL
      AND whd.work_date >= btr_general.valid_from
      AND (btr_general.valid_to IS NULL OR whd.work_date <= btr_general.valid_to)
    
    GROUP BY whd.employee_id
  )
  SELECT 
    trc.employee_id,
    COALESCE(trc.total_trip, 0) as trip_total
  FROM trip_rates_calc trc;
END;
$$;

COMMENT ON FUNCTION calculate_business_trip_all_time IS 'Рассчитывает суточные за всё время с учётом индивидуальных и общих ставок, minimum_hours';

-- ============================================================================
-- Права доступа
-- ============================================================================
GRANT EXECUTE ON FUNCTION calculate_base_salary_all_time TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_business_trip_all_time TO authenticated;


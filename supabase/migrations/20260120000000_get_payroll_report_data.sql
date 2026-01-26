-- Миграция: Функция для формирования данных отчета ФОТ
-- Описание: Собирает начисления, выплаты (FIFO) и балансы для всех активных сотрудников

CREATE OR REPLACE FUNCTION get_payroll_report_data(
  p_year INT,
  p_month INT,
  p_company_id UUID
)
RETURNS TABLE (
  employee_id UUID,
  full_name TEXT,
  hours_worked NUMERIC,
  hourly_rate NUMERIC,
  base_salary NUMERIC,
  bonuses_total NUMERIC,
  penalties_total NUMERIC,
  business_trip_total NUMERIC,
  net_salary NUMERIC,
  payouts_for_month NUMERIC,
  balance_all_time NUMERIC
) 
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_period_start DATE := TO_DATE(p_year || '-' || p_month || '-01', 'YYYY-MM-DD');
BEGIN
  RETURN QUERY
  WITH 
  -- 1. Все сотрудники компании
  all_company_employees AS (
    SELECT e.id, CONCAT(e.last_name, ' ', e.first_name, ' ', COALESCE(e.middle_name, '')) as f_name
    FROM employees e
    WHERE e.company_id = p_company_id
  ),

  -- 2. Все начисления (аккумулируем из всех источников)
  all_accruals_raw AS (
    -- Смены
    SELECT 
      wh.employee_id,
      w.date,
      wh.hours,
      (wh.hours * COALESCE(
        (SELECT er.hourly_rate FROM employee_rates er 
         WHERE er.employee_id = wh.employee_id AND w.date >= er.valid_from 
         AND (er.valid_to IS NULL OR w.date <= er.valid_to)
         ORDER BY er.valid_from DESC LIMIT 1), 0)) as base_val,
      COALESCE(
        (SELECT rate FROM business_trip_rates btr 
         WHERE btr.object_id = w.object_id AND (btr.employee_id = wh.employee_id OR btr.employee_id IS NULL)
         AND w.date >= btr.valid_from AND (btr.valid_to IS NULL OR w.date <= btr.valid_to)
         AND wh.hours >= COALESCE(btr.minimum_hours, 0)
         ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1), 0) as trip_val
    FROM work_hours wh
    JOIN works w ON wh.work_id = w.id
    WHERE w.company_id = p_company_id AND w.status = 'closed'
    
    UNION ALL
    
    -- Ручной ввод
    SELECT 
      ea.employee_id,
      ea.date,
      ea.hours,
      (ea.hours * COALESCE(
        (SELECT er.hourly_rate FROM employee_rates er 
         WHERE er.employee_id = ea.employee_id AND ea.date >= er.valid_from 
         AND (er.valid_to IS NULL OR ea.date <= er.valid_to)
         ORDER BY er.valid_from DESC LIMIT 1), 0)) as base_val,
      COALESCE(
        (SELECT rate FROM business_trip_rates btr 
         WHERE btr.object_id = ea.object_id AND (btr.employee_id = ea.employee_id OR btr.employee_id IS NULL)
         AND ea.date >= btr.valid_from AND (btr.valid_to IS NULL OR ea.date <= btr.valid_to)
         AND ea.hours >= COALESCE(btr.minimum_hours, 0)
         ORDER BY btr.employee_id NULLS LAST, btr.valid_from DESC LIMIT 1), 0) as trip_val
    FROM employee_attendance ea
    WHERE ea.company_id = p_company_id
  ),

  -- 3. Агрегация начислений по периодам
  accruals_monthly AS (
    SELECT 
      emp_id,
      -- Текущий месяц
      SUM(CASE WHEN date_trunc('month', date) = v_period_start THEN hours ELSE 0 END) as cur_hours,
      SUM(CASE WHEN date_trunc('month', date) = v_period_start THEN base_val ELSE 0 END) as cur_base,
      SUM(CASE WHEN date_trunc('month', date) = v_period_start THEN trip_val ELSE 0 END) as cur_trip,
      -- Все начисления (для FIFO и Баланса)
      SUM(base_val + trip_val) as total_accrued_base_trip,
      -- Начисления строго ДО текущего месяца
      SUM(CASE WHEN date < v_period_start THEN base_val + trip_val ELSE 0 END) as accrued_before
    FROM (SELECT employee_id as emp_id, date, hours, base_val, trip_val FROM all_accruals_raw) as t
    GROUP BY emp_id
  ),

  -- 4. Бонусы и штрафы
  extras AS (
    SELECT 
      employee_id,
      SUM(CASE WHEN date_trunc('month', date) = v_period_start THEN amount ELSE 0 END) FILTER (WHERE type = 'bonus') as cur_bonus,
      SUM(CASE WHEN date_trunc('month', date) = v_period_start THEN amount ELSE 0 END) FILTER (WHERE type = 'penalty') as cur_penalty,
      SUM(amount) FILTER (WHERE type = 'bonus') as total_bonus,
      SUM(amount) FILTER (WHERE type = 'penalty') as total_penalty,
      SUM(amount) FILTER (WHERE type = 'bonus' AND date < v_period_start) as bonus_before,
      SUM(amount) FILTER (WHERE type = 'penalty' AND date < v_period_start) as penalty_before
    FROM (
      SELECT employee_id, date, amount, 'bonus' as type FROM payroll_bonus WHERE company_id = p_company_id
      UNION ALL
      SELECT employee_id, date, amount, 'penalty' as type FROM payroll_penalty WHERE company_id = p_company_id
    ) as t
    GROUP BY employee_id
  ),

  -- 5. Выплаты
  payouts AS (
    SELECT 
      employee_id,
      COALESCE(SUM(amount), 0) as total_paid
    FROM payroll_payout
    WHERE company_id = p_company_id
    GROUP BY employee_id
  ),

  -- 6. Сборка финальных показателей
  final_calc AS (
    SELECT 
      ae.id as emp_id,
      ae.f_name,
      COALESCE(am.cur_hours, 0) as h_worked,
      COALESCE(am.cur_base, 0) as b_salary,
      COALESCE(am.cur_trip, 0) as t_trip,
      COALESCE(ex.cur_bonus, 0) as b_total,
      COALESCE(ex.cur_penalty, 0) as p_total,
      -- Чистое начисление за месяц
      (COALESCE(am.cur_base, 0) + COALESCE(am.cur_trip, 0) + COALESCE(ex.cur_bonus, 0) - COALESCE(ex.cur_penalty, 0)) as net_val,
      -- Данные для FIFO
      COALESCE(p.total_paid, 0) as total_paid,
      (COALESCE(am.accrued_before, 0) + COALESCE(ex.bonus_before, 0) - COALESCE(ex.penalty_before, 0)) as accrued_before_month,
      -- Общий баланс
      (COALESCE(am.total_accrued_base_trip, 0) + COALESCE(ex.total_bonus, 0) - COALESCE(ex.total_penalty, 0) - COALESCE(p.total_paid, 0)) as total_balance
    FROM all_company_employees ae
    LEFT JOIN accruals_monthly am ON ae.id = am.emp_id
    LEFT JOIN extras ex ON ae.id = ex.employee_id
    LEFT JOIN payouts p ON ae.id = p.employee_id
  )

  SELECT 
    fc.emp_id,
    fc.f_name,
    fc.h_worked::NUMERIC,
    COALESCE((SELECT er.hourly_rate FROM employee_rates er WHERE er.employee_id = fc.emp_id AND er.valid_from <= CURRENT_DATE ORDER BY er.valid_from DESC LIMIT 1), 0)::NUMERIC as h_rate,
    fc.b_salary::NUMERIC,
    fc.b_total::NUMERIC,
    fc.p_total::NUMERIC,
    fc.t_trip::NUMERIC,
    fc.net_val::NUMERIC,
    -- FIFO Распределение выплат: max(0, min(net_val, total_paid - accrued_before_month))
    GREATEST(0, LEAST(fc.net_val, fc.total_paid - fc.accrued_before_month))::NUMERIC as p_month,
    fc.total_balance::NUMERIC
  FROM final_calc fc
  WHERE ABS(fc.h_worked) > 0.001 
     OR ABS(fc.b_total) > 0.001 
     OR ABS(fc.p_total) > 0.001 
     OR ABS(fc.t_trip) > 0.001
     OR ABS(fc.total_balance) > 0.01
  ORDER BY fc.f_name;
END;
$$;

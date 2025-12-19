-- 1. Функция для получения сгруппированного списка смет (Sidebar)
-- Работает быстро за счет индексов, возвращает только заголовки и суммы.
CREATE OR REPLACE FUNCTION get_estimate_groups()
RETURNS TABLE (
  estimate_title TEXT,
  object_id UUID,
  contract_id UUID,
  items_count BIGINT,
  total_amount NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(e.estimate_title, 'Без названия') as estimate_title,
    e.object_id,
    e.contract_id,
    COUNT(*) as items_count,
    COALESCE(SUM(e.total), 0) as total_amount
  FROM estimates e
  GROUP BY e.estimate_title, e.object_id, e.contract_id
  ORDER BY e.estimate_title;
END;
$$ LANGUAGE plpgsql STABLE;

-- 2. Функция для точечного получения выполнения по списку ID сметных позиций
-- Исправлено: join с work_items вместо works
CREATE OR REPLACE FUNCTION get_estimate_completion_by_ids(
  p_estimate_ids UUID[]
)
RETURNS JSONB AS $$
DECLARE
  v_data JSONB;
BEGIN
  SELECT JSONB_AGG(t.*)
  INTO v_data
  FROM (
    SELECT
      e.id AS estimate_id,
      e.object_id,
      e.contract_id,
      e.system,
      e.subsystem,
      COALESCE(e.number::TEXT, '') AS number,
      COALESCE(e.name, '') AS name,
      COALESCE(e.unit, '') AS unit,
      COALESCE(e.quantity, 0.0) AS quantity,
      COALESCE(e.total, 0.0) AS total,
      -- Суммируем выполнение из таблицы work_items (детали работ)
      COALESCE(SUM(wi.quantity), 0.0) AS completed_quantity,
      COALESCE(SUM(wi.total), 0.0) AS completed_total,
      CASE 
        WHEN COALESCE(e.quantity, 0) = 0 THEN 0
        ELSE (COALESCE(SUM(wi.quantity), 0.0) / COALESCE(e.quantity, 1)) * 100
      END AS percentage,
      COALESCE(e.quantity, 0) - COALESCE(SUM(wi.quantity), 0.0) AS remaining_quantity
    FROM estimates e
    LEFT JOIN work_items wi ON e.id = wi.estimate_id
    WHERE e.id = ANY(p_estimate_ids)
    GROUP BY e.id
  ) t;

  RETURN COALESCE(v_data, '[]'::JSONB);
END;
$$ LANGUAGE plpgsql STABLE;

-- Обновленный индекс для поддержки группировки
CREATE INDEX IF NOT EXISTS idx_estimates_grouping 
ON estimates(estimate_title, object_id, contract_id);

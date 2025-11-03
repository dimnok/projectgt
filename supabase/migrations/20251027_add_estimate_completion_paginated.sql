-- Функция для получения пагинированного отчёта о выполнении смет
-- Поддерживает миллионы строк с infinite scroll
-- Сортировка на БД (система → подсистема → номер)

CREATE OR REPLACE FUNCTION get_estimate_completion_paginated(
  p_offset INT DEFAULT 0,
  p_limit INT DEFAULT 50,
  p_object_ids UUID[] DEFAULT NULL,
  p_contract_ids UUID[] DEFAULT NULL,
  p_systems TEXT[] DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_total_count INT;
  v_data JSONB;
  v_has_next BOOLEAN;
BEGIN
  -- Получаем ТОЛЬКО количество записей (для определения has_next)
  SELECT COUNT(*)
  INTO v_total_count
  FROM estimates e
  WHERE 
    (p_object_ids IS NULL OR e.object_id = ANY(p_object_ids))
    AND (p_contract_ids IS NULL OR e.contract_id = ANY(p_contract_ids))
    AND (p_systems IS NULL OR e.system = ANY(p_systems));

  -- Проверяем есть ли ещё данные после текущей страницы
  v_has_next := (p_offset + p_limit) < v_total_count;

  -- Получаем данные ЭТОЙ страницы с сортировкой на БД
  SELECT COALESCE(JSONB_AGG(row_to_json(t.*) ORDER BY t.system, t.subsystem, t.number), '[]'::JSONB)
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
      COALESCE(SUM(w.completed_quantity), 0.0) AS completed_quantity,
      COALESCE(SUM(w.completed_cost), 0.0) AS completed_total,
      CASE 
        WHEN COALESCE(e.quantity, 0) = 0 THEN 0
        ELSE ROUND((COALESCE(SUM(w.completed_quantity), 0.0) / COALESCE(e.quantity, 1)) * 100)
      END AS percentage,
      COALESCE(e.quantity, 0) - COALESCE(SUM(w.completed_quantity), 0.0) AS remaining_quantity
    FROM estimates e
    LEFT JOIN works w ON e.id = w.estimate_id
    WHERE 
      (p_object_ids IS NULL OR e.object_id = ANY(p_object_ids))
      AND (p_contract_ids IS NULL OR e.contract_id = ANY(p_contract_ids))
      AND (p_systems IS NULL OR e.system = ANY(p_systems))
    GROUP BY e.id, e.object_id, e.contract_id, e.system, e.subsystem, e.number, e.name, e.unit, e.quantity, e.total
    ORDER BY e.system, e.subsystem, e.number
    LIMIT p_limit
    OFFSET p_offset
  ) t;

  RETURN JSONB_BUILD_OBJECT(
    'data', COALESCE(v_data, '[]'::JSONB),
    'total_count', v_total_count,
    'has_next', v_has_next
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- Индекс для оптимизации фильтрации по object_id, contract_id
CREATE INDEX IF NOT EXISTS idx_estimates_filters 
ON estimates(object_id, contract_id, system);

-- Индекс для сортировки
CREATE INDEX IF NOT EXISTS idx_estimates_sort 
ON estimates(system, subsystem, number);

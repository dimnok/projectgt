-- Миграция: Строгая привязка материалов к договорам в FIFO
-- Дата: 6 октября 2025
-- Описание: Исправление логики списания материалов - FIFO теперь работает только внутри договора

-- ============================================================================
-- Шаг 1: Удаление старых объектов
-- ============================================================================

DROP VIEW IF EXISTS public.v_materials_with_usage CASCADE;
DROP FUNCTION IF EXISTS public.v_materials_usage_period CASCADE;

-- ============================================================================
-- Шаг 2: Создание нового представления v_materials_with_usage
-- ============================================================================

CREATE VIEW public.v_materials_with_usage AS
WITH norm_aliases AS (
  SELECT 
    lower(regexp_replace(translate(ma.alias_raw, 'Мм', 'mm'), '\s+', ' ', 'g')) AS normalized_name,
    ma.estimate_id
  FROM material_aliases ma
),
used_by_estimate AS (
  SELECT 
    wi.estimate_id,
    COALESCE(sum(wi.quantity), 0::numeric) AS used_qty
  FROM work_items wi
  WHERE wi.estimate_id IS NOT NULL
  GROUP BY wi.estimate_id
),
norm_materials AS (
  SELECT 
    m.id,
    m.name,
    m.unit,
    m.quantity,
    m.price,
    m.total,
    m.receipt_number,
    m.receipt_date,
    m.file_url,
    m.contract_number,
    lower(regexp_replace(translate(m.name, 'Мм', 'mm'), '\s+', ' ', 'g')) AS normalized_name
  FROM materials m
),
material_estimate AS (
  SELECT 
    nm.id,
    nm.name,
    nm.unit,
    nm.quantity,
    nm.price,
    nm.total,
    nm.receipt_number,
    nm.receipt_date,
    nm.file_url,
    nm.contract_number,
    nm.normalized_name,
    -- ИСПРАВЛЕНО: Ищем estimate_id ТОЛЬКО из того же договора, что и материал
    (
      SELECT na.estimate_id
      FROM norm_aliases na
      JOIN estimates e ON e.id = na.estimate_id
      JOIN contracts c ON c.id = e.contract_id
      WHERE na.normalized_name = nm.normalized_name
        AND c.number = nm.contract_number
      LIMIT 1
    ) AS estimate_id
  FROM norm_materials nm
),
me_fifo AS (
  SELECT 
    mef.id,
    mef.name,
    mef.unit,
    mef.quantity,
    mef.price,
    mef.total,
    mef.receipt_number,
    mef.receipt_date,
    mef.file_url,
    mef.contract_number,
    mef.normalized_name,
    mef.estimate_id,
    COALESCE(mef.quantity, 0) AS qty,
    -- ИЗМЕНЕНО: PARTITION теперь по estimate_id И contract_number
    sum(COALESCE(mef.quantity, 0)) OVER (
      PARTITION BY mef.estimate_id, mef.contract_number
      ORDER BY mef.receipt_date, mef.id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS prev_cum_qty,
    row_number() OVER (
      PARTITION BY mef.estimate_id, mef.contract_number
      ORDER BY mef.receipt_date, mef.id
    ) AS rn,
    count(*) OVER (
      PARTITION BY mef.estimate_id, mef.contract_number
    ) AS cnt
  FROM material_estimate me
)
SELECT 
  mef.id,
  mef.name,
  mef.unit,
  mef.quantity,
  mef.price,
  mef.total,
  mef.receipt_number,
  mef.receipt_date,
  mef.file_url,
  mef.contract_number,
  GREATEST(0, LEAST(
    COALESCE(mef.qty, 0),
    COALESCE(ube.used_qty, 0) - COALESCE(mef.prev_cum_qty, 0)
  )) AS used,
  CASE
    WHEN mef.quantity IS NULL THEN NULL
    WHEN mef.estimate_id IS NOT NULL AND mef.rn = mef.cnt THEN
      COALESCE(mef.quantity, 0) - GREATEST(0,
        COALESCE(ube.used_qty, 0) - COALESCE(mef.prev_cum_qty, 0)
      )
    ELSE
      COALESCE(mef.quantity, 0) - GREATEST(0, LEAST(
        COALESCE(mef.qty, 0),
        COALESCE(ube.used_qty, 0) - COALESCE(mef.prev_cum_qty, 0)
      ))
  END AS remaining,
  mef.estimate_id
FROM me_fifo mef
LEFT JOIN used_by_estimate ube ON ube.estimate_id = mef.estimate_id;

-- ============================================================================
-- Шаг 3: Создание новой функции v_materials_usage_period
-- ============================================================================

CREATE FUNCTION public.v_materials_usage_period(
  in_date_start date,
  in_date_end date,
  in_contract_number text DEFAULT NULL
)
RETURNS TABLE (
  material_id uuid,
  name text,
  unit text,
  receipt_number text,
  receipt_date date,
  quantity numeric,
  price numeric,
  total numeric,
  used_period numeric,
  remaining_end numeric,
  used_total numeric,
  estimate_id uuid,
  estimate_number text,
  estimate_name text,
  file_url text
)
LANGUAGE sql
AS $$
WITH norm_aliases AS (
  SELECT 
    lower(regexp_replace(translate(ma.alias_raw, 'Мм', 'mm'), '\s+', ' ', 'g')) AS n,
    ma.estimate_id
  FROM public.material_aliases ma
),
norm_materials AS (
  SELECT 
    m.id, m.name, m.unit, m.quantity, m.price, m.total,
    m.receipt_number, m.receipt_date, m.file_url, m.contract_number,
    lower(regexp_replace(translate(m.name, 'Мм', 'mm'), '\s+', ' ', 'g')) AS n
  FROM public.materials m
  WHERE (in_contract_number IS NULL OR m.contract_number = in_contract_number)
),
material_estimate AS (
  SELECT 
    nm.*,
    -- ИСПРАВЛЕНО: Ищем estimate ТОЛЬКО из того же договора, что и материал
    (
      SELECT na.estimate_id 
      FROM norm_aliases na 
      JOIN estimates e ON e.id = na.estimate_id
      JOIN contracts c ON c.id = e.contract_id
      WHERE na.n = nm.n
        AND c.number = nm.contract_number
      LIMIT 1
    ) AS estimate_id
  FROM norm_materials nm
),
wi_sum_end AS (
  SELECT 
    wi.estimate_id, 
    COALESCE(SUM(wi.quantity), 0)::numeric AS used_qty
  FROM public.work_items wi
  WHERE wi.estimate_id IS NOT NULL
    AND wi.created_at::date <= in_date_end
  GROUP BY wi.estimate_id
),
wi_sum_start AS (
  SELECT 
    wi.estimate_id, 
    COALESCE(SUM(wi.quantity), 0)::numeric AS used_qty
  FROM public.work_items wi
  WHERE wi.estimate_id IS NOT NULL
    AND wi.created_at::date < in_date_start
  GROUP BY wi.estimate_id
),
me AS (
  SELECT 
    me.id, me.name, me.unit, me.quantity, me.price, me.total,
    me.receipt_number, me.receipt_date,
    me.file_url, me.contract_number, me.estimate_id,
    -- ИЗМЕНЕНО: PARTITION по estimate_id И contract_number
    SUM(COALESCE(me.quantity, 0)) OVER (
      PARTITION BY me.estimate_id, me.contract_number
      ORDER BY me.receipt_date, me.id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS prev_cum
  FROM material_estimate me
  WHERE me.estimate_id IS NOT NULL
),
joined AS (
  SELECT 
    me.*, 
    COALESCE(wse.used_qty, 0) AS used_end, 
    COALESCE(wss.used_qty, 0) AS used_start
  FROM me
  LEFT JOIN wi_sum_end wse ON wse.estimate_id = me.estimate_id
  LEFT JOIN wi_sum_start wss ON wss.estimate_id = me.estimate_id
)
SELECT 
  j.id AS material_id,
  j.name,
  j.unit,
  j.receipt_number,
  j.receipt_date,
  j.quantity,
  j.price,
  j.total,
  GREATEST(0, LEAST(COALESCE(j.quantity, 0), j.used_end - COALESCE(j.prev_cum, 0)))
    - GREATEST(0, LEAST(COALESCE(j.quantity, 0), j.used_start - COALESCE(j.prev_cum, 0))) AS used_period,
  CASE 
    WHEN j.quantity IS NULL THEN NULL::numeric
    ELSE COALESCE(j.quantity, 0) - GREATEST(0, LEAST(COALESCE(j.quantity, 0), j.used_end - COALESCE(j.prev_cum, 0)))
  END AS remaining_end,
  GREATEST(0, LEAST(COALESCE(j.quantity, 0), j.used_end - COALESCE(j.prev_cum, 0))) AS used_total,
  j.estimate_id,
  e.number AS estimate_number,
  e.name AS estimate_name,
  j.file_url
FROM joined j
LEFT JOIN public.estimates e ON e.id = j.estimate_id
ORDER BY j.receipt_date NULLS LAST, j.name ASC
$$;

-- ============================================================================
-- Комментарии
-- ============================================================================

COMMENT ON VIEW public.v_materials_with_usage IS 
'Представление материалов с расчётом использования по методу FIFO. 
ВАЖНО: FIFO применяется СТРОГО в рамках договора - материалы списываются 
только из партий того же договора, к которому относится сметная позиция.';

COMMENT ON FUNCTION public.v_materials_usage_period IS 
'Функция расчёта использования материалов за период по методу FIFO.
ВАЖНО: FIFO применяется СТРОГО в рамках договора - материалы списываются 
только из партий того же договора, к которому относится сметная позиция.';


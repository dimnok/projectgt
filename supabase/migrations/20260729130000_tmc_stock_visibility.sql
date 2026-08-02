-- ТМЦ: синхронизация quantity, расширенный список позиций, остатки по складам.
-- Применено через MCP: tmc_stock_visibility + tmc_stock_list_and_triggers

BEGIN;

CREATE OR REPLACE FUNCTION public.tmc_recalc_item_quantity(p_item_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_accounting TEXT;
  v_qty NUMERIC := 0;
BEGIN
  SELECT accounting_type INTO v_accounting
  FROM public.tmc_items
  WHERE id = p_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF v_accounting = 'quantitative' THEN
    SELECT COALESCE(sum(quantity), 0) INTO v_qty
    FROM public.tmc_balances
    WHERE item_id = p_item_id;
  ELSE
    SELECT COALESCE(count(*)::NUMERIC, 0) INTO v_qty
    FROM public.tmc_units
    WHERE item_id = p_item_id
      AND is_archived = false
      AND status <> 'written_off';
  END IF;

  UPDATE public.tmc_items
  SET quantity = v_qty, updated_at = now()
  WHERE id = p_item_id;
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_recalc_item_quantity(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_recalc_item_quantity(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.tmc_trg_recalc_item_qty()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_item_id UUID;
BEGIN
  v_item_id := COALESCE(NEW.item_id, OLD.item_id);
  IF v_item_id IS NOT NULL THEN
    PERFORM public.tmc_recalc_item_quantity(v_item_id);
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_tmc_balances_recalc_qty ON public.tmc_balances;
CREATE TRIGGER trg_tmc_balances_recalc_qty
AFTER INSERT OR UPDATE OR DELETE ON public.tmc_balances
FOR EACH ROW EXECUTE FUNCTION public.tmc_trg_recalc_item_qty();

DROP TRIGGER IF EXISTS trg_tmc_units_recalc_qty ON public.tmc_units;
CREATE TRIGGER trg_tmc_units_recalc_qty
AFTER INSERT OR UPDATE OR DELETE ON public.tmc_units
FOR EACH ROW EXECUTE FUNCTION public.tmc_trg_recalc_item_qty();

DROP FUNCTION IF EXISTS public.tmc_list_items(UUID, TEXT, UUID, TEXT, TEXT, INT, INT);

CREATE OR REPLACE FUNCTION public.tmc_list_items(
  p_company_id UUID,
  p_search TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_accounting_type TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  category_name TEXT,
  subcategory_name TEXT,
  accounting_type TEXT,
  sku TEXT,
  unit_of_measure TEXT,
  quantity NUMERIC,
  qty_in_stock NUMERIC,
  qty_issued NUMERIC,
  qty_on_object NUMERIC,
  location_summary TEXT,
  unit_price NUMERIC,
  total_cost NUMERIC,
  status TEXT,
  photo_url TEXT,
  delivery_date DATE,
  supplier_name TEXT,
  created_at TIMESTAMPTZ,
  total_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_can_cost BOOLEAN;
BEGIN
  IF NOT (p_company_id IN (SELECT public.get_my_company_ids())) THEN
    RAISE EXCEPTION 'Нет доступа';
  END IF;
  IF NOT public.check_permission(auth.uid(), 'tmc', 'read') THEN
    RAISE EXCEPTION 'Нет права просмотра ТМЦ';
  END IF;
  v_can_cost := public.check_permission(auth.uid(), 'tmc', 'view_cost');

  RETURN QUERY
  WITH stock AS (
    -- Количественный учёт: остатки
    SELECT
      b.item_id,
      COALESCE(sum(b.quantity) FILTER (
        WHERE b.location_type IN ('warehouse', 'office')
      ), 0) AS qty_in_stock,
      COALESCE(sum(b.quantity) FILTER (
        WHERE b.location_type = 'employee'
      ), 0) AS qty_issued,
      COALESCE(sum(b.quantity) FILTER (
        WHERE b.location_type = 'object'
      ), 0) AS qty_on_object
    FROM public.tmc_balances b
    JOIN public.tmc_items i0 ON i0.id = b.item_id
    WHERE i0.company_id = p_company_id
      AND i0.accounting_type = 'quantitative'
    GROUP BY b.item_id

    UNION ALL

    -- Индивидуальный учёт: единицы
    SELECT
      u.item_id,
      COALESCE(count(*) FILTER (
        WHERE u.status = 'in_stock'
      ), 0)::NUMERIC AS qty_in_stock,
      COALESCE(count(*) FILTER (
        WHERE u.status = 'issued'
      ), 0)::NUMERIC AS qty_issued,
      COALESCE(count(*) FILTER (
        WHERE u.status = 'on_object'
      ), 0)::NUMERIC AS qty_on_object
    FROM public.tmc_units u
    JOIN public.tmc_items i0 ON i0.id = u.item_id
    WHERE i0.company_id = p_company_id
      AND i0.accounting_type = 'individual'
      AND u.is_archived = false
      AND u.status <> 'written_off'
    GROUP BY u.item_id
  ),
  locs AS (
    SELECT
      b.item_id,
      string_agg(
        w.name || ': ' || trim(to_char(b.quantity, 'FM999999990.###')),
        ', '
        ORDER BY w.name
      ) AS location_summary
    FROM public.tmc_balances b
    JOIN public.tmc_warehouses w ON w.id = b.warehouse_id
    JOIN public.tmc_items i0 ON i0.id = b.item_id
    WHERE i0.company_id = p_company_id
      AND b.location_type = 'warehouse'
      AND b.quantity > 0
    GROUP BY b.item_id

    UNION ALL

    SELECT
      u.item_id,
      string_agg(
        DISTINCT COALESCE(w.name, o.name, '—'),
        ', '
        ORDER BY COALESCE(w.name, o.name, '—')
      ) AS location_summary
    FROM public.tmc_units u
    LEFT JOIN public.tmc_warehouses w ON w.id = u.warehouse_id
    LEFT JOIN public.objects o ON o.id = u.object_id
    JOIN public.tmc_items i0 ON i0.id = u.item_id
    WHERE i0.company_id = p_company_id
      AND u.is_archived = false
      AND u.status IN ('in_stock', 'on_object')
    GROUP BY u.item_id
  ),
  filtered AS (
    SELECT
      i.id,
      i.name,
      cat.name AS category_name,
      sub.name AS subcategory_name,
      i.accounting_type,
      i.sku,
      i.unit_of_measure,
      COALESCE(s.qty_in_stock, 0) + COALESCE(s.qty_issued, 0) + COALESCE(s.qty_on_object, 0) AS quantity,
      COALESCE(s.qty_in_stock, 0) AS qty_in_stock,
      COALESCE(s.qty_issued, 0) AS qty_issued,
      COALESCE(s.qty_on_object, 0) AS qty_on_object,
      NULLIF(trim(COALESCE(l.location_summary, '')), '') AS location_summary,
      CASE WHEN v_can_cost THEN i.unit_price ELSE NULL END AS unit_price,
      CASE WHEN v_can_cost THEN
        round(
          i.unit_price * (
            COALESCE(s.qty_in_stock, 0) + COALESCE(s.qty_issued, 0) + COALESCE(s.qty_on_object, 0)
          ),
          2
        )
      ELSE NULL END AS total_cost,
      i.status,
      i.photo_url,
      i.delivery_date,
      co.short_name AS supplier_name,
      i.created_at,
      count(*) OVER() AS total_count
    FROM public.tmc_items i
    LEFT JOIN public.tmc_categories cat ON cat.id = i.category_id
    LEFT JOIN public.tmc_categories sub ON sub.id = i.subcategory_id
    LEFT JOIN public.contractors co ON co.id = i.supplier_id
    LEFT JOIN stock s ON s.item_id = i.id
    LEFT JOIN locs l ON l.item_id = i.id
    WHERE i.company_id = p_company_id
      AND i.is_archived = false
      AND (p_category_id IS NULL OR i.category_id = p_category_id OR i.subcategory_id = p_category_id)
      AND (p_status IS NULL OR i.status = p_status)
      AND (p_accounting_type IS NULL OR i.accounting_type = p_accounting_type)
      AND (
        p_search IS NULL OR p_search = ''
        OR i.name ILIKE '%' || p_search || '%'
        OR COALESCE(i.sku, '') ILIKE '%' || p_search || '%'
        OR COALESCE(i.model, '') ILIKE '%' || p_search || '%'
      )
  )
  SELECT *
  FROM filtered
  ORDER BY name
  LIMIT GREATEST(COALESCE(p_limit, 50), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_list_items(
  UUID, TEXT, UUID, TEXT, TEXT, INT, INT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_list_items(
  UUID, TEXT, UUID, TEXT, TEXT, INT, INT
) TO authenticated;
CREATE OR REPLACE FUNCTION public.tmc_list_stock(
  p_company_id UUID,
  p_warehouse_id UUID DEFAULT NULL,
  p_search TEXT DEFAULT NULL
)
RETURNS TABLE (
  item_id UUID,
  item_name TEXT,
  accounting_type TEXT,
  unit_of_measure TEXT,
  warehouse_id UUID,
  warehouse_name TEXT,
  location_type TEXT,
  quantity NUMERIC,
  unit_id UUID,
  inventory_number TEXT,
  unit_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  IF NOT (p_company_id IN (SELECT public.get_my_company_ids())) THEN
    RAISE EXCEPTION 'Нет доступа';
  END IF;
  IF NOT public.check_permission(auth.uid(), 'tmc', 'read') THEN
    RAISE EXCEPTION 'Нет права просмотра ТМЦ';
  END IF;

  RETURN QUERY
  SELECT
    i.id AS item_id,
    i.name AS item_name,
    i.accounting_type,
    i.unit_of_measure,
    b.warehouse_id,
    w.name AS warehouse_name,
    b.location_type,
    b.quantity,
    NULL::UUID AS unit_id,
    NULL::TEXT AS inventory_number,
    NULL::TEXT AS unit_status
  FROM public.tmc_balances b
  JOIN public.tmc_items i ON i.id = b.item_id
  LEFT JOIN public.tmc_warehouses w ON w.id = b.warehouse_id
  WHERE i.company_id = p_company_id
    AND i.is_archived = false
    AND b.location_type IN ('warehouse', 'office')
    AND b.quantity > 0
    AND (p_warehouse_id IS NULL OR b.warehouse_id = p_warehouse_id)
    AND (
      p_search IS NULL OR p_search = ''
      OR i.name ILIKE '%' || p_search || '%'
      OR COALESCE(i.sku, '') ILIKE '%' || p_search || '%'
    )

  UNION ALL

  SELECT
    i.id AS item_id,
    i.name AS item_name,
    i.accounting_type,
    i.unit_of_measure,
    u.warehouse_id,
    w.name AS warehouse_name,
    u.location_type,
    1::NUMERIC AS quantity,
    u.id AS unit_id,
    u.inventory_number,
    u.status AS unit_status
  FROM public.tmc_units u
  JOIN public.tmc_items i ON i.id = u.item_id
  LEFT JOIN public.tmc_warehouses w ON w.id = u.warehouse_id
  WHERE i.company_id = p_company_id
    AND i.is_archived = false
    AND u.is_archived = false
    AND u.status = 'in_stock'
    AND u.location_type IN ('warehouse', 'office')
    AND (p_warehouse_id IS NULL OR u.warehouse_id = p_warehouse_id)
    AND (
      p_search IS NULL OR p_search = ''
      OR i.name ILIKE '%' || p_search || '%'
      OR COALESCE(u.inventory_number, '') ILIKE '%' || p_search || '%'
    )

  ORDER BY warehouse_name NULLS LAST, item_name, inventory_number;
END;
$$;

REVOKE ALL ON FUNCTION public.tmc_list_stock(UUID, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_list_stock(UUID, UUID, TEXT) TO authenticated;

-- Исправление уже существующих карточек
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM public.tmc_items LOOP
    PERFORM public.tmc_recalc_item_quantity(r.id);
  END LOOP;
END $$;
COMMIT;

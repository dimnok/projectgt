-- Фильтр по id позиции в tmc_list_items (для getItem без поиска по имени).
DROP FUNCTION IF EXISTS public.tmc_list_items(UUID, TEXT, UUID, TEXT, TEXT, INT, INT);

CREATE OR REPLACE FUNCTION public.tmc_list_items(
  p_company_id UUID,
  p_search TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_accounting_type TEXT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0,
  p_item_id UUID DEFAULT NULL
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
      AND (p_item_id IS NULL OR i.id = p_item_id)
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
  UUID, TEXT, UUID, TEXT, TEXT, INT, INT, UUID
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tmc_list_items(
  UUID, TEXT, UUID, TEXT, TEXT, INT, INT, UUID
) TO authenticated;

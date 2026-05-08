-- PL/pgSQL: имена OUT из RETURNS TABLE конфликтуют с колонками в top_c (DISTINCT ON / ORDER BY).
-- Квалификация ranked_ecp AS r.

CREATE OR REPLACE FUNCTION public.get_subcontractor_margin_dashboard(
  p_company_id uuid
)
RETURNS TABLE (
  object_id uuid,
  contract_id uuid,
  estimate_title text,
  contractor_id uuid,
  our_amount numeric,
  subcontractor_planned_amount numeric,
  unpriced_lines bigint
)
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF p_company_id IS NULL OR NOT p_company_id IN (SELECT public.get_my_company_ids()) THEN
    RAISE EXCEPTION 'access denied'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  WITH line_data AS (
    SELECT
      e.id AS est_id,
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия') AS estimate_title,
      e.quantity,
      e.total::numeric AS our_line,
      (
        SELECT COALESCE(
          SUM(
            (COALESCE(ecp.contractor_quantity, e.quantity) * (ecp.unit_price)::numeric)
          ),
          0::numeric
        )
        FROM estimate_contractor_prices ecp
        WHERE ecp.estimate_id = e.id
          AND ecp.company_id = p_company_id
          AND ecp.unit_price IS NOT NULL
      ) AS sub_line
    FROM estimates e
    WHERE e.company_id = p_company_id
  ),
  ranked_ecp AS (
    SELECT
      ld.object_id,
      ld.contract_id,
      ld.estimate_title,
      ecp.contractor_id,
      (COALESCE(ecp.contractor_quantity, ld.quantity) * (ecp.unit_price)::numeric) AS line_cost
    FROM line_data ld
    INNER JOIN estimate_contractor_prices ecp ON ecp.estimate_id = ld.est_id
    WHERE ecp.company_id = p_company_id
      AND ecp.unit_price IS NOT NULL
  ),
  top_c AS (
    SELECT DISTINCT ON (r.object_id, r.contract_id, r.estimate_title)
      r.object_id,
      r.contract_id,
      r.estimate_title,
      r.contractor_id
    FROM ranked_ecp r
    ORDER BY
      r.object_id,
      r.contract_id,
      r.estimate_title,
      r.line_cost DESC NULLS LAST
  ),
  agg AS (
    SELECT
      ld.object_id,
      ld.contract_id,
      ld.estimate_title,
      SUM(ld.our_line) AS our_amount,
      SUM(ld.sub_line) AS sub_amount,
      COUNT(*) FILTER (WHERE ld.sub_line = 0::numeric)::bigint AS unpriced_lines
    FROM line_data ld
    GROUP BY ld.object_id, ld.contract_id, ld.estimate_title
  )
  SELECT
    a.object_id,
    a.contract_id,
    a.estimate_title,
    t.contractor_id,
    a.our_amount,
    a.sub_amount AS subcontractor_planned_amount,
    a.unpriced_lines
  FROM agg a
  LEFT JOIN top_c t
    ON t.object_id IS NOT DISTINCT FROM a.object_id
   AND t.contract_id IS NOT DISTINCT FROM a.contract_id
   AND t.estimate_title = a.estimate_title
  ORDER BY
    a.object_id,
    a.contract_id NULLS LAST,
    a.estimate_title;
END;
$$;

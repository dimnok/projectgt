-- Исправление 42804: SUM(work_items.total) давал double precision при total = float8.
-- Явное приведение к numeric для соответствия RETURNS TABLE.

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
  SELECT
    w.object_id,
    e.contract_id,
    COALESCE(e.estimate_title, 'Без названия') AS estimate_title,
    wi.contractor_id,
    COALESCE(
      SUM(COALESCE(wi.total::numeric, 0::numeric)),
      0::numeric
    ) AS our_amount,
    COALESCE(
      SUM(
        CASE
          WHEN ecp.unit_price IS NOT NULL THEN
            (wi.quantity::double precision) * ecp.unit_price
          ELSE
            0::double precision
        END
      )::numeric,
      0::numeric
    ) AS subcontractor_planned_amount,
    COUNT(*) FILTER (WHERE ecp.id IS NULL OR ecp.unit_price IS NULL) AS unpriced_lines
  FROM work_items wi
  INNER JOIN works w
    ON w.id = wi.work_id
   AND w.company_id = p_company_id
  INNER JOIN estimates e
    ON e.id = wi.estimate_id
   AND e.company_id = p_company_id
  LEFT JOIN estimate_contractor_prices ecp
    ON ecp.estimate_id = wi.estimate_id
   AND ecp.contractor_id = wi.contractor_id
   AND ecp.company_id = p_company_id
  WHERE wi.company_id = p_company_id
    AND wi.contractor_id IS NOT NULL
  GROUP BY
    w.object_id,
    e.contract_id,
    COALESCE(e.estimate_title, 'Без названия'),
    wi.contractor_id
  HAVING
    COALESCE(
      SUM(COALESCE(wi.total::numeric, 0::numeric)),
      0::numeric
    ) <> 0::numeric
    OR COALESCE(
      SUM(
        CASE
          WHEN ecp.unit_price IS NOT NULL THEN
            (wi.quantity::double precision) * ecp.unit_price
          ELSE
            0::double precision
        END
      )::numeric,
      0::numeric
    ) <> 0::numeric
  ORDER BY
    w.object_id,
    e.contract_id NULLS LAST,
    COALESCE(e.estimate_title, 'Без названия'),
    wi.contractor_id;
END;
$$;

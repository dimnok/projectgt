-- Исправление 42804: SUM/COALESCE по work_items.total давали double precision при сигнатуре numeric.

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
  unpriced_lines bigint,
  fact_own_amount numeric,
  fact_subcontractor_revenue_amount numeric,
  fact_subcontractor_cost_amount numeric
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
  WITH ecp_sub AS (
    SELECT
      ecp.estimate_id,
      ecp.contractor_id,
      (COALESCE(ecp.contractor_quantity::numeric, e.quantity::numeric) *
        (ecp.unit_price::numeric)
      )::numeric AS part_sub
    FROM estimate_contractor_prices ecp
    INNER JOIN estimates e ON e.id = ecp.estimate_id
    WHERE ecp.company_id = p_company_id
      AND e.company_id = p_company_id
      AND ecp.unit_price IS NOT NULL
  ),
  line_sub_tot AS (
    SELECT
      s.estimate_id,
      SUM(s.part_sub)::numeric AS s_tot
    FROM ecp_sub s
    GROUP BY s.estimate_id
  ),
  line_alloc AS (
    SELECT
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия') AS estimate_title,
      es.contractor_id,
      es.part_sub::numeric AS sub_line
    FROM estimates e
    INNER JOIN ecp_sub es ON es.estimate_id = e.id
    INNER JOIN line_sub_tot lst ON lst.estimate_id = e.id
    WHERE e.company_id = p_company_id
      AND lst.s_tot > 0::numeric
  ),
  group_our AS (
    SELECT
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия') AS estimate_title,
      SUM(e.total::numeric) AS our_group
    FROM estimates e
    WHERE e.company_id = p_company_id
    GROUP BY
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия')
  ),
  fact_groups AS (
    SELECT
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия') AS estimate_title,
      COALESCE(SUM(
        CASE
          WHEN wi.contractor_id IS NULL THEN COALESCE(wi.total::numeric, 0::numeric)
          ELSE 0::numeric
        END
      )::numeric, 0::numeric) AS fact_own,
      COALESCE(SUM(
        CASE
          WHEN wi.contractor_id IS NOT NULL THEN COALESCE(wi.total::numeric, 0::numeric)
          ELSE 0::numeric
        END
      )::numeric, 0::numeric) AS fact_sub_rev,
      COALESCE(SUM(
        CASE
          WHEN wi.contractor_id IS NOT NULL THEN (
            wi.quantity::numeric * COALESCE(
              (
                SELECT ecp.unit_price::numeric
                FROM estimate_contractor_prices ecp
                WHERE ecp.estimate_id = wi.estimate_id
                  AND ecp.contractor_id = wi.contractor_id
                  AND ecp.company_id = p_company_id
                  AND ecp.unit_price IS NOT NULL
                ORDER BY ecp.updated_at DESC NULLS LAST
                LIMIT 1
              ),
              0::numeric
            )
          )::numeric
          ELSE 0::numeric
        END
      )::numeric, 0::numeric) AS fact_sub_cost
    FROM work_items wi
    INNER JOIN estimates e ON e.id = wi.estimate_id
    INNER JOIN works w ON w.id = wi.work_id
    WHERE e.company_id = p_company_id
      AND wi.company_id = p_company_id
      AND w.company_id = p_company_id
      AND w.status = 'closed'
    GROUP BY
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия')
  ),
  by_contractor AS (
    SELECT
      la.object_id,
      la.contract_id,
      la.estimate_title,
      la.contractor_id,
      MAX(g.our_group) AS o_amt,
      COALESCE(SUM(la.sub_line), 0::numeric) AS s_amt,
      0::bigint AS n_unpriced
    FROM line_alloc la
    INNER JOIN group_our g
      ON g.object_id = la.object_id
      AND g.contract_id IS NOT DISTINCT FROM la.contract_id
      AND g.estimate_title = la.estimate_title
    GROUP BY
      la.object_id,
      la.contract_id,
      la.estimate_title,
      la.contractor_id
  ),
  unpriced AS (
    SELECT
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия') AS estimate_title,
      NULL::uuid AS contractor_id,
      SUM(e.total::numeric) AS o_amt,
      0::numeric AS s_amt,
      COUNT(*)::bigint AS n_unpriced
    FROM estimates e
    WHERE e.company_id = p_company_id
      AND NOT EXISTS (
        SELECT 1
        FROM estimate_contractor_prices ecp
        WHERE ecp.estimate_id = e.id
          AND ecp.company_id = p_company_id
          AND ecp.unit_price IS NOT NULL
      )
    GROUP BY
      e.object_id,
      e.contract_id,
      COALESCE(e.estimate_title, 'Без названия')
  ),
  combined AS (
    SELECT
      bc.object_id,
      bc.contract_id,
      bc.estimate_title,
      bc.contractor_id,
      bc.o_amt,
      COALESCE(bc.s_amt, 0::numeric)::numeric AS s_amt,
      bc.n_unpriced
    FROM by_contractor bc
    UNION ALL
    SELECT
      u.object_id,
      u.contract_id,
      u.estimate_title,
      u.contractor_id,
      u.o_amt,
      u.s_amt,
      u.n_unpriced
    FROM unpriced u
  )
  SELECT
    c.object_id,
    c.contract_id,
    c.estimate_title,
    c.contractor_id,
    c.o_amt,
    c.s_amt,
    c.n_unpriced,
    COALESCE(fg.fact_own, 0::numeric)::numeric,
    COALESCE(fg.fact_sub_rev, 0::numeric)::numeric,
    COALESCE(fg.fact_sub_cost, 0::numeric)::numeric
  FROM combined c
  LEFT JOIN fact_groups fg
    ON fg.object_id = c.object_id
    AND fg.contract_id IS NOT DISTINCT FROM c.contract_id
    AND fg.estimate_title = c.estimate_title
  ORDER BY
    c.object_id,
    c.contract_id NULLS LAST,
    c.estimate_title,
    c.contractor_id NULLS FIRST;
END;
$$;

COMMENT ON FUNCTION public.get_subcontractor_margin_dashboard(uuid) IS
  'Сводка по сметам: план (наша сумма, суб по расценкам) и факт по закрытым сменам (свои / выручка суба / оплата суба по расценке).';

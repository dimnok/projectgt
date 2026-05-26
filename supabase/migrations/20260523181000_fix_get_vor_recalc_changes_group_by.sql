-- Исправление GROUP BY в get_vor_recalc_changes (vi.is_extra в агрегате).

BEGIN;

CREATE OR REPLACE FUNCTION public.get_vor_recalc_changes(p_vor_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_status public.vor_status;
    v_contract_id UUID;
    v_start_date DATE;
    v_end_date DATE;
    v_systems TEXT[];
    v_result JSONB;
BEGIN
    SELECT status, contract_id, start_date, end_date
    INTO v_status, v_contract_id, v_start_date, v_end_date
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND OR v_status IS DISTINCT FROM 'draft'::public.vor_status THEN
        RETURN '[]'::jsonb;
    END IF;

    SELECT array_agg(system_name)
    INTO v_systems
    FROM public.vor_systems
    WHERE vor_id = p_vor_id;

    WITH journal AS (
        SELECT
            wi.estimate_id AS estimate_item_id,
            wi.name,
            wi.unit,
            SUM(wi.quantity) AS journal_total,
            CASE
                WHEN wi.estimate_id IS NULL THEN 'Вне сметы'
                ELSE COALESCE(NULLIF(TRIM(e.system), ''), 'Без системы')
            END AS section,
            CASE
                WHEN wi.estimate_id IS NOT NULL AND NULLIF(TRIM(e.number::text), '') IS NOT NULL
                    THEN TRIM(e.number::text) || ' — ' || COALESCE(NULLIF(TRIM(e.name), ''), wi.name)
                ELSE COALESCE(NULLIF(TRIM(wi.name), ''), 'Без наименования')
            END AS row_label
        FROM public.work_items wi
        JOIN public.works w ON wi.work_id = w.id
        LEFT JOIN public.estimates e ON e.id = wi.estimate_id
        WHERE w.date >= v_start_date
          AND w.date <= v_end_date
          AND (v_systems IS NULL OR wi.system = ANY(v_systems))
          AND EXISTS (
              SELECT 1
              FROM public.estimates e2
              WHERE e2.id = wi.estimate_id
                AND e2.contract_id = v_contract_id
          )
        GROUP BY
            wi.estimate_id,
            wi.name,
            wi.unit,
            e.system,
            e.number,
            e.name
    ),
    current_agg AS (
        SELECT
            vi.estimate_item_id,
            vi.name,
            vi.unit,
            SUM(vi.quantity) AS current_total,
            CASE
                WHEN vi.estimate_item_id IS NULL THEN 'Вне сметы'
                ELSE COALESCE(NULLIF(TRIM(e.system), ''), 'Без системы')
            END AS section,
            CASE
                WHEN vi.estimate_item_id IS NOT NULL AND NULLIF(TRIM(e.number::text), '') IS NOT NULL
                    THEN TRIM(e.number::text) || ' — ' || COALESCE(NULLIF(TRIM(e.name), ''), vi.name)
                ELSE COALESCE(NULLIF(TRIM(vi.name), ''), 'Без наименования')
            END AS row_label
        FROM public.vor_items vi
        LEFT JOIN public.estimates e ON e.id = vi.estimate_item_id
        WHERE vi.vor_id = p_vor_id
        GROUP BY vi.estimate_item_id, vi.name, vi.unit, e.system, e.number, e.name
    ),
    changes AS (
        SELECT
            CASE
                WHEN c.current_total IS NULL THEN 'added'
                WHEN j.journal_total IS NULL THEN 'removed'
                ELSE 'modified'
            END AS change_type,
            COALESCE(j.section, c.section) AS section,
            COALESCE(j.row_label, c.row_label) AS row_label,
            COALESCE(j.unit, c.unit) AS unit,
            c.current_total AS old_quantity,
            j.journal_total AS new_quantity
        FROM journal j
        FULL OUTER JOIN current_agg c
            ON j.estimate_item_id IS NOT DISTINCT FROM c.estimate_item_id
           AND j.name = c.name
           AND j.unit = c.unit
        WHERE c.current_total IS NULL
           OR j.journal_total IS NULL
           OR ROUND(j.journal_total::numeric, 6)
                IS DISTINCT FROM ROUND(c.current_total::numeric, 6)
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'change_type', change_type,
                'section', section,
                'row_label', row_label,
                'unit', unit,
                'old_quantity', old_quantity,
                'new_quantity', new_quantity
            )
            ORDER BY section, row_label
        ),
        '[]'::jsonb
    )
    INTO v_result
    FROM changes;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

COMMIT;

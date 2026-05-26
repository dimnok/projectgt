-- Детализация отличий состава черновика ВОР для окна подтверждения пересчёта.

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
    v_result JSONB;
BEGIN
    SELECT status
    INTO v_status
    FROM public.vors
    WHERE id = p_vor_id;

    IF NOT FOUND THEN
        RETURN '[]'::jsonb;
    END IF;

    IF v_status IS DISTINCT FROM 'draft'::public.vor_status THEN
        RETURN '[]'::jsonb;
    END IF;

    WITH expected AS (
        SELECT
            r.estimate_item_id,
            COALESCE(r.name, '') AS name,
            COALESCE(r.unit, '') AS unit,
            r.is_extra,
            r.quantity,
            CASE
                WHEN r.is_extra AND r.estimate_item_id IS NULL THEN 'Вне сметы'
                ELSE COALESCE(NULLIF(TRIM(e.system), ''), 'Без системы')
            END AS section,
            CASE
                WHEN r.estimate_item_id IS NOT NULL AND NULLIF(TRIM(e.number::text), '') IS NOT NULL
                    THEN TRIM(e.number::text) || ' — ' || COALESCE(NULLIF(TRIM(e.name), ''), r.name)
                ELSE COALESCE(NULLIF(TRIM(r.name), ''), 'Без наименования')
            END AS row_label
        FROM public.compute_vor_item_rows(p_vor_id) AS r
        LEFT JOIN public.estimates e ON e.id = r.estimate_item_id
    ),
    current_rows AS (
        SELECT
            vi.estimate_item_id,
            COALESCE(vi.name, '') AS name,
            COALESCE(vi.unit, '') AS unit,
            vi.is_extra,
            vi.quantity,
            CASE
                WHEN vi.is_extra AND vi.estimate_item_id IS NULL THEN 'Вне сметы'
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
    ),
    compared AS (
        SELECT
            COALESCE(e.section, c.section) AS section,
            COALESCE(e.row_label, c.row_label) AS row_label,
            COALESCE(e.unit, c.unit) AS unit,
            COALESCE(e.is_extra, c.is_extra) AS is_extra,
            c.quantity AS old_quantity,
            e.quantity AS new_quantity,
            CASE
                WHEN c.quantity IS NULL THEN 'added'
                WHEN e.quantity IS NULL THEN 'removed'
                ELSE 'modified'
            END AS change_type
        FROM expected e
        FULL OUTER JOIN current_rows c
            ON e.estimate_item_id IS NOT DISTINCT FROM c.estimate_item_id
           AND e.name = c.name
           AND e.unit = c.unit
           AND e.is_extra IS NOT DISTINCT FROM c.is_extra
        WHERE c.quantity IS NULL
           OR e.quantity IS NULL
           OR ROUND(e.quantity::numeric, 6)
                IS DISTINCT FROM ROUND(c.quantity::numeric, 6)
    )
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'change_type', change_type,
                'section', section,
                'row_label', row_label,
                'unit', unit,
                'old_quantity', old_quantity,
                'new_quantity', new_quantity,
                'is_extra', is_extra
            )
            ORDER BY section, row_label
        ),
        '[]'::jsonb
    )
    INTO v_result
    FROM compared;

    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$;

COMMENT ON FUNCTION public.get_vor_recalc_changes(UUID) IS
    'JSON-массив отличий между vor_items и актуальным расчётом для окна пересчёта.';

GRANT EXECUTE ON FUNCTION public.get_vor_recalc_changes(UUID) TO authenticated;

COMMIT;

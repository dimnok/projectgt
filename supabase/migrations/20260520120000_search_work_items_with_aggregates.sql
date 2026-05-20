-- Поиск работ с агрегатами и пагинацией в одном запросе (модуль «Выгрузка»).
-- Старые RPC get_work_items_aggregates и search_work_items_paginated сохранены для совместимости.

CREATE OR REPLACE FUNCTION search_work_items_with_aggregates(
    p_object_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_system_filters TEXT[] DEFAULT NULL,
    p_section_filters TEXT[] DEFAULT NULL,
    p_floor_filters TEXT[] DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,
    p_from INTEGER DEFAULT 0,
    p_to INTEGER DEFAULT 49
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
BEGIN
    WITH filtered_rows AS (
        SELECT
            wi.id AS work_item_id,
            wi.work_id,
            w.date AS work_date,
            w.object_id,
            o.name AS object_name,
            w.status AS work_status,
            wi.system,
            wi.subsystem,
            wi.section,
            wi.floor,
            wi.name AS work_name,
            wi.unit,
            wi.quantity,
            wi.estimate_id,
            e.price,
            e.number AS position_number,
            c.number AS contract_number,
            (
                SELECT string_agg(DISTINCT ma.alias_raw, ', ')
                FROM material_aliases ma
                WHERE ma.estimate_id = wi.estimate_id
            ) AS m15_name
        FROM work_items wi
        JOIN works w ON wi.work_id = w.id
        LEFT JOIN objects o ON w.object_id = o.id
        LEFT JOIN estimates e ON wi.estimate_id = e.id
        LEFT JOIN contracts c ON e.contract_id = c.id
        WHERE w.object_id = p_object_id
          AND (p_start_date IS NULL OR w.date >= p_start_date)
          AND (p_end_date IS NULL OR w.date <= p_end_date)
          AND (
              p_system_filters IS NULL
              OR array_length(p_system_filters, 1) IS NULL
              OR wi.system = ANY (p_system_filters)
          )
          AND (
              p_section_filters IS NULL
              OR array_length(p_section_filters, 1) IS NULL
              OR wi.section = ANY (p_section_filters)
          )
          AND (
              p_floor_filters IS NULL
              OR array_length(p_floor_filters, 1) IS NULL
              OR wi.floor = ANY (p_floor_filters)
          )
          AND (
              p_search_query IS NULL
              OR p_search_query = ''
              OR wi.name ILIKE '%' || p_search_query || '%'
          )
    ),
    aggregates AS (
        SELECT
            COUNT(*)::BIGINT AS total_count,
            COALESCE(SUM(fr.quantity), 0)::NUMERIC AS total_quantity,
            COALESCE(SUM(fr.quantity * fr.price), 0)::NUMERIC AS total_sum
        FROM filtered_rows fr
    ),
    paged AS (
        SELECT fr.*
        FROM filtered_rows fr
        ORDER BY fr.work_date DESC, fr.work_item_id DESC
        OFFSET p_from
        LIMIT GREATEST(p_to - p_from + 1, 0)
    )
    SELECT jsonb_build_object(
        'total_count', (SELECT a.total_count FROM aggregates a),
        'total_quantity', (SELECT a.total_quantity FROM aggregates a),
        'total_sum', (SELECT a.total_sum FROM aggregates a),
        'items', COALESCE(
            (SELECT jsonb_agg(to_jsonb(p) ORDER BY p.work_date DESC, p.work_item_id DESC) FROM paged p),
            '[]'::JSONB
        )
    )
    INTO v_result;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION search_work_items_with_aggregates IS
    'Пагинированный поиск work_items с итогами (count, quantity, sum) в одном ответе JSONB.';

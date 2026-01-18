CREATE OR REPLACE FUNCTION get_work_items_aggregates(
    p_object_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_system_filters TEXT[] DEFAULT NULL,
    p_section_filters TEXT[] DEFAULT NULL,
    p_floor_filters TEXT[] DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL
)
RETURNS TABLE (
    total_count BIGINT,
    total_quantity NUMERIC,
    total_sum NUMERIC
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH filtered_works AS (
        SELECT id FROM works 
        WHERE object_id = p_object_id
          AND (p_start_date IS NULL OR date >= p_start_date)
          AND (p_end_date IS NULL OR date <= p_end_date)
    )
    SELECT 
        COUNT(*)::BIGINT as total_count,
        COALESCE(SUM(wi.quantity), 0)::NUMERIC as total_quantity,
        COALESCE(SUM(wi.quantity * e.price), 0)::NUMERIC as total_sum
    FROM work_items wi
    LEFT JOIN estimates e ON wi.estimate_id = e.id
    WHERE wi.work_id IN (SELECT id FROM filtered_works)
      AND (p_system_filters IS NULL OR array_length(p_system_filters, 1) IS NULL OR wi.system = ANY(p_system_filters))
      AND (p_section_filters IS NULL OR array_length(p_section_filters, 1) IS NULL OR wi.section = ANY(p_section_filters))
      AND (p_floor_filters IS NULL OR array_length(p_floor_filters, 1) IS NULL OR wi.floor = ANY(p_floor_filters))
      AND (p_search_query IS NULL OR p_search_query = '' OR wi.name ILIKE '%' || p_search_query || '%');
END;
$$;

CREATE OR REPLACE FUNCTION get_work_items_available_filters(
    p_object_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_system_filters TEXT[] DEFAULT NULL,
    p_section_filters TEXT[] DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL
)
RETURNS TABLE (
    systems TEXT[],
    sections TEXT[],
    floors TEXT[]
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
        array_agg(DISTINCT system) FILTER (WHERE system IS NOT NULL AND system <> '') as systems,
        array_agg(DISTINCT section) FILTER (WHERE section IS NOT NULL AND section <> '') as sections,
        array_agg(DISTINCT floor) FILTER (WHERE floor IS NOT NULL AND floor <> '') as floors
    FROM work_items
    WHERE work_id IN (SELECT id FROM filtered_works)
      AND (p_system_filters IS NULL OR array_length(p_system_filters, 1) IS NULL OR system = ANY(p_system_filters))
      AND (p_section_filters IS NULL OR array_length(p_section_filters, 1) IS NULL OR section = ANY(p_section_filters))
      AND (p_search_query IS NULL OR p_search_query = '' OR name ILIKE '%' || p_search_query || '%');
END;
$$;

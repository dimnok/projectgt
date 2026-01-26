-- Функция для поиска работ с пагинацией и корректной сортировкой по дате (обновлена: добавлено m15_name)
-- Сначала удаляем старую функцию, так как изменился набор возвращаемых колонок
DROP FUNCTION IF EXISTS search_work_items_paginated(uuid,date,date,text[],text[],text[],text,integer,integer);

CREATE OR REPLACE FUNCTION search_work_items_paginated(
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
RETURNS TABLE (
    work_item_id UUID,
    work_id UUID,
    work_date DATE,
    object_id UUID,
    object_name TEXT,
    work_status TEXT,
    system TEXT,
    subsystem TEXT,
    section TEXT,
    floor TEXT,
    work_name TEXT,
    unit TEXT,
    quantity NUMERIC,
    estimate_id UUID,
    price DOUBLE PRECISION,
    position_number TEXT,
    contract_number TEXT,
    m15_name TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wi.id as work_item_id,
        wi.work_id,
        w.date as work_date,
        w.object_id,
        o.name as object_name,
        w.status as work_status,
        wi.system,
        wi.subsystem,
        wi.section,
        wi.floor,
        wi.name as work_name,
        wi.unit,
        wi.quantity,
        wi.estimate_id,
        e.price,
        e.number as position_number,
        c.number as contract_number,
        (
            SELECT string_agg(DISTINCT ma.alias_raw, ', ')
            FROM material_aliases ma
            WHERE ma.estimate_id = wi.estimate_id
        ) as m15_name
    FROM work_items wi
    JOIN works w ON wi.work_id = w.id
    LEFT JOIN objects o ON w.object_id = o.id
    LEFT JOIN estimates e ON wi.estimate_id = e.id
    LEFT JOIN contracts c ON e.contract_id = c.id
    WHERE w.object_id = p_object_id
      AND (p_start_date IS NULL OR w.date >= p_start_date)
      AND (p_end_date IS NULL OR w.date <= p_end_date)
      AND (p_system_filters IS NULL OR array_length(p_system_filters, 1) IS NULL OR wi.system = ANY(p_system_filters))
      AND (p_section_filters IS NULL OR array_length(p_section_filters, 1) IS NULL OR wi.section = ANY(p_section_filters))
      AND (p_floor_filters IS NULL OR array_length(p_floor_filters, 1) IS NULL OR wi.floor = ANY(p_floor_filters))
      AND (p_search_query IS NULL OR p_search_query = '' OR wi.name ILIKE '%' || p_search_query || '%')
    ORDER BY w.date DESC, wi.id DESC
    OFFSET p_from
    LIMIT (p_to - p_from + 1);
END;
$$;

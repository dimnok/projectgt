CREATE OR REPLACE FUNCTION get_cash_flow_available_filters(
    p_company_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    object_ids UUID[],
    contractor_ids UUID[],
    contract_ids UUID[]
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        array_agg(DISTINCT object_id) FILTER (WHERE object_id IS NOT NULL) as object_ids,
        array_agg(DISTINCT contractor_id) FILTER (WHERE contractor_id IS NOT NULL) as contractor_ids,
        array_agg(DISTINCT contract_id) FILTER (WHERE contract_id IS NOT NULL) as contract_ids
    FROM cash_flow
    WHERE company_id = p_company_id
      AND date >= p_start_date
      AND date <= p_end_date;
END;
$$;


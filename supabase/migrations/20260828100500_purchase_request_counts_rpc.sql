-- RPC для подсчета количества заявок на закупку по категориям фильтров.
CREATE OR REPLACE FUNCTION public.purchase_request_counts(
    p_company_id UUID,
    p_search TEXT DEFAULT NULL
)
RETURNS TABLE (
    pending_approval INT,
    approved INT,
    all_count INT,
    archive INT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
#variable_conflict use_column
DECLARE
    v_uid UUID := auth.uid();
    v_search TEXT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(p_company_id);

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'read') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_search := NULLIF(btrim(p_search), '');

    RETURN QUERY
    WITH base AS (
        SELECT r.id, r.status
        FROM public.purchase_requests r
        WHERE r.company_id = p_company_id
          AND (
            public.check_permission(v_uid, 'purchase_requests', 'view_all')
            OR r.created_by = v_uid
            OR public.purchase_request_internal_user_is_assignee(
                r.company_id, r.status, r.created_by, v_uid
            )
          )
          AND (
            v_search IS NULL
            OR r.number ILIKE '%' || v_search || '%'
            OR EXISTS (
                SELECT 1 FROM public.purchase_request_items it
                WHERE it.request_id = r.id
                  AND it.name ILIKE '%' || v_search || '%'
            )
            OR EXISTS (
                SELECT 1 FROM public.purchase_request_invoices inv
                JOIN public.contractors c ON c.id = inv.supplier_id
                WHERE inv.request_id = r.id
                  AND (
                    c.short_name ILIKE '%' || v_search || '%'
                    OR c.full_name ILIKE '%' || v_search || '%'
                    OR inv.invoice_number ILIKE '%' || v_search || '%'
                  )
            )
          )
    )
    SELECT
        COUNT(*) FILTER (WHERE b.status = 'approval')::INT AS pending_approval,
        COUNT(*) FILTER (WHERE b.status IN (
            'invoice_preparation',
            'invoice_approval',
            'accounting',
            'payment_queue',
            'paid'
        ))::INT AS approved,
        COUNT(*)::INT AS all_count,
        COUNT(*) FILTER (WHERE b.status IN ('received', 'cancelled'))::INT AS archive
    FROM base b;
END;
$$;

REVOKE ALL ON FUNCTION public.purchase_request_counts(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_counts(UUID, TEXT) TO authenticated;

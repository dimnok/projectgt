-- Добавить ФИО инициатора в purchase_request_list.

BEGIN;

DROP FUNCTION IF EXISTS public.purchase_request_list(
    UUID, TEXT, TEXT, UUID, TEXT, UUID, DATE, DATE, INT, INT
);

CREATE OR REPLACE FUNCTION public.purchase_request_list(
    p_company_id UUID,
    p_filter TEXT DEFAULT 'all',
    p_search TEXT DEFAULT NULL,
    p_object_id UUID DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL,
    p_from_date DATE DEFAULT NULL,
    p_to_date DATE DEFAULT NULL,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    number TEXT,
    object_id UUID,
    object_name TEXT,
    status TEXT,
    created_by UUID,
    created_by_name TEXT,
    current_assignee_id UUID,
    total_amount NUMERIC,
    created_at TIMESTAMPTZ,
    items_preview TEXT,
    items_count INT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
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
        SELECT r.*
        FROM public.purchase_requests r
        WHERE r.company_id = p_company_id
          AND (
            public.check_permission(v_uid, 'purchase_requests', 'view_all')
            OR r.created_by = v_uid
            OR r.current_assignee_id = v_uid
          )
          AND (
            p_filter = 'all'
            OR (p_filter = 'mine' AND r.created_by = v_uid)
            OR (p_filter = 'on_me' AND r.current_assignee_id = v_uid
                AND r.status NOT IN ('received', 'cancelled', 'draft'))
            OR (p_filter = 'archive' AND r.status IN ('received', 'cancelled'))
            OR p_filter NOT IN ('all', 'mine', 'on_me', 'archive')
          )
          AND (p_object_id IS NULL OR r.object_id = p_object_id)
          AND (p_status IS NULL OR r.status = p_status)
          AND (p_created_by IS NULL OR r.created_by = p_created_by)
          AND (p_from_date IS NULL OR r.created_at::date >= p_from_date)
          AND (p_to_date IS NULL OR r.created_at::date <= p_to_date)
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
    ),
    item_agg AS (
        SELECT
            i.request_id,
            COUNT(*)::INT AS cnt,
            (
                SELECT string_agg(sub.name, ', ' ORDER BY sub.sort_order, sub.created_at)
                FROM (
                    SELECT x.name, x.sort_order, x.created_at
                    FROM public.purchase_request_items x
                    WHERE x.request_id = i.request_id
                    ORDER BY x.sort_order, x.created_at
                    LIMIT 3
                ) sub
            ) AS preview
        FROM public.purchase_request_items i
        WHERE i.request_id IN (SELECT b.id FROM base b)
        GROUP BY i.request_id
    )
    SELECT
        b.id,
        b.number,
        b.object_id,
        o.name AS object_name,
        b.status,
        b.created_by,
        COALESCE(
            NULLIF(btrim(pr.short_name), ''),
            NULLIF(btrim(pr.full_name), ''),
            NULLIF(btrim(pr.email), ''),
            '—'
        ) AS created_by_name,
        b.current_assignee_id,
        b.total_amount,
        b.created_at,
        COALESCE(ia.preview, '') AS items_preview,
        COALESCE(ia.cnt, 0) AS items_count
    FROM base b
    JOIN public.objects o ON o.id = b.object_id
    LEFT JOIN public.profiles pr ON pr.id = b.created_by
    LEFT JOIN item_agg ia ON ia.request_id = b.id
    ORDER BY b.created_at DESC
    LIMIT GREATEST(p_limit, 1)
    OFFSET GREATEST(p_offset, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.purchase_request_list(
    UUID, TEXT, TEXT, UUID, TEXT, UUID, DATE, DATE, INT, INT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_list(
    UUID, TEXT, TEXT, UUID, TEXT, UUID, DATE, DATE, INT, INT
) TO authenticated;

COMMIT;

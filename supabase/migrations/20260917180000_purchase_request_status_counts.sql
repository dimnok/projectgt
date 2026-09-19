-- Счётчики заявок по реальным статусам.
--
-- Отдельная функция, чтобы не менять смысл `purchase_request_counts`
-- (её использует приложение). Возвращает по строке на каждый статус
-- плюс строку 'all' с общим количеством. Права доступа и поиск —
-- те же, что в реестре.

BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_request_status_counts(
    p_company_id UUID,
    p_search TEXT DEFAULT NULL
)
RETURNS TABLE (
    status_code TEXT,
    request_count INT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
        SELECT r.status
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
    SELECT s.status_code, COALESCE(c.cnt, 0)::INT
    FROM (
        VALUES
            ('draft'::TEXT),
            ('approval'),
            ('revision'),
            ('invoice_preparation'),
            ('invoice_approval'),
            ('accounting'),
            ('payment_queue'),
            ('paid'),
            ('received')
    ) AS s(status_code)
    LEFT JOIN (
        SELECT b.status AS st, COUNT(*)::INT AS cnt
        FROM base b
        GROUP BY b.status
    ) c ON c.st = s.status_code
    UNION ALL
    SELECT 'all'::TEXT, COUNT(*)::INT
    FROM base;
END;
$$;

COMMENT ON FUNCTION public.purchase_request_status_counts(UUID, TEXT) IS
    'Количество заявок по каждому реальному статусу плюс строка all с общим числом.';

REVOKE ALL ON FUNCTION public.purchase_request_status_counts(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_status_counts(UUID, TEXT) TO authenticated;

COMMIT;

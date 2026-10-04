-- Счётчики заявок по статусам с учётом объекта.
--
-- Добавлен необязательный фильтр по объекту: карточка «Оплачено по объектам»
-- работает как фильтр реестра, поэтому счётчики должны считать то же
-- множество заявок, что и список — иначе итог и число страниц разойдутся
-- с тем, что видно в таблице.
--
-- Сигнатура с двумя аргументами больше не нужна: вызовы с двумя именованными
-- параметрами обслуживает новая версия (третий параметр по умолчанию NULL).

BEGIN;

DROP FUNCTION IF EXISTS public.purchase_request_status_counts(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.purchase_request_status_counts(
    p_company_id UUID,
    p_search TEXT DEFAULT NULL,
    p_object_id UUID DEFAULT NULL
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
          AND (p_object_id IS NULL OR r.object_id = p_object_id)
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

COMMENT ON FUNCTION public.purchase_request_status_counts(UUID, TEXT, UUID) IS
    'Количество заявок по каждому реальному статусу плюс строка all с общим числом; при передаче объекта — только по нему.';

REVOKE ALL ON FUNCTION public.purchase_request_status_counts(UUID, TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_status_counts(UUID, TEXT, UUID) TO authenticated;

COMMIT;

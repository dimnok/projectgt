-- KPI «Оплачено по объектам»: сумма оплаченных счетов по каждому объекту.
--
-- Считаем счета заявок в статусе «Оплачено» (paid). Группируем по объекту
-- заявки. Видимость строк — та же, что у реестра: право view_all, автор
-- или участник этапа. Отдельных прав не вводим.

BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_request_paid_by_object(
    p_company_id UUID
)
RETURNS TABLE (
    object_id UUID,
    object_name TEXT,
    paid_amount NUMERIC,
    requests_count INT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(p_company_id);

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'read') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    WITH paid_requests AS (
        SELECT r.id, r.object_id
        FROM public.purchase_requests r
        WHERE r.company_id = p_company_id
          AND r.status = 'paid'
          AND (
            public.check_permission(v_uid, 'purchase_requests', 'view_all')
            OR r.created_by = v_uid
            OR public.purchase_request_internal_user_is_assignee(
                r.company_id, r.status, r.created_by, v_uid
            )
          )
    ),
    per_object AS (
        SELECT
            p.object_id,
            COALESCE(SUM(inv.amount), 0)::NUMERIC AS paid_amount,
            COUNT(DISTINCT p.id)::INT AS requests_count
        FROM paid_requests p
        LEFT JOIN public.purchase_request_invoices inv
            ON inv.request_id = p.id
        GROUP BY p.object_id
    )
    SELECT
        o.id,
        o.name,
        per_object.paid_amount,
        per_object.requests_count
    FROM per_object
    JOIN public.objects o ON o.id = per_object.object_id
    ORDER BY per_object.paid_amount DESC, o.name;
END;
$$;

COMMENT ON FUNCTION public.purchase_request_paid_by_object(UUID) IS
    'Сумма оплаченных счетов и число заявок по каждому объекту (статус paid).';

REVOKE ALL ON FUNCTION public.purchase_request_paid_by_object(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_paid_by_object(UUID) TO authenticated;

COMMIT;

-- Отмена заявки: откат в черновик (заявка остаётся рабочей), а не архивный статус cancelled.

CREATE OR REPLACE FUNCTION public.purchase_request_cancel(
    p_request_id UUID,
    p_comment TEXT
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_prev_assignee UUID;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_comment IS NULL OR btrim(p_comment) = '' THEN
        RAISE EXCEPTION 'Укажите причину отмены';
    END IF;

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(v_row.company_id);

    IF v_row.status IN ('draft', 'received', 'cancelled') THEN
        RAISE EXCEPTION 'Заявку нельзя вернуть в черновик из текущего статуса';
    END IF;

    IF v_row.created_by <> v_uid
        AND NOT public.check_permission(v_uid, 'purchase_requests', 'view_all')
    THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_prev_assignee := v_row.current_assignee_id;

    v_row := public.purchase_request_internal_transition(
        p_request_id, v_row.status, 'draft', v_row.created_by,
        'cancelled', btrim(p_comment), '{}'::jsonb, false, false
    );

    UPDATE public.purchase_requests
    SET
        completed_at = NULL,
        submitted_at = NULL,
        updated_at = now()
    WHERE id = p_request_id
    RETURNING * INTO v_row;

    IF v_prev_assignee IS NOT NULL AND v_prev_assignee IS DISTINCT FROM v_uid THEN
        PERFORM public.purchase_request_internal_notify(
            v_row.company_id,
            p_request_id,
            v_prev_assignee,
            v_row.number || ' возвращена в черновик',
            btrim(p_comment)
        );
    END IF;

    IF v_row.created_by IS DISTINCT FROM v_uid THEN
        PERFORM public.purchase_request_internal_notify(
            v_row.company_id,
            p_request_id,
            v_row.created_by,
            v_row.number || ' возвращена в черновик',
            btrim(p_comment)
        );
    END IF;

    RETURN v_row;
END;
$$;

UPDATE public.purchase_requests
SET
    status = 'draft',
    current_assignee_id = created_by,
    completed_at = NULL,
    submitted_at = NULL,
    updated_at = now()
WHERE status = 'cancelled';

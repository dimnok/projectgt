-- Редактирование шапки и удаление заявки: только автор и только статус draft.

CREATE OR REPLACE FUNCTION public.purchase_request_update_header(
    p_request_id UUID,
    p_object_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'create') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(v_row.company_id);

    IF v_row.created_by <> v_uid THEN
        RAISE EXCEPTION 'Редактировать можно только свою заявку';
    END IF;

    IF v_row.status <> 'draft' THEN
        RAISE EXCEPTION 'Редактирование возможно только для черновика';
    END IF;

    IF p_object_id IS NULL THEN
        RAISE EXCEPTION 'Объект обязателен';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.objects o
        WHERE o.id = p_object_id AND o.company_id = v_row.company_id
    ) THEN
        RAISE EXCEPTION 'Объект не найден';
    END IF;

    UPDATE public.purchase_requests
    SET
        object_id = p_object_id,
        comment = p_comment,
        updated_at = now()
    WHERE id = p_request_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_delete_draft(
    p_request_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'create') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(v_row.company_id);

    IF v_row.status <> 'draft' THEN
        RAISE EXCEPTION 'Удаление возможно только для черновика';
    END IF;

    IF v_row.created_by <> v_uid THEN
        RAISE EXCEPTION 'Удалить можно только свою заявку';
    END IF;

    DELETE FROM public.purchase_requests WHERE id = p_request_id;
END;
$$;

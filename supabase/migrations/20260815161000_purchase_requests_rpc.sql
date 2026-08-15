-- RPC: заявки на закупку — нумерация, workflow, список.

BEGIN;

-- ---------------------------------------------------------------------------
-- Внутренние helpers (не для клиента)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_internal_assert_company(
    p_company_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_company_id IS NULL
        OR NOT (p_company_id IN (SELECT public.get_my_company_ids()))
    THEN
        RAISE EXCEPTION 'Access denied' USING ERRCODE = '42501';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_next_number(
    p_company_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_year INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
    v_next INT;
BEGIN
    INSERT INTO public.purchase_request_number_seq (company_id, year, last_value)
    VALUES (p_company_id, v_year, 1)
    ON CONFLICT (company_id, year)
    DO UPDATE SET last_value = public.purchase_request_number_seq.last_value + 1
    RETURNING last_value INTO v_next;

    RETURN 'ЗП-' || v_year::TEXT || '-' || lpad(v_next::TEXT, 5, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_write_history(
    p_company_id UUID,
    p_request_id UUID,
    p_user_id UUID,
    p_action TEXT,
    p_from_status TEXT,
    p_to_status TEXT,
    p_comment TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.purchase_request_history (
        company_id, request_id, user_id, action,
        from_status, to_status, comment, metadata
    ) VALUES (
        p_company_id, p_request_id, p_user_id, p_action,
        p_from_status, p_to_status, p_comment, COALESCE(p_metadata, '{}'::jsonb)
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_notify(
    p_company_id UUID,
    p_request_id UUID,
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_user_id IS NULL THEN
        RETURN;
    END IF;
    INSERT INTO public.purchase_request_notifications (
        company_id, request_id, user_id, title, body
    ) VALUES (
        p_company_id, p_request_id, p_user_id, p_title, p_body
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_resolve_receiver(
    p_request_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_created_by UUID;
    v_company_id UUID;
    v_mode TEXT;
    v_fixed UUID;
BEGIN
    SELECT r.created_by, r.company_id
    INTO v_created_by, v_company_id
    FROM public.purchase_requests r
    WHERE r.id = p_request_id;

    SELECT s.receiver_mode, s.fixed_receiver_id
    INTO v_mode, v_fixed
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_company_id;

    IF v_mode = 'fixed_user' THEN
        RETURN v_fixed;
    END IF;
    RETURN v_created_by;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_transition(
    p_request_id UUID,
    p_expected_status TEXT,
    p_new_status TEXT,
    p_new_assignee UUID,
    p_action TEXT,
    p_comment TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb,
    p_set_submitted BOOLEAN DEFAULT false,
    p_set_completed BOOLEAN DEFAULT false
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(v_row.company_id);

    IF v_row.status IS DISTINCT FROM p_expected_status THEN
        RAISE EXCEPTION 'Недопустимый статус заявки: %', v_row.status;
    END IF;

    UPDATE public.purchase_requests
    SET
        status = p_new_status,
        current_assignee_id = p_new_assignee,
        submitted_at = CASE
            WHEN p_set_submitted THEN COALESCE(submitted_at, now())
            ELSE submitted_at
        END,
        completed_at = CASE
            WHEN p_set_completed THEN now()
            ELSE completed_at
        END,
        updated_at = now()
    WHERE id = p_request_id
    RETURNING * INTO v_row;

    PERFORM public.purchase_request_internal_write_history(
        v_row.company_id, p_request_id, v_uid, p_action,
        p_expected_status, p_new_status, p_comment, p_metadata
    );

    RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.purchase_request_internal_assert_company(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purchase_request_internal_next_number(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purchase_request_internal_write_history(
    UUID, UUID, UUID, TEXT, TEXT, TEXT, TEXT, JSONB
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purchase_request_internal_notify(
    UUID, UUID, UUID, TEXT, TEXT
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purchase_request_internal_resolve_receiver(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purchase_request_internal_transition(
    UUID, TEXT, TEXT, UUID, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN
) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- Создание черновика
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_create_draft(
    p_company_id UUID,
    p_object_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_id UUID;
    v_number TEXT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
    END IF;
    IF NOT public.check_permission(v_uid, 'purchase_requests', 'create') THEN
        RAISE EXCEPTION 'Access denied' USING ERRCODE = '42501';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(p_company_id);

    IF p_object_id IS NULL THEN
        RAISE EXCEPTION 'Объект обязателен';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.objects o
        WHERE o.id = p_object_id AND o.company_id = p_company_id
    ) THEN
        RAISE EXCEPTION 'Объект не найден';
    END IF;

    v_number := public.purchase_request_internal_next_number(p_company_id);

    INSERT INTO public.purchase_requests (
        company_id, number, object_id, created_by,
        current_assignee_id, status, comment
    ) VALUES (
        p_company_id, v_number, p_object_id, v_uid,
        v_uid, 'draft', p_comment
    )
    RETURNING id INTO v_id;

    PERFORM public.purchase_request_internal_write_history(
        p_company_id, v_id, v_uid, 'created', NULL, 'draft', NULL, '{}'::jsonb
    );

    RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Обновление черновика / доработки
-- ---------------------------------------------------------------------------
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

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(v_row.company_id);

    IF v_row.created_by <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF v_row.status NOT IN ('draft', 'revision') THEN
        RAISE EXCEPTION 'Заявка недоступна для редактирования';
    END IF;

    IF p_object_id IS NULL THEN
        RAISE EXCEPTION 'Объект обязателен';
    END IF;

    UPDATE public.purchase_requests
    SET
        object_id = p_object_id,
        comment = p_comment,
        updated_at = now()
    WHERE id = p_request_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Удаление черновика
-- ---------------------------------------------------------------------------
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

    IF v_row.created_by <> v_uid
        AND NOT public.check_permission(v_uid, 'purchase_requests', 'view_all')
    THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    DELETE FROM public.purchase_requests WHERE id = p_request_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Отправка / повторная отправка
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_submit(
    p_request_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_settings public.purchase_request_settings;
    v_items_count INT;
    v_action TEXT;
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(v_row.company_id);

    IF v_row.created_by <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF v_row.status NOT IN ('draft', 'revision') THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'create') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT COUNT(*)::INT INTO v_items_count
    FROM public.purchase_request_items i
    WHERE i.request_id = p_request_id;

    IF v_items_count = 0 THEN
        RAISE EXCEPTION 'Добавьте хотя бы одну позицию';
    END IF;

    SELECT * INTO v_settings
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_row.company_id;

    IF v_settings.first_approver_id IS NULL THEN
        RAISE EXCEPTION 'Не настроен первый согласующий';
    END IF;

    v_action := CASE
        WHEN v_row.status = 'draft' THEN 'submitted'
        ELSE 'resubmitted'
    END;

    v_row := public.purchase_request_internal_transition(
        p_request_id, v_row.status, 'approval', v_settings.first_approver_id,
        v_action, p_comment, '{}'::jsonb, true, false
    );

    PERFORM public.purchase_request_internal_notify(
        v_row.company_id, p_request_id, v_settings.first_approver_id,
        v_row.number || ' ожидает согласования',
        NULL
    );

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Первое согласование
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_approve(
    p_request_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_settings public.purchase_request_settings;
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    IF v_row.status <> 'approval' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'approve') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT * INTO v_settings
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_row.company_id;

    IF v_settings.invoice_preparer_id IS NULL THEN
        RAISE EXCEPTION 'Не настроен ответственный за счёт';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'approval', 'invoice_preparation',
        v_settings.invoice_preparer_id, 'approved', p_comment, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify(
        v_row.company_id, p_request_id, v_settings.invoice_preparer_id,
        v_row.number || ' согласована. Необходимо добавить счёт',
        NULL
    );

    RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_return(
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
BEGIN
    IF p_comment IS NULL OR btrim(p_comment) = '' THEN
        RAISE EXCEPTION 'Укажите причину возврата';
    END IF;

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    IF v_row.status <> 'approval' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'approve') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'approval', 'revision', v_row.created_by,
        'returned', p_comment, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify(
        v_row.company_id, p_request_id, v_row.created_by,
        v_row.number || ' возвращена на доработку',
        p_comment
    );

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Счета: отправка на согласование
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_submit_invoices(
    p_request_id UUID
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_settings public.purchase_request_settings;
    v_invoice_count INT;
    v_missing_files INT;
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    IF v_row.status <> 'invoice_preparation' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'prepare_invoice') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT COUNT(*)::INT INTO v_invoice_count
    FROM public.purchase_request_invoices i
    WHERE i.request_id = p_request_id;

    IF v_invoice_count = 0 THEN
        RAISE EXCEPTION 'Добавьте хотя бы один счёт';
    END IF;

    SELECT COUNT(*)::INT INTO v_missing_files
    FROM public.purchase_request_invoices i
    WHERE i.request_id = p_request_id
      AND NOT EXISTS (
          SELECT 1 FROM public.purchase_request_files f
          WHERE f.invoice_id = i.id AND f.type = 'invoice'
      );

    IF v_missing_files > 0 THEN
        RAISE EXCEPTION 'Для каждого счёта нужен файл';
    END IF;

    SELECT * INTO v_settings
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_row.company_id;

    IF v_settings.invoice_approver_id IS NULL THEN
        RAISE EXCEPTION 'Не настроен финальный согласующий';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'invoice_preparation', 'invoice_approval',
        v_settings.invoice_approver_id, 'invoices_submitted', NULL, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify(
        v_row.company_id, p_request_id, v_settings.invoice_approver_id,
        'Счета по ' || v_row.number || ' ожидают согласования',
        NULL
    );

    RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_approve_invoice(
    p_request_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_settings public.purchase_request_settings;
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    IF v_row.status <> 'invoice_approval' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'approve_invoice') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT * INTO v_settings
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_row.company_id;

    IF v_settings.accountant_id IS NULL THEN
        RAISE EXCEPTION 'Не настроен бухгалтер';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'invoice_approval', 'accounting',
        v_settings.accountant_id, 'invoice_approved', p_comment, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify(
        v_row.company_id, p_request_id, v_settings.accountant_id,
        v_row.number || ' передана на оплату',
        NULL
    );

    RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_return_invoice(
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
    v_settings public.purchase_request_settings;
BEGIN
    IF p_comment IS NULL OR btrim(p_comment) = '' THEN
        RAISE EXCEPTION 'Укажите причину возврата';
    END IF;

    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    IF v_row.status <> 'invoice_approval' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'approve_invoice') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT * INTO v_settings
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_row.company_id;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'invoice_approval', 'invoice_preparation',
        v_settings.invoice_preparer_id, 'invoice_returned', p_comment, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify(
        v_row.company_id, p_request_id, v_settings.invoice_preparer_id,
        v_row.number || ' — счета возвращены на доработку',
        p_comment
    );

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Бухгалтерия
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_queue_payment(
    p_request_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF v_row.status <> 'accounting' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'payment') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'accounting', 'payment_queue',
        v_row.current_assignee_id, 'queued_for_payment', p_comment, '{}'::jsonb, false, false
    );

    RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_mark_paid(
    p_request_id UUID,
    p_payment_date DATE DEFAULT NULL,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_receiver UUID;
    v_meta JSONB;
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка не найдена';
    END IF;

    IF v_row.status <> 'payment_queue' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'payment') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_receiver := public.purchase_request_internal_resolve_receiver(p_request_id);
    v_meta := jsonb_build_object(
        'payment_date', COALESCE(p_payment_date, CURRENT_DATE)
    );

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'payment_queue', 'paid', v_receiver,
        'paid', p_comment, v_meta, false, false
    );

    IF v_receiver IS NOT NULL AND v_receiver <> v_uid THEN
        PERFORM public.purchase_request_internal_notify(
            v_row.company_id, p_request_id, v_receiver,
            v_row.number || ' оплачена. Подтвердите получение',
            NULL
        );
    END IF;

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Получение
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_mark_received(
    p_request_id UUID,
    p_received_date DATE DEFAULT NULL,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_meta JSONB;
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF v_row.status <> 'paid' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF v_row.current_assignee_id <> v_uid THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'receive') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_meta := jsonb_build_object(
        'received_date', COALESCE(p_received_date, CURRENT_DATE)
    );

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'paid', 'received', NULL,
        'received', p_comment, v_meta, false, true
    );

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Отмена
-- ---------------------------------------------------------------------------
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
BEGIN
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

    IF v_row.status IN ('received', 'cancelled') THEN
        RAISE EXCEPTION 'Заявка уже завершена';
    END IF;

    IF v_row.created_by <> v_uid
        AND NOT public.check_permission(v_uid, 'purchase_requests', 'view_all')
    THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, v_row.status, 'cancelled', NULL,
        'cancelled', p_comment, '{}'::jsonb, false, true
    );

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Настройки модуля
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_upsert_settings(
    p_company_id UUID,
    p_first_approver_id UUID,
    p_invoice_preparer_id UUID,
    p_invoice_approver_id UUID,
    p_accountant_id UUID,
    p_receiver_mode TEXT DEFAULT 'initiator',
    p_fixed_receiver_id UUID DEFAULT NULL
)
RETURNS public.purchase_request_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_row public.purchase_request_settings;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    PERFORM public.purchase_request_internal_assert_company(p_company_id);

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'view_all') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_receiver_mode NOT IN ('initiator', 'fixed_user') THEN
        RAISE EXCEPTION 'Некорректный режим получателя';
    END IF;

    IF p_receiver_mode = 'fixed_user' AND p_fixed_receiver_id IS NULL THEN
        RAISE EXCEPTION 'Укажите ответственного за получение';
    END IF;

    INSERT INTO public.purchase_request_settings (
        company_id, first_approver_id, invoice_preparer_id,
        invoice_approver_id, accountant_id, receiver_mode,
        fixed_receiver_id, updated_by
    ) VALUES (
        p_company_id, p_first_approver_id, p_invoice_preparer_id,
        p_invoice_approver_id, p_accountant_id, p_receiver_mode,
        p_fixed_receiver_id, v_uid
    )
    ON CONFLICT (company_id) DO UPDATE SET
        first_approver_id = EXCLUDED.first_approver_id,
        invoice_preparer_id = EXCLUDED.invoice_preparer_id,
        invoice_approver_id = EXCLUDED.invoice_approver_id,
        accountant_id = EXCLUDED.accountant_id,
        receiver_mode = EXCLUDED.receiver_mode,
        fixed_receiver_id = EXCLUDED.fixed_receiver_id,
        updated_by = v_uid,
        updated_at = now()
    RETURNING * INTO v_row;

    RETURN v_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Список заявок (лёгкий)
-- ---------------------------------------------------------------------------
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
        b.current_assignee_id,
        b.total_amount,
        b.created_at,
        COALESCE(ia.preview, '') AS items_preview,
        COALESCE(ia.cnt, 0) AS items_count
    FROM base b
    JOIN public.objects o ON o.id = b.object_id
    LEFT JOIN item_agg ia ON ia.request_id = b.id
    ORDER BY b.created_at DESC
    LIMIT GREATEST(p_limit, 1)
    OFFSET GREATEST(p_offset, 0);
END;
$$;

-- ---------------------------------------------------------------------------
-- GRANT публичных RPC
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.purchase_request_create_draft(
    UUID, UUID, TEXT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_create_draft(
    UUID, UUID, TEXT
) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_update_header(
    UUID, UUID, TEXT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_update_header(
    UUID, UUID, TEXT
) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_delete_draft(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_delete_draft(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_submit(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_submit(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_approve(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_approve(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_return(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_return(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_submit_invoices(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_submit_invoices(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_approve_invoice(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_approve_invoice(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_return_invoice(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_return_invoice(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_queue_payment(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_queue_payment(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_mark_paid(UUID, DATE, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_mark_paid(UUID, DATE, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_mark_received(UUID, DATE, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_mark_received(UUID, DATE, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_cancel(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_cancel(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_upsert_settings(
    UUID, UUID, UUID, UUID, UUID, TEXT, UUID
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_upsert_settings(
    UUID, UUID, UUID, UUID, UUID, TEXT, UUID
) TO authenticated;

REVOKE ALL ON FUNCTION public.purchase_request_list(
    UUID, TEXT, TEXT, UUID, TEXT, UUID, DATE, DATE, INT, INT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_list(
    UUID, TEXT, TEXT, UUID, TEXT, UUID, DATE, DATE, INT, INT
) TO authenticated;

REVOKE INSERT ON public.purchase_request_notifications FROM authenticated;

COMMIT;

-- Настройки заявок: только владелец компании. Создание заявок — после настройки маршрута.

BEGIN;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_is_company_owner(
    p_company_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.company_members cm
        WHERE cm.company_id = p_company_id
          AND cm.user_id = p_user_id
          AND cm.is_active = true
          AND cm.is_owner = true
    );
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_settings_configured(
    p_company_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.purchase_request_settings s
        WHERE s.company_id = p_company_id
          AND s.first_approver_id IS NOT NULL
          AND s.invoice_preparer_id IS NOT NULL
          AND s.invoice_approver_id IS NOT NULL
          AND s.accountant_id IS NOT NULL
          AND (
              s.receiver_mode = 'initiator'
              OR (
                  s.receiver_mode = 'fixed_user'
                  AND s.fixed_receiver_id IS NOT NULL
              )
          )
    );
$$;

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

    IF NOT public.purchase_request_internal_settings_configured(p_company_id) THEN
        RAISE EXCEPTION 'Модуль не настроен. Владелец компании должен указать согласующих';
    END IF;

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

    IF NOT public.purchase_request_internal_is_company_owner(p_company_id, v_uid) THEN
        RAISE EXCEPTION 'Только владелец компании может настраивать маршрут';
    END IF;

    IF p_receiver_mode NOT IN ('initiator', 'fixed_user') THEN
        RAISE EXCEPTION 'Некорректный режим получателя';
    END IF;

    IF p_receiver_mode = 'fixed_user' AND p_fixed_receiver_id IS NULL THEN
        RAISE EXCEPTION 'Укажите ответственного за получение';
    END IF;

    IF p_first_approver_id IS NULL
        OR p_invoice_preparer_id IS NULL
        OR p_invoice_approver_id IS NULL
        OR p_accountant_id IS NULL THEN
        RAISE EXCEPTION 'Укажите всех участников маршрута';
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

DROP POLICY IF EXISTS "pr_settings_insert" ON public.purchase_request_settings;
CREATE POLICY "pr_settings_insert"
ON public.purchase_request_settings FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.purchase_request_internal_is_company_owner(
        company_id, auth.uid()
    )
);

DROP POLICY IF EXISTS "pr_settings_update" ON public.purchase_request_settings;
CREATE POLICY "pr_settings_update"
ON public.purchase_request_settings FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.purchase_request_internal_is_company_owner(
        company_id, auth.uid()
    )
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.purchase_request_internal_is_company_owner(
        company_id, auth.uid()
    )
);

COMMIT;

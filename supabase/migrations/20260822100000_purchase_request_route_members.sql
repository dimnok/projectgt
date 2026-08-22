-- Несколько участников на роли маршрута. На этапе действует любой из списка.

BEGIN;

-- ---------------------------------------------------------------------------
-- Таблица участников маршрута
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_route_members (
    company_id UUID NOT NULL
        REFERENCES public.purchase_request_settings (company_id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    user_id UUID NOT NULL
        REFERENCES auth.users (id) ON DELETE CASCADE,
    sort_order INT NOT NULL DEFAULT 0,
    CONSTRAINT purchase_request_route_members_pkey
        PRIMARY KEY (company_id, role, user_id),
    CONSTRAINT purchase_request_route_members_role_chk CHECK (
        role = ANY (ARRAY[
            'first_approver'::text,
            'invoice_preparer'::text,
            'invoice_approver'::text,
            'accountant'::text,
            'receiver'::text
        ])
    )
);

CREATE INDEX IF NOT EXISTS idx_purchase_request_route_members_role
    ON public.purchase_request_route_members (company_id, role, sort_order);

INSERT INTO public.purchase_request_route_members (company_id, role, user_id, sort_order)
SELECT s.company_id, 'first_approver', s.first_approver_id, 0
FROM public.purchase_request_settings s
WHERE s.first_approver_id IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO public.purchase_request_route_members (company_id, role, user_id, sort_order)
SELECT s.company_id, 'invoice_preparer', s.invoice_preparer_id, 0
FROM public.purchase_request_settings s
WHERE s.invoice_preparer_id IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO public.purchase_request_route_members (company_id, role, user_id, sort_order)
SELECT s.company_id, 'invoice_approver', s.invoice_approver_id, 0
FROM public.purchase_request_settings s
WHERE s.invoice_approver_id IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO public.purchase_request_route_members (company_id, role, user_id, sort_order)
SELECT s.company_id, 'accountant', s.accountant_id, 0
FROM public.purchase_request_settings s
WHERE s.accountant_id IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO public.purchase_request_route_members (company_id, role, user_id, sort_order)
SELECT s.company_id, 'receiver', s.fixed_receiver_id, 0
FROM public.purchase_request_settings s
WHERE s.fixed_receiver_id IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE public.purchase_request_route_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pr_route_members_select" ON public.purchase_request_route_members;
CREATE POLICY "pr_route_members_select"
ON public.purchase_request_route_members FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'read')
);

GRANT SELECT ON public.purchase_request_route_members TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.purchase_request_route_members FROM authenticated;
REVOKE ALL ON public.purchase_request_route_members FROM anon;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_internal_user_is_assignee(
    p_company_id UUID,
    p_status TEXT,
    p_created_by UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
    v_role TEXT;
    v_mode TEXT;
BEGIN
    IF p_user_id IS NULL THEN
        RETURN false;
    END IF;

    IF p_status IN ('draft', 'revision') THEN
        RETURN p_user_id = p_created_by;
    END IF;

    IF p_status IN ('received', 'cancelled') THEN
        RETURN false;
    END IF;

    IF p_status = 'paid' THEN
        SELECT s.receiver_mode INTO v_mode
        FROM public.purchase_request_settings s
        WHERE s.company_id = p_company_id;

        IF v_mode = 'fixed_user' THEN
            RETURN EXISTS (
                SELECT 1
                FROM public.purchase_request_route_members m
                WHERE m.company_id = p_company_id
                  AND m.role = 'receiver'
                  AND m.user_id = p_user_id
            );
        END IF;

        RETURN p_user_id = p_created_by;
    END IF;

    v_role := CASE p_status
        WHEN 'approval' THEN 'first_approver'
        WHEN 'invoice_preparation' THEN 'invoice_preparer'
        WHEN 'invoice_approval' THEN 'invoice_approver'
        WHEN 'accounting' THEN 'accountant'
        WHEN 'payment_queue' THEN 'accountant'
        ELSE NULL
    END;

    IF v_role IS NULL THEN
        RETURN false;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.purchase_request_route_members m
        WHERE m.company_id = p_company_id
          AND m.role = v_role
          AND m.user_id = p_user_id
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_first_role_user(
    p_company_id UUID,
    p_role TEXT
)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
    SELECT m.user_id
    FROM public.purchase_request_route_members m
    WHERE m.company_id = p_company_id
      AND m.role = p_role
    ORDER BY m.sort_order, m.user_id
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_replace_role_members(
    p_company_id UUID,
    p_role TEXT,
    p_user_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
    DELETE FROM public.purchase_request_route_members
    WHERE company_id = p_company_id
      AND role = p_role;

    IF p_user_ids IS NULL OR cardinality(p_user_ids) = 0 THEN
        RETURN;
    END IF;

    INSERT INTO public.purchase_request_route_members (
        company_id, role, user_id, sort_order
    )
    SELECT
        p_company_id,
        p_role,
        d.user_id,
        d.sort_order
    FROM (
        SELECT u AS user_id, min(ord)::INT AS sort_order
        FROM unnest(p_user_ids) WITH ORDINALITY AS t(u, ord)
        WHERE u IS NOT NULL
        GROUP BY u
    ) d;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_assert_route_users(
    p_company_id UUID,
    p_user_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
    IF p_user_ids IS NULL OR cardinality(p_user_ids) = 0 THEN
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM unnest(p_user_ids) AS u(id)
        WHERE u.id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM public.company_members cm
              WHERE cm.company_id = p_company_id
                AND cm.user_id = u.id
                AND cm.is_active = true
          )
    ) THEN
        RAISE EXCEPTION 'Пользователь не состоит в компании';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_notify_role(
    p_company_id UUID,
    p_request_id UUID,
    p_role TEXT,
    p_title TEXT,
    p_body TEXT DEFAULT NULL,
    p_except_user_id UUID DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
    v_user UUID;
BEGIN
    FOR v_user IN
        SELECT m.user_id
        FROM public.purchase_request_route_members m
        WHERE m.company_id = p_company_id
          AND m.role = p_role
        ORDER BY m.sort_order, m.user_id
    LOOP
        IF v_user IS DISTINCT FROM p_except_user_id THEN
            PERFORM public.purchase_request_internal_notify(
                p_company_id, p_request_id, v_user, p_title, p_body
            );
        END IF;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_resolve_receiver(
    p_request_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
    v_created_by UUID;
    v_company_id UUID;
    v_mode TEXT;
BEGIN
    SELECT r.created_by, r.company_id
    INTO v_created_by, v_company_id
    FROM public.purchase_requests r
    WHERE r.id = p_request_id;

    SELECT s.receiver_mode
    INTO v_mode
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_company_id;

    IF v_mode = 'fixed_user' THEN
        RETURN public.purchase_request_internal_first_role_user(
            v_company_id, 'receiver'
        );
    END IF;
    RETURN v_created_by;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_internal_settings_configured(
    p_company_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.purchase_request_settings s
        WHERE s.company_id = p_company_id
          AND EXISTS (
              SELECT 1 FROM public.purchase_request_route_members m
              WHERE m.company_id = s.company_id AND m.role = 'first_approver'
          )
          AND EXISTS (
              SELECT 1 FROM public.purchase_request_route_members m
              WHERE m.company_id = s.company_id AND m.role = 'invoice_preparer'
          )
          AND EXISTS (
              SELECT 1 FROM public.purchase_request_route_members m
              WHERE m.company_id = s.company_id AND m.role = 'invoice_approver'
          )
          AND EXISTS (
              SELECT 1 FROM public.purchase_request_route_members m
              WHERE m.company_id = s.company_id AND m.role = 'accountant'
          )
          AND (
              s.receiver_mode = 'initiator'
              OR EXISTS (
                  SELECT 1 FROM public.purchase_request_route_members m
                  WHERE m.company_id = s.company_id AND m.role = 'receiver'
              )
          )
    );
$$;

REVOKE ALL ON FUNCTION public.purchase_request_internal_first_role_user(UUID, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_request_internal_replace_role_members(UUID, TEXT, UUID[]) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_request_internal_assert_route_users(UUID, UUID[]) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.purchase_request_internal_notify_role(UUID, UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.purchase_request_internal_user_is_assignee(UUID, TEXT, UUID, UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- can_read: статус вместо одного assignee
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "pr_requests_select" ON public.purchase_requests;
DROP POLICY IF EXISTS "pr_items_select" ON public.purchase_request_items;
DROP POLICY IF EXISTS "pr_invoices_select" ON public.purchase_request_invoices;
DROP POLICY IF EXISTS "pr_files_select" ON public.purchase_request_files;
DROP POLICY IF EXISTS "pr_history_select" ON public.purchase_request_history;

DROP FUNCTION IF EXISTS public.purchase_request_can_read(UUID, UUID, UUID);

CREATE OR REPLACE FUNCTION public.purchase_request_can_read(
    p_company_id UUID,
    p_created_by UUID,
    p_status TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO public
AS $$
BEGIN
    IF NOT public.check_permission(auth.uid(), 'purchase_requests', 'read') THEN
        RETURN false;
    END IF;
    IF public.check_permission(auth.uid(), 'purchase_requests', 'view_all') THEN
        RETURN true;
    END IF;
    IF auth.uid() = p_created_by THEN
        RETURN true;
    END IF;
    RETURN public.purchase_request_internal_user_is_assignee(
        p_company_id, p_status, p_created_by, auth.uid()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.purchase_request_can_read(UUID, UUID, TEXT) TO authenticated;

CREATE POLICY "pr_requests_select"
ON public.purchase_requests FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.purchase_request_can_read(company_id, created_by, status)
);

CREATE POLICY "pr_items_select"
ON public.purchase_request_items FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = purchase_request_items.request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.status)
    )
);

CREATE POLICY "pr_invoices_select"
ON public.purchase_request_invoices FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = purchase_request_invoices.request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.status)
    )
);

CREATE POLICY "pr_files_select"
ON public.purchase_request_files FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = purchase_request_files.request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.status)
    )
);

CREATE POLICY "pr_history_select"
ON public.purchase_request_history FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = purchase_request_history.request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.status)
    )
);

DROP POLICY IF EXISTS "pr_invoices_insert" ON public.purchase_request_invoices;
CREATE POLICY "pr_invoices_insert"
ON public.purchase_request_invoices FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.company_id = purchase_request_invoices.company_id
          AND r.status = 'invoice_preparation'
          AND public.purchase_request_internal_user_is_assignee(
              r.company_id, r.status, r.created_by, auth.uid()
          )
    )
);

DROP POLICY IF EXISTS "pr_invoices_update" ON public.purchase_request_invoices;
CREATE POLICY "pr_invoices_update"
ON public.purchase_request_invoices FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.status = 'invoice_preparation'
          AND public.purchase_request_internal_user_is_assignee(
              r.company_id, r.status, r.created_by, auth.uid()
          )
    )
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.status = 'invoice_preparation'
          AND public.purchase_request_internal_user_is_assignee(
              r.company_id, r.status, r.created_by, auth.uid()
          )
    )
);

DROP POLICY IF EXISTS "pr_invoices_delete" ON public.purchase_request_invoices;
CREATE POLICY "pr_invoices_delete"
ON public.purchase_request_invoices FOR DELETE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.status IN ('invoice_preparation', 'invoice_approval')
          AND public.purchase_request_internal_user_is_assignee(
              r.company_id, r.status, r.created_by, auth.uid()
          )
    )
);

DROP POLICY IF EXISTS "pr_files_insert" ON public.purchase_request_files;
CREATE POLICY "pr_files_insert"
ON public.purchase_request_files FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.company_id = purchase_request_files.company_id
          AND (
            (
                r.created_by = auth.uid()
                AND r.status IN ('draft', 'revision')
                AND public.check_permission(auth.uid(), 'purchase_requests', 'create')
            )
            OR (
                r.status = 'invoice_preparation'
                AND public.purchase_request_internal_user_is_assignee(
                    r.company_id, r.status, r.created_by, auth.uid()
                )
                AND public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
            )
            OR (
                r.status IN ('payment_queue', 'paid')
                AND public.purchase_request_internal_user_is_assignee(
                    r.company_id, r.status, r.created_by, auth.uid()
                )
                AND public.check_permission(auth.uid(), 'purchase_requests', 'payment')
            )
            OR (
                r.status = 'paid'
                AND public.purchase_request_internal_user_is_assignee(
                    r.company_id, r.status, r.created_by, auth.uid()
                )
                AND public.check_permission(auth.uid(), 'purchase_requests', 'receive')
            )
          )
    )
);

DROP POLICY IF EXISTS "pr_files_delete" ON public.purchase_request_files;
CREATE POLICY "pr_files_delete"
ON public.purchase_request_files FOR DELETE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = purchase_request_files.request_id
          AND (
            (
                r.created_by = auth.uid()
                AND r.status IN ('draft', 'revision')
            )
            OR (
                r.status = 'invoice_preparation'
                AND public.purchase_request_internal_user_is_assignee(
                    r.company_id, r.status, r.created_by, auth.uid()
                )
                AND public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
            )
          )
    )
);

-- ---------------------------------------------------------------------------
-- Workflow RPC
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_submit(
    p_request_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_approver UUID;
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

    v_approver := public.purchase_request_internal_first_role_user(
        v_row.company_id, 'first_approver'
    );
    IF v_approver IS NULL THEN
        RAISE EXCEPTION 'Не настроен первый согласующий';
    END IF;

    v_action := CASE
        WHEN v_row.status = 'draft' THEN 'submitted'
        ELSE 'resubmitted'
    END;

    v_row := public.purchase_request_internal_transition(
        p_request_id, v_row.status, 'approval', v_approver,
        v_action, p_comment, '{}'::jsonb, true, false
    );

    PERFORM public.purchase_request_internal_notify_role(
        v_row.company_id, p_request_id, 'first_approver',
        v_row.number || ' ожидает согласования',
        NULL,
        v_uid
    );

    RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_approve(
    p_request_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_preparer UUID;
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

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'approve') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_preparer := public.purchase_request_internal_first_role_user(
        v_row.company_id, 'invoice_preparer'
    );
    IF v_preparer IS NULL THEN
        RAISE EXCEPTION 'Не настроен ответственный за счёт';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'approval', 'invoice_preparation',
        v_preparer, 'approved', p_comment, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify_role(
        v_row.company_id, p_request_id, 'invoice_preparer',
        v_row.number || ' согласована. Необходимо добавить счёт',
        NULL,
        v_uid
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
SET search_path TO public
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

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
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

CREATE OR REPLACE FUNCTION public.purchase_request_submit_invoices(
    p_request_id UUID
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_approver UUID;
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

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
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

    v_approver := public.purchase_request_internal_first_role_user(
        v_row.company_id, 'invoice_approver'
    );
    IF v_approver IS NULL THEN
        RAISE EXCEPTION 'Не настроен финальный согласующий';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'invoice_preparation', 'invoice_approval',
        v_approver, 'invoices_submitted', NULL, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify_role(
        v_row.company_id, p_request_id, 'invoice_approver',
        'Счета по ' || v_row.number || ' ожидают согласования',
        NULL,
        v_uid
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
SET search_path TO public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_accountant UUID;
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

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'approve_invoice') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_accountant := public.purchase_request_internal_first_role_user(
        v_row.company_id, 'accountant'
    );
    IF v_accountant IS NULL THEN
        RAISE EXCEPTION 'Не настроен бухгалтер';
    END IF;

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'invoice_approval', 'accounting',
        v_accountant, 'invoice_approved', p_comment, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify_role(
        v_row.company_id, p_request_id, 'accountant',
        v_row.number || ' передана на оплату',
        NULL,
        v_uid
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
SET search_path TO public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_preparer UUID;
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

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'approve_invoice') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_preparer := public.purchase_request_internal_first_role_user(
        v_row.company_id, 'invoice_preparer'
    );

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'invoice_approval', 'invoice_preparation',
        v_preparer, 'invoice_returned', p_comment, '{}'::jsonb, false, false
    );

    PERFORM public.purchase_request_internal_notify_role(
        v_row.company_id, p_request_id, 'invoice_preparer',
        v_row.number || ' — счета возвращены на доработку',
        p_comment,
        v_uid
    );

    RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_queue_payment(
    p_request_id UUID,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_accountant UUID;
BEGIN
    SELECT * INTO v_row
    FROM public.purchase_requests
    WHERE id = p_request_id
    FOR UPDATE;

    IF v_row.status <> 'accounting' THEN
        RAISE EXCEPTION 'Недопустимый статус';
    END IF;

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF NOT public.check_permission(v_uid, 'purchase_requests', 'payment') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_accountant := public.purchase_request_internal_first_role_user(
        v_row.company_id, 'accountant'
    );

    v_row := public.purchase_request_internal_transition(
        p_request_id, 'accounting', 'payment_queue',
        v_accountant, 'queued_for_payment', p_comment, '{}'::jsonb, false, false
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
SET search_path TO public
AS $$
DECLARE
    v_row public.purchase_requests;
    v_uid UUID := auth.uid();
    v_receiver UUID;
    v_mode TEXT;
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

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
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

    SELECT s.receiver_mode INTO v_mode
    FROM public.purchase_request_settings s
    WHERE s.company_id = v_row.company_id;

    IF v_mode = 'fixed_user' THEN
        PERFORM public.purchase_request_internal_notify_role(
            v_row.company_id, p_request_id, 'receiver',
            v_row.number || ' оплачена. Подтвердите получение',
            NULL,
            v_uid
        );
    ELSIF v_receiver IS NOT NULL AND v_receiver IS DISTINCT FROM v_uid THEN
        PERFORM public.purchase_request_internal_notify(
            v_row.company_id, p_request_id, v_receiver,
            v_row.number || ' оплачена. Подтвердите получение',
            NULL
        );
    END IF;

    RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_request_mark_received(
    p_request_id UUID,
    p_received_date DATE DEFAULT NULL,
    p_comment TEXT DEFAULT NULL
)
RETURNS public.purchase_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
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

    IF NOT public.purchase_request_internal_user_is_assignee(
        v_row.company_id, v_row.status, v_row.created_by, v_uid
    ) THEN
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
        SELECT r.*
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
            p_filter = 'all'
            OR (p_filter = 'pending_approval' AND r.status = 'approval')
            OR (p_filter = 'approved' AND r.status IN (
                'invoice_preparation',
                'invoice_approval',
                'accounting',
                'payment_queue',
                'paid'
            ))
            OR (p_filter = 'archive' AND r.status IN ('received', 'cancelled'))
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

DROP FUNCTION IF EXISTS public.purchase_request_upsert_settings(
    UUID, UUID, UUID, UUID, UUID, TEXT, UUID
);

CREATE FUNCTION public.purchase_request_upsert_settings(
    p_company_id UUID,
    p_first_approver_ids UUID[],
    p_invoice_preparer_ids UUID[],
    p_invoice_approver_ids UUID[],
    p_accountant_ids UUID[],
    p_receiver_mode TEXT DEFAULT 'initiator',
    p_fixed_receiver_ids UUID[] DEFAULT '{}'::UUID[]
)
RETURNS public.purchase_request_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
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

    IF p_first_approver_ids IS NULL OR cardinality(p_first_approver_ids) = 0
        OR p_invoice_preparer_ids IS NULL OR cardinality(p_invoice_preparer_ids) = 0
        OR p_invoice_approver_ids IS NULL OR cardinality(p_invoice_approver_ids) = 0
        OR p_accountant_ids IS NULL OR cardinality(p_accountant_ids) = 0 THEN
        RAISE EXCEPTION 'Укажите всех участников маршрута';
    END IF;

    IF p_receiver_mode = 'fixed_user'
        AND (p_fixed_receiver_ids IS NULL OR cardinality(p_fixed_receiver_ids) = 0) THEN
        RAISE EXCEPTION 'Укажите ответственного за получение';
    END IF;

    PERFORM public.purchase_request_internal_assert_route_users(
        p_company_id, p_first_approver_ids
    );
    PERFORM public.purchase_request_internal_assert_route_users(
        p_company_id, p_invoice_preparer_ids
    );
    PERFORM public.purchase_request_internal_assert_route_users(
        p_company_id, p_invoice_approver_ids
    );
    PERFORM public.purchase_request_internal_assert_route_users(
        p_company_id, p_accountant_ids
    );
    IF p_receiver_mode = 'fixed_user' THEN
        PERFORM public.purchase_request_internal_assert_route_users(
            p_company_id, p_fixed_receiver_ids
        );
    END IF;

    INSERT INTO public.purchase_request_settings (
        company_id, receiver_mode, updated_by
    ) VALUES (
        p_company_id, p_receiver_mode, v_uid
    )
    ON CONFLICT (company_id) DO UPDATE SET
        receiver_mode = EXCLUDED.receiver_mode,
        updated_by = v_uid,
        updated_at = now()
    RETURNING * INTO v_row;

    PERFORM public.purchase_request_internal_replace_role_members(
        p_company_id, 'first_approver', p_first_approver_ids
    );
    PERFORM public.purchase_request_internal_replace_role_members(
        p_company_id, 'invoice_preparer', p_invoice_preparer_ids
    );
    PERFORM public.purchase_request_internal_replace_role_members(
        p_company_id, 'invoice_approver', p_invoice_approver_ids
    );
    PERFORM public.purchase_request_internal_replace_role_members(
        p_company_id, 'accountant', p_accountant_ids
    );
    IF p_receiver_mode = 'fixed_user' THEN
        PERFORM public.purchase_request_internal_replace_role_members(
            p_company_id, 'receiver', p_fixed_receiver_ids
        );
    ELSE
        PERFORM public.purchase_request_internal_replace_role_members(
            p_company_id, 'receiver', '{}'::UUID[]
        );
    END IF;

    RETURN v_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.purchase_request_upsert_settings(
    UUID, UUID[], UUID[], UUID[], UUID[], TEXT, UUID[]
) TO authenticated;

-- Колонки одиночных id больше не используются
ALTER TABLE public.purchase_request_settings
    DROP CONSTRAINT IF EXISTS purchase_request_settings_fixed_receiver_chk,
    DROP CONSTRAINT IF EXISTS purchase_request_settings_first_approver_id_fkey,
    DROP CONSTRAINT IF EXISTS purchase_request_settings_invoice_preparer_id_fkey,
    DROP CONSTRAINT IF EXISTS purchase_request_settings_invoice_approver_id_fkey,
    DROP CONSTRAINT IF EXISTS purchase_request_settings_accountant_id_fkey,
    DROP CONSTRAINT IF EXISTS purchase_request_settings_fixed_receiver_id_fkey;

ALTER TABLE public.purchase_request_settings
    DROP COLUMN IF EXISTS first_approver_id,
    DROP COLUMN IF EXISTS invoice_preparer_id,
    DROP COLUMN IF EXISTS invoice_approver_id,
    DROP COLUMN IF EXISTS accountant_id,
    DROP COLUMN IF EXISTS fixed_receiver_id;

COMMIT;

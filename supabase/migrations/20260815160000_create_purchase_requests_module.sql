-- Модуль «Заявки на закупку»: таблицы, RLS, Storage, RBAC.
-- Единицы измерения позиций — TEXT (unit). Настройки согласующих — одна строка на company.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- Настройки модуля (одна строка на компанию)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_settings (
    company_id UUID PRIMARY KEY REFERENCES public.companies(id) ON DELETE CASCADE,
    first_approver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    invoice_preparer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    invoice_approver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    accountant_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    receiver_mode TEXT NOT NULL DEFAULT 'initiator'
        CHECK (receiver_mode IN ('initiator', 'fixed_user')),
    fixed_receiver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT purchase_request_settings_fixed_receiver_chk CHECK (
        receiver_mode <> 'fixed_user'
        OR fixed_receiver_id IS NOT NULL
    )
);

COMMENT ON TABLE public.purchase_request_settings IS
    'Настройки маршрута заявок на закупку: назначенные участники процесса на компанию.';

-- ---------------------------------------------------------------------------
-- Нумерация ЗП-YYYY-NNNNN
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_number_seq (
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    year INT NOT NULL,
    last_value INT NOT NULL DEFAULT 0,
    PRIMARY KEY (company_id, year)
);

-- ---------------------------------------------------------------------------
-- Заявки
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    number TEXT NOT NULL,
    object_id UUID NOT NULL REFERENCES public.objects(id),
    created_by UUID NOT NULL REFERENCES auth.users(id),
    current_assignee_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'draft',
    comment TEXT,
    total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    submitted_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    CONSTRAINT purchase_requests_number_company_uq UNIQUE (company_id, number),
    CONSTRAINT purchase_requests_status_chk CHECK (
        status IN (
            'draft', 'approval', 'revision', 'invoice_preparation',
            'invoice_approval', 'accounting', 'payment_queue', 'paid',
            'received', 'cancelled'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_purchase_requests_company_status
    ON public.purchase_requests (company_id, status);

CREATE INDEX IF NOT EXISTS idx_purchase_requests_assignee
    ON public.purchase_requests (company_id, current_assignee_id)
    WHERE status NOT IN ('received', 'cancelled');

CREATE INDEX IF NOT EXISTS idx_purchase_requests_created_by
    ON public.purchase_requests (company_id, created_by, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_purchase_requests_object
    ON public.purchase_requests (company_id, object_id);

CREATE INDEX IF NOT EXISTS idx_purchase_requests_number_trgm
    ON public.purchase_requests USING gin (number gin_trgm_ops);

COMMENT ON TABLE public.purchase_requests IS
    'Заявки на закупку материалов и оборудования. Статус меняется только через RPC.';

-- ---------------------------------------------------------------------------
-- Позиции заявки
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.purchase_requests(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity NUMERIC(14, 3) NOT NULL CHECK (quantity > 0),
    unit TEXT NOT NULL DEFAULT 'шт',
    comment TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT purchase_request_items_name_chk CHECK (btrim(name) <> '')
);

CREATE INDEX IF NOT EXISTS idx_purchase_request_items_request
    ON public.purchase_request_items (request_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_purchase_request_items_name_trgm
    ON public.purchase_request_items USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- Счета
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.purchase_requests(id) ON DELETE CASCADE,
    supplier_id UUID NOT NULL REFERENCES public.contractors(id),
    invoice_number TEXT,
    invoice_date DATE,
    amount NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    comment TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_request_invoices_request
    ON public.purchase_request_invoices (request_id);

CREATE INDEX IF NOT EXISTS idx_purchase_request_invoices_supplier
    ON public.purchase_request_invoices (company_id, supplier_id);

-- ---------------------------------------------------------------------------
-- Файлы
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.purchase_requests(id) ON DELETE CASCADE,
    invoice_id UUID REFERENCES public.purchase_request_invoices(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT,
    size BIGINT CHECK (size IS NULL OR size >= 0),
    uploaded_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT purchase_request_files_type_chk CHECK (
        type IN (
            'request_attachment', 'invoice', 'payment', 'upd',
            'waybill', 'receipt', 'photo', 'other'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_purchase_request_files_request
    ON public.purchase_request_files (request_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_purchase_request_files_invoice
    ON public.purchase_request_files (invoice_id)
    WHERE invoice_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- История (неизменяемая)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.purchase_requests(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    action TEXT NOT NULL,
    from_status TEXT,
    to_status TEXT,
    comment TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_request_history_request
    ON public.purchase_request_history (request_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- In-app уведомления
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.purchase_request_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    request_id UUID NOT NULL REFERENCES public.purchase_requests(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_request_notifications_user
    ON public.purchase_request_notifications (user_id, is_read, created_at DESC);

-- ---------------------------------------------------------------------------
-- Пересчёт total_amount при изменении счетов
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_recalc_total_amount()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.purchase_requests r
    SET
        total_amount = COALESCE(
            (
                SELECT SUM(i.amount)
                FROM public.purchase_request_invoices i
                WHERE i.request_id = COALESCE(NEW.request_id, OLD.request_id)
            ),
            0
        ),
        updated_at = now()
    WHERE r.id = COALESCE(NEW.request_id, OLD.request_id);
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_purchase_request_invoices_recalc_total
    ON public.purchase_request_invoices;
CREATE TRIGGER trg_purchase_request_invoices_recalc_total
    AFTER INSERT OR UPDATE OF amount OR DELETE
    ON public.purchase_request_invoices
    FOR EACH ROW
    EXECUTE FUNCTION public.purchase_request_recalc_total_amount();

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_purchase_requests_updated_at ON public.purchase_requests;
CREATE TRIGGER trg_purchase_requests_updated_at
    BEFORE UPDATE ON public.purchase_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_purchase_request_invoices_updated_at
    ON public.purchase_request_invoices;
CREATE TRIGGER trg_purchase_request_invoices_updated_at
    BEFORE UPDATE ON public.purchase_request_invoices
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_purchase_request_settings_updated_at
    ON public.purchase_request_settings;
CREATE TRIGGER trg_purchase_request_settings_updated_at
    BEFORE UPDATE ON public.purchase_request_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS: helper — пользователь может читать заявку
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purchase_request_can_read(
    p_company_id UUID,
    p_created_by UUID,
    p_assignee_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.check_permission(auth.uid(), 'purchase_requests', 'read') THEN
        RETURN false;
    END IF;
    IF public.check_permission(auth.uid(), 'purchase_requests', 'view_all') THEN
        RETURN true;
    END IF;
    RETURN auth.uid() = p_created_by OR auth.uid() = p_assignee_id;
END;
$$;

REVOKE ALL ON FUNCTION public.purchase_request_can_read(UUID, UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_request_can_read(UUID, UUID, UUID) TO authenticated;

-- ---------------------------------------------------------------------------
-- RLS policies
-- ---------------------------------------------------------------------------
ALTER TABLE public.purchase_request_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_request_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_request_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_request_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_request_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_request_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pr_settings_select" ON public.purchase_request_settings;
CREATE POLICY "pr_settings_select"
ON public.purchase_request_settings FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'read')
);

DROP POLICY IF EXISTS "pr_settings_insert" ON public.purchase_request_settings;
CREATE POLICY "pr_settings_insert"
ON public.purchase_request_settings FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'view_all')
);

DROP POLICY IF EXISTS "pr_settings_update" ON public.purchase_request_settings;
CREATE POLICY "pr_settings_update"
ON public.purchase_request_settings FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'view_all')
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'view_all')
);

DROP POLICY IF EXISTS "pr_requests_select" ON public.purchase_requests;
CREATE POLICY "pr_requests_select"
ON public.purchase_requests FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.purchase_request_can_read(company_id, created_by, current_assignee_id)
);

DROP POLICY IF EXISTS "pr_items_select" ON public.purchase_request_items;
CREATE POLICY "pr_items_select"
ON public.purchase_request_items FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.current_assignee_id)
    )
);

DROP POLICY IF EXISTS "pr_invoices_select" ON public.purchase_request_invoices;
CREATE POLICY "pr_invoices_select"
ON public.purchase_request_invoices FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.current_assignee_id)
    )
);

DROP POLICY IF EXISTS "pr_files_select" ON public.purchase_request_files;
CREATE POLICY "pr_files_select"
ON public.purchase_request_files FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.current_assignee_id)
    )
);

DROP POLICY IF EXISTS "pr_history_select" ON public.purchase_request_history;
CREATE POLICY "pr_history_select"
ON public.purchase_request_history FOR SELECT TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND public.purchase_request_can_read(r.company_id, r.created_by, r.current_assignee_id)
    )
);

DROP POLICY IF EXISTS "pr_notifications_select" ON public.purchase_request_notifications;
CREATE POLICY "pr_notifications_select"
ON public.purchase_request_notifications FOR SELECT TO authenticated
USING (
    user_id = auth.uid()
    AND company_id IN (SELECT public.get_my_company_ids())
);

DROP POLICY IF EXISTS "pr_notifications_update" ON public.purchase_request_notifications;
CREATE POLICY "pr_notifications_update"
ON public.purchase_request_notifications FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Прямые INSERT/UPDATE/DELETE на заявки и историю — только через RPC
REVOKE INSERT, UPDATE, DELETE ON public.purchase_requests FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.purchase_request_history FROM authenticated;
GRANT SELECT ON public.purchase_requests TO authenticated;
GRANT SELECT ON public.purchase_request_history TO authenticated;

-- Позиции: редактирование инициатором в draft/revision
DROP POLICY IF EXISTS "pr_items_insert" ON public.purchase_request_items;
CREATE POLICY "pr_items_insert"
ON public.purchase_request_items FOR INSERT TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'create')
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.company_id = purchase_request_items.company_id
          AND r.created_by = auth.uid()
          AND r.status IN ('draft', 'revision')
    )
);

DROP POLICY IF EXISTS "pr_items_update" ON public.purchase_request_items;
CREATE POLICY "pr_items_update"
ON public.purchase_request_items FOR UPDATE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.created_by = auth.uid()
          AND r.status IN ('draft', 'revision')
    )
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.created_by = auth.uid()
          AND r.status IN ('draft', 'revision')
    )
);

DROP POLICY IF EXISTS "pr_items_delete" ON public.purchase_request_items;
CREATE POLICY "pr_items_delete"
ON public.purchase_request_items FOR DELETE TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.created_by = auth.uid()
          AND r.status IN ('draft', 'revision')
    )
);

-- Счета: ответственный за закупку в invoice_preparation
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
          AND r.current_assignee_id = auth.uid()
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
          AND r.current_assignee_id = auth.uid()
    )
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND EXISTS (
        SELECT 1 FROM public.purchase_requests r
        WHERE r.id = request_id
          AND r.status = 'invoice_preparation'
          AND r.current_assignee_id = auth.uid()
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
          AND r.current_assignee_id = auth.uid()
    )
);

-- Файлы: вложения в draft/revision (инициатор) или по этапу процесса
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
                AND r.current_assignee_id = auth.uid()
                AND public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
            )
            OR (
                r.status IN ('payment_queue', 'paid')
                AND r.current_assignee_id = auth.uid()
                AND public.check_permission(auth.uid(), 'purchase_requests', 'payment')
            )
            OR (
                r.status = 'paid'
                AND r.current_assignee_id = auth.uid()
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
        WHERE r.id = request_id
          AND (
            (
                r.created_by = auth.uid()
                AND r.status IN ('draft', 'revision')
            )
            OR (
                r.status = 'invoice_preparation'
                AND r.current_assignee_id = auth.uid()
                AND public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
            )
        )
    )
);

-- ---------------------------------------------------------------------------
-- Storage bucket purchase_requests
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
SELECT 'purchase_requests', 'purchase_requests', false
WHERE NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'purchase_requests'
);

DROP POLICY IF EXISTS "purchase_requests_bucket_select" ON storage.objects;
CREATE POLICY "purchase_requests_bucket_select"
ON storage.objects FOR SELECT TO authenticated
USING (
    bucket_id = 'purchase_requests'
    AND (storage.foldername(name))[1]::uuid IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'read')
);

DROP POLICY IF EXISTS "purchase_requests_bucket_insert" ON storage.objects;
CREATE POLICY "purchase_requests_bucket_insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'purchase_requests'
    AND (storage.foldername(name))[1]::uuid IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'purchase_requests', 'create')
);

DROP POLICY IF EXISTS "purchase_requests_bucket_delete" ON storage.objects;
CREATE POLICY "purchase_requests_bucket_delete"
ON storage.objects FOR DELETE TO authenticated
USING (
    bucket_id = 'purchase_requests'
    AND (storage.foldername(name))[1]::uuid IN (SELECT public.get_my_company_ids())
    AND (
        public.check_permission(auth.uid(), 'purchase_requests', 'create')
        OR public.check_permission(auth.uid(), 'purchase_requests', 'prepare_invoice')
        OR public.check_permission(auth.uid(), 'purchase_requests', 'payment')
        OR public.check_permission(auth.uid(), 'purchase_requests', 'receive')
    )
);

-- ---------------------------------------------------------------------------
-- app_modules
-- ---------------------------------------------------------------------------
INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('purchase_requests', 'Заявки на закупку', 'cart', 56, true)
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    icon_key = EXCLUDED.icon_key,
    sort_order = EXCLUDED.sort_order,
    is_active = true;

-- Базовые права read для ролей с доступом к объектам
INSERT INTO public.role_permissions (role_id, company_id, module_code, permission_code, is_enabled)
SELECT rp.role_id, rp.company_id, 'purchase_requests'::text, 'read'::text, true
FROM public.role_permissions rp
WHERE rp.module_code = 'objects'
  AND rp.permission_code = 'read'
  AND rp.is_enabled = true
  AND NOT EXISTS (
    SELECT 1
    FROM public.role_permissions e
    WHERE e.role_id = rp.role_id
      AND e.module_code = 'purchase_requests'
      AND e.permission_code = 'read'
      AND (e.company_id IS NOT DISTINCT FROM rp.company_id)
  );

COMMIT;

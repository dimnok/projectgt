-- Взаиморасчёты: операции (акт / аванс / прочее).
-- Параллельно существующим contract_acts; не заменяет КС-2.

BEGIN;

CREATE TABLE IF NOT EXISTS public.settlement_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    operation_type TEXT NOT NULL,
    object_id UUID NOT NULL REFERENCES public.objects(id),
    contractor_id UUID NOT NULL REFERENCES public.contractors(id),
    contract_id UUID NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    period_from DATE,
    period_to DATE,
    act_number TEXT,
    act_date DATE,
    invoice_number TEXT NOT NULL,
    invoice_date DATE NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0 CHECK (amount >= 0),
    vat_amount NUMERIC NOT NULL DEFAULT 0 CHECK (vat_amount >= 0),
    advance_retention NUMERIC NOT NULL DEFAULT 0 CHECK (advance_retention >= 0),
    warranty_retention NUMERIC NOT NULL DEFAULT 0 CHECK (warranty_retention >= 0),
    total_to_pay NUMERIC GENERATED ALWAYS AS (
        GREATEST(
            0::NUMERIC,
            amount + vat_amount - advance_retention - warranty_retention
        )
    ) STORED,
    paid_amount NUMERIC NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    payment_status TEXT NOT NULL DEFAULT 'unpaid',
    purpose TEXT,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT settlement_operations_type_chk CHECK (
        operation_type IN ('act', 'advance', 'other')
    ),
    CONSTRAINT settlement_operations_payment_status_chk CHECK (
        payment_status IN ('unpaid', 'partial', 'paid', 'overpaid')
    ),
    CONSTRAINT settlement_operations_period_chk CHECK (
        period_from IS NULL
        OR period_to IS NULL
        OR period_to >= period_from
    ),
    CONSTRAINT settlement_operations_act_fields_chk CHECK (
        (
            operation_type = 'act'
            AND act_number IS NOT NULL
            AND btrim(act_number) <> ''
            AND act_date IS NOT NULL
            AND period_from IS NOT NULL
            AND period_to IS NOT NULL
        )
        OR (
            operation_type IN ('advance', 'other')
            AND act_number IS NULL
            AND act_date IS NULL
            AND advance_retention = 0
            AND warranty_retention = 0
        )
    ),
    CONSTRAINT settlement_operations_other_purpose_chk CHECK (
        operation_type <> 'other'
        OR (purpose IS NOT NULL AND btrim(purpose) <> '')
    )
);

CREATE INDEX IF NOT EXISTS idx_settlement_operations_company
    ON public.settlement_operations (company_id);

CREATE INDEX IF NOT EXISTS idx_settlement_operations_contract
    ON public.settlement_operations (contract_id, invoice_date DESC);

CREATE INDEX IF NOT EXISTS idx_settlement_operations_status
    ON public.settlement_operations (company_id, payment_status);

CREATE INDEX IF NOT EXISTS idx_settlement_operations_type
    ON public.settlement_operations (company_id, operation_type);

COMMENT ON TABLE public.settlement_operations IS
    'Взаиморасчёты: операции учёта счетов и оплат (акт / аванс / прочее).';
COMMENT ON COLUMN public.settlement_operations.operation_type IS 'act | advance | other';
COMMENT ON COLUMN public.settlement_operations.payment_status IS 'unpaid | partial | paid | overpaid';
COMMENT ON COLUMN public.settlement_operations.total_to_pay IS
    'Генерируется: amount + vat − авансовые − гарантийные, не ниже 0';

ALTER TABLE public.settlement_operations ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS trg_settlement_operations_updated_at
    ON public.settlement_operations;
CREATE TRIGGER trg_settlement_operations_updated_at
    BEFORE UPDATE ON public.settlement_operations
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP POLICY IF EXISTS "Strict SELECT for settlement_operations"
    ON public.settlement_operations;
CREATE POLICY "Strict SELECT for settlement_operations"
ON public.settlement_operations FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for settlement_operations"
    ON public.settlement_operations;
CREATE POLICY "Strict INSERT for settlement_operations"
ON public.settlement_operations FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'create')
);

DROP POLICY IF EXISTS "Strict UPDATE for settlement_operations"
    ON public.settlement_operations;
CREATE POLICY "Strict UPDATE for settlement_operations"
ON public.settlement_operations FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
);

DROP POLICY IF EXISTS "Strict DELETE for settlement_operations"
    ON public.settlement_operations;
CREATE POLICY "Strict DELETE for settlement_operations"
ON public.settlement_operations FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'delete')
);

INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('settlements', 'Взаиморасчёты', 'money_dollar_circle', 92, true)
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    icon_key = EXCLUDED.icon_key,
    sort_order = EXCLUDED.sort_order,
    is_active = true;

-- Копируем права с contracts на settlements для уже существующих ролей.
INSERT INTO public.role_permissions (role_id, company_id, module_code, permission_code, is_enabled)
SELECT s.role_id, s.company_id, 'settlements'::text, s.permission_code, s.is_enabled
FROM public.role_permissions s
WHERE s.module_code = 'contracts'
  AND NOT EXISTS (
    SELECT 1
    FROM public.role_permissions e
    WHERE e.role_id = s.role_id
      AND e.module_code = 'settlements'
      AND e.permission_code = s.permission_code
      AND (e.company_id IS NOT DISTINCT FROM s.company_id)
  );

COMMIT;

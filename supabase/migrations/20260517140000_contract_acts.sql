-- Реестр актов по договору (ручной ввод сумм, удержаний, статусов).
-- Отдельно от ks2_acts (КС-2 с привязкой к работам).

BEGIN;

CREATE TABLE IF NOT EXISTS public.contract_acts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    contract_id UUID NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    number TEXT NOT NULL,
    act_date DATE NOT NULL,
    period_from DATE NOT NULL,
    period_to DATE NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0,
    vat_amount NUMERIC NOT NULL DEFAULT 0,
    advance_retention NUMERIC NOT NULL DEFAULT 0,
    warranty_retention NUMERIC NOT NULL DEFAULT 0,
    other_retentions NUMERIC NOT NULL DEFAULT 0,
    total_to_pay NUMERIC GENERATED ALWAYS AS (
        GREATEST(
            0::NUMERIC,
            amount + vat_amount - advance_retention - warranty_retention - other_retentions
        )
    ) STORED,
    note TEXT,
    workflow_status TEXT NOT NULL DEFAULT 'pending_approval',
    payment_status TEXT NOT NULL DEFAULT 'unpaid',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT contract_acts_period_chk CHECK (period_to >= period_from),
    CONSTRAINT contract_acts_workflow_status_chk CHECK (
        workflow_status IN ('pending_approval', 'approved', 'signed')
    ),
    CONSTRAINT contract_acts_payment_status_chk CHECK (
        payment_status IN ('paid', 'partial', 'unpaid')
    )
);

CREATE INDEX IF NOT EXISTS idx_contract_acts_contract
    ON public.contract_acts (contract_id, act_date DESC);

CREATE INDEX IF NOT EXISTS idx_contract_acts_company
    ON public.contract_acts (company_id);

COMMENT ON TABLE public.contract_acts IS 'Акты по договору (реестр; не КС-2).';
COMMENT ON COLUMN public.contract_acts.workflow_status IS 'pending_approval | approved | signed';
COMMENT ON COLUMN public.contract_acts.payment_status IS 'paid | partial | unpaid';
COMMENT ON COLUMN public.contract_acts.total_to_pay IS 'Генерируется: amount + vat − удержания, не ниже 0';

ALTER TABLE public.contract_acts ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS trg_contract_acts_updated_at ON public.contract_acts;
CREATE TRIGGER trg_contract_acts_updated_at
    BEFORE UPDATE ON public.contract_acts
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP POLICY IF EXISTS "Strict SELECT for contract_acts" ON public.contract_acts;
CREATE POLICY "Strict SELECT for contract_acts"
ON public.contract_acts FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for contract_acts" ON public.contract_acts;
CREATE POLICY "Strict INSERT for contract_acts"
ON public.contract_acts FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'update')
);

DROP POLICY IF EXISTS "Strict UPDATE for contract_acts" ON public.contract_acts;
CREATE POLICY "Strict UPDATE for contract_acts"
ON public.contract_acts FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'update')
);

DROP POLICY IF EXISTS "Strict DELETE for contract_acts" ON public.contract_acts;
CREATE POLICY "Strict DELETE for contract_acts"
ON public.contract_acts FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'delete')
);

COMMIT;

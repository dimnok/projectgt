-- Строки актов КС-2: фиксированные объёмы по позициям сметы (снимок при создании акта).

BEGIN;

CREATE TABLE IF NOT EXISTS public.contract_act_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    contract_id UUID NOT NULL REFERENCES public.contracts(id) ON DELETE CASCADE,
    contract_act_id UUID NOT NULL REFERENCES public.contract_acts(id) ON DELETE CASCADE,
    estimate_item_id UUID REFERENCES public.estimates(id) ON DELETE SET NULL,
    vor_item_id UUID REFERENCES public.vor_items(id) ON DELETE SET NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    estimate_number TEXT NOT NULL DEFAULT '',
    section_title TEXT NOT NULL DEFAULT '',
    name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT '',
    quantity DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    price NUMERIC NOT NULL DEFAULT 0,
    amount NUMERIC NOT NULL DEFAULT 0,
    backlog_quantity DOUBLE PRECISION NOT NULL DEFAULT 0,
    current_period_quantity DOUBLE PRECISION NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_contract_act_lines_act
    ON public.contract_act_lines (contract_act_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_contract_act_lines_contract_estimate
    ON public.contract_act_lines (contract_id, estimate_item_id);

CREATE INDEX IF NOT EXISTS idx_contract_act_lines_company
    ON public.contract_act_lines (company_id);

COMMENT ON TABLE public.contract_act_lines IS
    'Строки акта КС-2: объёмы и суммы по позициям сметы на момент формирования акта.';
COMMENT ON COLUMN public.contract_act_lines.backlog_quantity IS
    'Часть количества, перенесённая из превышения прошлых подписанных ВОР.';
COMMENT ON COLUMN public.contract_act_lines.current_period_quantity IS
    'Часть количества за период текущей ВОР (без переноса).';

ALTER TABLE public.contract_act_lines ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS trg_contract_act_lines_updated_at ON public.contract_act_lines;
CREATE TRIGGER trg_contract_act_lines_updated_at
    BEFORE UPDATE ON public.contract_act_lines
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP POLICY IF EXISTS "Strict SELECT for contract_act_lines" ON public.contract_act_lines;
CREATE POLICY "Strict SELECT for contract_act_lines"
ON public.contract_act_lines FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for contract_act_lines" ON public.contract_act_lines;
CREATE POLICY "Strict INSERT for contract_act_lines"
ON public.contract_act_lines FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'update')
);

DROP POLICY IF EXISTS "Strict UPDATE for contract_act_lines" ON public.contract_act_lines;
CREATE POLICY "Strict UPDATE for contract_act_lines"
ON public.contract_act_lines FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'update')
);

DROP POLICY IF EXISTS "Strict DELETE for contract_act_lines" ON public.contract_act_lines;
CREATE POLICY "Strict DELETE for contract_act_lines"
ON public.contract_act_lines FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'contracts', 'delete')
);

COMMIT;

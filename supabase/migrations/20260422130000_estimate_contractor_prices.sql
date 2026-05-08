-- Расценки подрядчика по позициям смет: цена за единицу для пары (строка сметы × контрагент).
-- Модуль «Подрядчики» / импорт из Excel: upsert по estimate_id + contractor_id.

BEGIN;

CREATE TABLE IF NOT EXISTS public.estimate_contractor_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    estimate_id UUID NOT NULL REFERENCES public.estimates(id) ON DELETE CASCADE,
    contractor_id UUID NOT NULL REFERENCES public.contractors(id) ON DELETE CASCADE,
    unit_price DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT estimate_contractor_prices_unit_price_non_negative
        CHECK (unit_price >= 0::double precision),
    CONSTRAINT estimate_contractor_prices_estimate_contractor_uniq
        UNIQUE (estimate_id, contractor_id)
);

COMMENT ON TABLE public.estimate_contractor_prices IS
    'Расценка подрядчика (цена за ед.) по позиции сметы: одна запись на пару (estimate_id, contractor_id) в рамках company_id.';

COMMENT ON COLUMN public.estimate_contractor_prices.unit_price IS
    'Цена подрядчика за единицу измерения позиции сметы (как plan price в estimates).';

CREATE INDEX IF NOT EXISTS idx_estimate_contractor_prices_company
    ON public.estimate_contractor_prices(company_id);

CREATE INDEX IF NOT EXISTS idx_estimate_contractor_prices_estimate
    ON public.estimate_contractor_prices(estimate_id);

CREATE INDEX IF NOT EXISTS idx_estimate_contractor_prices_contractor
    ON public.estimate_contractor_prices(contractor_id);

ALTER TABLE public.estimate_contractor_prices ENABLE ROW LEVEL SECURITY;

-- SELECT: своя компания + право на модуль contractors (read)
DROP POLICY IF EXISTS "contractors_select estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_select estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR SELECT
    TO authenticated
    USING (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'contractors', 'read')
    );

-- INSERT: company_id совпадает с позицией сметы и с контрагентом; права create
DROP POLICY IF EXISTS "contractors_insert estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_insert estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR INSERT
    TO authenticated
    WITH CHECK (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'contractors', 'create')
        AND EXISTS (
            SELECT 1
            FROM public.estimates e
            WHERE e.id = estimate_id
              AND e.company_id = company_id
        )
        AND EXISTS (
            SELECT 1
            FROM public.contractors c
            WHERE c.id = contractor_id
              AND c.company_id = company_id
        )
    );

-- UPDATE: те же связи, права update
DROP POLICY IF EXISTS "contractors_update estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_update estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR UPDATE
    TO authenticated
    USING (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'contractors', 'update')
    )
    WITH CHECK (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'contractors', 'update')
        AND EXISTS (
            SELECT 1
            FROM public.estimates e
            WHERE e.id = estimate_id
              AND e.company_id = company_id
        )
        AND EXISTS (
            SELECT 1
            FROM public.contractors c
            WHERE c.id = contractor_id
              AND c.company_id = company_id
        )
    );

-- DELETE
DROP POLICY IF EXISTS "contractors_delete estimate_contractor_prices" ON public.estimate_contractor_prices;
CREATE POLICY "contractors_delete estimate_contractor_prices"
    ON public.estimate_contractor_prices
    FOR DELETE
    TO authenticated
    USING (
        company_id IN (SELECT public.get_my_company_ids())
        AND public.check_permission(auth.uid(), 'contractors', 'delete')
    );

-- updated_at (функция уже есть в проекте)
CREATE TRIGGER tr_estimate_contractor_prices_updated_at
    BEFORE UPDATE ON public.estimate_contractor_prices
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

COMMIT;

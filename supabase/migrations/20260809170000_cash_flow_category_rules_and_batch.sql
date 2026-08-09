-- Правила автосопоставления категорий ДДС и пакетная обработка банковских выписок.

BEGIN;

-- ---------------------------------------------------------------------------
-- Таблица правил: ключевое слово в назначении платежа → статья ДДС
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cash_flow_category_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES public.cash_flow_categories(id) ON DELETE CASCADE,
    keyword TEXT NOT NULL,
    operation_type TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT cash_flow_category_rules_operation_type_chk
        CHECK (operation_type = ANY (ARRAY['income'::text, 'expense'::text])),
    CONSTRAINT cash_flow_category_rules_keyword_nonempty
        CHECK (length(trim(keyword)) > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_cash_flow_category_rules_unique_keyword
    ON public.cash_flow_category_rules (
        company_id,
        operation_type,
        lower(trim(keyword))
    );

CREATE INDEX IF NOT EXISTS idx_cash_flow_category_rules_company
    ON public.cash_flow_category_rules (company_id, operation_type, priority DESC);

COMMENT ON TABLE public.cash_flow_category_rules IS
    'Правила автосопоставления статей ДДС по ключевым словам в назначении платежа.';

ALTER TABLE public.cash_flow_category_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view category rules of their companies"
    ON public.cash_flow_category_rules;
CREATE POLICY "Users can view category rules of their companies"
    ON public.cash_flow_category_rules FOR SELECT
    USING (company_id IN (SELECT public.get_my_company_ids()));

DROP POLICY IF EXISTS "Users can insert category rules for their companies"
    ON public.cash_flow_category_rules;
CREATE POLICY "Users can insert category rules for their companies"
    ON public.cash_flow_category_rules FOR INSERT
    WITH CHECK (company_id IN (SELECT public.get_my_company_ids()));

DROP POLICY IF EXISTS "Users can update category rules of their companies"
    ON public.cash_flow_category_rules;
CREATE POLICY "Users can update category rules of their companies"
    ON public.cash_flow_category_rules FOR UPDATE
    USING (company_id IN (SELECT public.get_my_company_ids()));

DROP POLICY IF EXISTS "Users can delete category rules of their companies"
    ON public.cash_flow_category_rules;
CREATE POLICY "Users can delete category rules of their companies"
    ON public.cash_flow_category_rules FOR DELETE
    USING (company_id IN (SELECT public.get_my_company_ids()));

-- ---------------------------------------------------------------------------
-- Контекст для автосопоставления (один запрос вместо множества)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_bank_statement_matching_context(
    p_company_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result JSONB;
BEGIN
    IF p_company_id IS NULL
        OR NOT p_company_id IN (SELECT public.get_my_company_ids()) THEN
        RAISE EXCEPTION 'Доступ к данным компании запрещён';
    END IF;

    SELECT jsonb_build_object(
        'contractor_hints',
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'contractor_id', contractor_id,
                        'contract_id', contract_id,
                        'object_id', object_id,
                        'category_id', category_id
                    )
                )
                FROM (
                    SELECT DISTINCT ON (contractor_id)
                        contractor_id,
                        contract_id,
                        object_id,
                        category_id
                    FROM public.cash_flow
                    WHERE company_id = p_company_id
                      AND contractor_id IS NOT NULL
                    ORDER BY contractor_id, date DESC, created_at DESC
                ) hints
            ),
            '[]'::jsonb
        ),
        'open_settlements',
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', id,
                        'contract_id', contract_id,
                        'contractor_id', contractor_id,
                        'remaining_amount', (total_to_pay - paid_amount),
                        'invoice_number', invoice_number,
                        'invoice_date', invoice_date
                    )
                    ORDER BY invoice_date ASC
                )
                FROM public.settlement_operations
                WHERE company_id = p_company_id
                  AND (total_to_pay - paid_amount) > 0.005
                  AND payment_status IN ('unpaid', 'partial')
            ),
            '[]'::jsonb
        )
    )
    INTO v_result;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION public.get_bank_statement_matching_context IS
    'Контекст автосопоставления выписки: последние операции по контрагентам и открытые счета взаиморасчётов.';

-- ---------------------------------------------------------------------------
-- Пакетная обработка строк выписки
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.batch_process_bank_statement_entries(
    p_company_id UUID,
    p_items JSONB,
    p_created_by UUID DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_item JSONB;
    v_transaction_id UUID;
    v_processed INTEGER := 0;
    v_failures JSONB := '[]'::jsonb;
    v_actor UUID := auth.uid();
BEGIN
    IF v_actor IS NULL THEN
        RAISE EXCEPTION 'Требуется авторизация';
    END IF;

    IF p_company_id IS NULL
        OR NOT p_company_id IN (SELECT public.get_my_company_ids()) THEN
        RAISE EXCEPTION 'Доступ к данным компании запрещён';
    END IF;

    IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' THEN
        RAISE EXCEPTION 'Некорректный формат списка операций';
    END IF;

    FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        BEGIN
            SELECT public.process_bank_statement_entry(
                (v_item->>'entry_id')::uuid,
                p_company_id,
                (v_item->>'date')::date,
                v_item->>'type',
                (v_item->>'amount')::numeric,
                NULLIF(v_item->>'category_id', '')::uuid,
                NULLIF(v_item->>'object_id', '')::uuid,
                NULLIF(v_item->>'contract_id', '')::uuid,
                NULLIF(v_item->>'contractor_id', '')::uuid,
                NULLIF(v_item->>'contractor_name', ''),
                NULLIF(v_item->>'contractor_inn', ''),
                NULLIF(v_item->>'comment', ''),
                NULLIF(v_item->>'operation_hash', ''),
                COALESCE(p_created_by, v_actor),
                NULLIF(v_item->>'settlement_operation_id', '')::uuid
            )
            INTO v_transaction_id;

            v_processed := v_processed + 1;
        EXCEPTION WHEN OTHERS THEN
            v_failures := v_failures || jsonb_build_array(
                jsonb_build_object(
                    'entry_id', v_item->>'entry_id',
                    'error', SQLERRM
                )
            );
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'processed', v_processed,
        'failed', v_failures
    );
END;
$$;

COMMENT ON FUNCTION public.batch_process_bank_statement_entries IS
    'Пакетный перенос строк банковской выписки в реестр ДДС. Ошибки по строкам не прерывают пакет.';

COMMIT;

BEGIN;

ALTER TABLE public.settlement_payments
    ADD COLUMN IF NOT EXISTS cash_flow_transaction_id UUID
        REFERENCES public.cash_flow(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS idx_settlement_payments_cash_flow_unique
    ON public.settlement_payments (cash_flow_transaction_id)
    WHERE cash_flow_transaction_id IS NOT NULL;

COMMENT ON COLUMN public.settlement_payments.cash_flow_transaction_id IS
    'Ссылка на транзакцию ДДС при оплате из банковской выписки.';

-- Удаляем все предыдущие сигнатуры RPC.
DROP FUNCTION IF EXISTS public.process_bank_statement_entry(
  UUID, UUID, DATE, TEXT, NUMERIC,
  UUID, UUID, UUID, UUID, TEXT, TEXT, UUID
);
DROP FUNCTION IF EXISTS public.process_bank_statement_entry(
  UUID, UUID, DATE, TEXT, NUMERIC,
  UUID, UUID, UUID, UUID, TEXT, TEXT, TEXT, TEXT, UUID
);

CREATE OR REPLACE FUNCTION public.process_bank_statement_entry(
  p_entry_id UUID,
  p_company_id UUID,
  p_date DATE,
  p_type TEXT,
  p_amount NUMERIC,
  p_category_id UUID DEFAULT NULL,
  p_object_id UUID DEFAULT NULL,
  p_contract_id UUID DEFAULT NULL,
  p_contractor_id UUID DEFAULT NULL,
  p_contractor_name TEXT DEFAULT NULL,
  p_contractor_inn TEXT DEFAULT NULL,
  p_comment TEXT DEFAULT NULL,
  p_operation_hash TEXT DEFAULT NULL,
  p_created_by UUID DEFAULT NULL,
  p_settlement_operation_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_transaction_id UUID;
  v_settlement_contract_id UUID;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Сумма операции должна быть больше нуля';
  END IF;

  -- 1. Создаём транзакцию в реестре ДДС
  INSERT INTO public.cash_flow (
    company_id,
    date,
    type,
    amount,
    category_id,
    object_id,
    contract_id,
    contractor_id,
    contractor_name,
    contractor_inn,
    comment,
    operation_hash,
    created_by
  ) VALUES (
    p_company_id,
    p_date,
    p_type,
    p_amount,
    p_category_id,
    p_object_id,
    p_contract_id,
    p_contractor_id,
    p_contractor_name,
    p_contractor_inn,
    p_comment,
    p_operation_hash,
    p_created_by
  )
  RETURNING id INTO v_transaction_id;

  -- 2. Опционально создаём оплату по счёту взаиморасчётов
  IF p_settlement_operation_id IS NOT NULL THEN
    IF p_created_by IS NULL OR NOT public.check_permission(p_created_by, 'settlements', 'update') THEN
      RAISE EXCEPTION 'Недостаточно прав для привязки оплаты к счёту взаиморасчётов';
    END IF;

    SELECT contract_id
    INTO v_settlement_contract_id
    FROM public.settlement_operations
    WHERE id = p_settlement_operation_id
      AND company_id = p_company_id;

    IF v_settlement_contract_id IS NULL THEN
      RAISE EXCEPTION 'Счёт взаиморасчётов не найден';
    END IF;

    IF p_contract_id IS NOT NULL AND v_settlement_contract_id IS DISTINCT FROM p_contract_id THEN
      RAISE EXCEPTION 'Договор операции не совпадает с выбранным счётом';
    END IF;

    INSERT INTO public.settlement_payments (
      company_id,
      settlement_operation_id,
      payment_date,
      amount,
      note,
      cash_flow_transaction_id,
      created_by
    ) VALUES (
      p_company_id,
      p_settlement_operation_id,
      p_date,
      p_amount,
      COALESCE(NULLIF(TRIM(p_comment), ''), 'Из банковской выписки'),
      v_transaction_id,
      p_created_by
    );
  END IF;

  -- 3. Помечаем запись выписки как обработанную
  UPDATE public.bank_statement_entries
  SET
    is_imported = true,
    linked_transaction_id = v_transaction_id
  WHERE id = p_entry_id;

  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.process_bank_statement_entry IS
    'Атомарно переносит строку выписки в cash_flow и опционально создаёт settlement_payment.';

COMMIT;

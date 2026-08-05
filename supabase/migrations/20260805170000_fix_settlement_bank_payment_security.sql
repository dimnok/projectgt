-- Безопасность привязки оплат из выписки к взаиморасчётам.

BEGIN;

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
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaction_id UUID;
  v_settlement_contract_id UUID;
  v_actor UUID := auth.uid();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'Требуется авторизация';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Сумма операции должна быть больше нуля';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.bank_statement_entries
    WHERE id = p_entry_id
      AND company_id = p_company_id
      AND is_imported = false
  ) THEN
    RAISE EXCEPTION 'Запись выписки не найдена или уже обработана';
  END IF;

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
    COALESCE(p_created_by, v_actor)
  )
  RETURNING id INTO v_transaction_id;

  IF p_settlement_operation_id IS NOT NULL THEN
    IF NOT public.check_permission(v_actor, 'settlements', 'update') THEN
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

    IF p_contract_id IS NOT NULL
        AND v_settlement_contract_id IS DISTINCT FROM p_contract_id THEN
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
      v_actor
    );
  END IF;

  UPDATE public.bank_statement_entries
  SET
    is_imported = true,
    linked_transaction_id = v_transaction_id
  WHERE id = p_entry_id
    AND company_id = p_company_id
    AND is_imported = false;

  RETURN v_transaction_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.guard_linked_settlement_payment()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.cash_flow_transaction_id IS NOT NULL THEN
    IF NEW.amount IS DISTINCT FROM OLD.amount
        OR NEW.payment_date IS DISTINCT FROM OLD.payment_date
        OR NEW.settlement_operation_id IS DISTINCT FROM OLD.settlement_operation_id
        OR NEW.cash_flow_transaction_id IS DISTINCT FROM OLD.cash_flow_transaction_id
        OR NEW.company_id IS DISTINCT FROM OLD.company_id THEN
      RAISE EXCEPTION
        'Оплата из банковской выписки не может быть изменена. Удалите транзакцию в ДДС.';
    END IF;
  ELSIF TG_OP = 'DELETE' AND OLD.cash_flow_transaction_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1
      FROM public.cash_flow
      WHERE id = OLD.cash_flow_transaction_id
    ) THEN
      RAISE EXCEPTION
        'Оплата из банковской выписки удаляется вместе с транзакцией ДДС.';
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_linked_settlement_payment
    ON public.settlement_payments;
CREATE TRIGGER trg_guard_linked_settlement_payment
    BEFORE UPDATE OR DELETE
    ON public.settlement_payments
    FOR EACH ROW
    EXECUTE FUNCTION public.guard_linked_settlement_payment();

COMMIT;

-- Функция для атомарного импорта транзакции из буфера выписки в реестр Cash Flow
CREATE OR REPLACE FUNCTION process_bank_statement_entry(
  p_entry_id UUID,
  p_company_id UUID,
  p_date DATE,
  p_type TEXT,
  p_amount NUMERIC,
  p_category_id UUID DEFAULT NULL,
  p_object_id UUID DEFAULT NULL,
  p_contract_id UUID DEFAULT NULL,
  p_contractor_id UUID DEFAULT NULL,
  p_comment TEXT DEFAULT NULL,
  p_operation_hash TEXT DEFAULT NULL,
  p_created_by UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_transaction_id UUID;
BEGIN
  -- 1. Создаем транзакцию в основной таблице cash_flow
  INSERT INTO public.cash_flow (
    company_id,
    date,
    type,
    amount,
    category_id,
    object_id,
    contract_id,
    contractor_id,
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
    p_comment,
    p_operation_hash,
    p_created_by
  )
  RETURNING id INTO v_transaction_id;

  -- 2. Обновляем статус в буферной таблице
  UPDATE public.bank_statement_entries
  SET 
    is_imported = true,
    linked_transaction_id = v_transaction_id
  WHERE id = p_entry_id;

  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


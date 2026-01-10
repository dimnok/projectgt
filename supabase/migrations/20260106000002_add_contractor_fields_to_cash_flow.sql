-- Добавление полей для хранения текстовых данных контрагента из выписки
ALTER TABLE public.cash_flow 
ADD COLUMN IF NOT EXISTS contractor_name TEXT,
ADD COLUMN IF NOT EXISTS contractor_inn TEXT;

-- Обновление RPC-функции для поддержки новых полей
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
  p_contractor_name TEXT DEFAULT NULL,
  p_contractor_inn TEXT DEFAULT NULL,
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

  -- 2. Обновляем статус в буферной таблице
  UPDATE public.bank_statement_entries
  SET 
    is_imported = true,
    linked_transaction_id = v_transaction_id
  WHERE id = p_entry_id;

  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Создание вычисляемой колонки для поиска (если её нет)
ALTER TABLE public.cash_flow 
ADD COLUMN IF NOT EXISTS cash_flow_search_text TEXT GENERATED ALWAYS AS (
  coalesce(comment, '') || ' ' || 
  coalesce(contractor_name, '') || ' ' || 
  coalesce(contractor_inn, '')
) STORED;

-- Индекс для ускорения поиска
CREATE INDEX IF NOT EXISTS idx_cash_flow_search_text ON public.cash_flow USING gin(to_tsvector('russian', cash_flow_search_text));


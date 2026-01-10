-- Улучшенная функция триггера для автоматического возврата записи выписки
-- Добавлена поддержка поиска по operation_hash на случай, если ссылка ID была потеряна
CREATE OR REPLACE FUNCTION on_cash_flow_transaction_deleted()
RETURNS TRIGGER AS $$
BEGIN
  -- 1. Сначала пробуем обновить по прямой ссылке ID
  UPDATE public.bank_statement_entries
  SET 
    is_imported = false,
    linked_transaction_id = NULL
  WHERE linked_transaction_id = OLD.id;
  
  -- 2. Если по ID ничего не обновилось, но у транзакции был хеш — ищем по хешу
  -- Это страховка на случай проблем с установкой linked_transaction_id
  IF NOT FOUND AND OLD.operation_hash IS NOT NULL THEN
    UPDATE public.bank_statement_entries
    SET 
      is_imported = false,
      linked_transaction_id = NULL
    WHERE operation_hash = OLD.operation_hash 
      AND company_id = OLD.company_id
      AND is_imported = true;
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Принудительное исправление существующих "зависших" записей в выписке
-- Если в выписке стоит TRUE, но в реестре нет транзакции с таким хешем — сбрасываем в FALSE
UPDATE public.bank_statement_entries b
SET is_imported = false, linked_transaction_id = NULL
WHERE is_imported = true 
  AND NOT EXISTS (
    SELECT 1 FROM public.cash_flow c 
    WHERE c.operation_hash = b.operation_hash 
      AND c.company_id = b.company_id
  );


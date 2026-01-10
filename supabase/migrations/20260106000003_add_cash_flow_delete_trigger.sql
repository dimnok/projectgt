-- Функция триггера для автоматического возврата записи выписки в статус "не импортировано" при удалении транзакции
CREATE OR REPLACE FUNCTION on_cash_flow_transaction_deleted()
RETURNS TRIGGER AS $$
BEGIN
  -- Обнуляем статус в буферной таблице для записей, которые были связаны с удаленной транзакцией
  UPDATE public.bank_statement_entries
  SET 
    is_imported = false,
    linked_transaction_id = NULL
  WHERE linked_transaction_id = OLD.id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Создание триггера
DROP TRIGGER IF EXISTS tr_on_cash_flow_transaction_deleted ON public.cash_flow;
CREATE TRIGGER tr_on_cash_flow_transaction_deleted
AFTER DELETE ON public.cash_flow
FOR EACH ROW
EXECUTE FUNCTION on_cash_flow_transaction_deleted();


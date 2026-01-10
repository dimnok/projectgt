-- Добавление operation_hash для предотвращения дубликатов в банковских выписках

-- 1. Таблица буферных записей (Staging)
ALTER TABLE public.bank_statement_entries 
ADD COLUMN operation_hash text;

-- Создаем уникальный индекс для предотвращения дублей в рамках компании
-- Используем coalesce для обработки null значений, хотя в идеале хеш должен быть всегда
CREATE UNIQUE INDEX idx_bank_entries_operation_hash 
ON public.bank_statement_entries (company_id, operation_hash);

-- 2. Основная таблица транзакций (для сквозной проверки)
ALTER TABLE public.cash_flow 
ADD COLUMN operation_hash text;

-- Уникальный индекс для транзакций, чтобы нельзя было импортировать одну и ту же выписку дважды
CREATE UNIQUE INDEX idx_cash_flow_operation_hash 
ON public.cash_flow (company_id, operation_hash);

-- Комментарии к колонкам
COMMENT ON COLUMN public.bank_statement_entries.operation_hash IS 'Уникальный хеш операции (date+amount+inn+number+comment) для дедупликации';
COMMENT ON COLUMN public.cash_flow.operation_hash IS 'Уникальный хеш операции для предотвращения повторного импорта из выписок';


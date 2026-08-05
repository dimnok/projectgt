-- Пересчёт payment_status для существующих записей (триггер sync_settlement_payment_status).

BEGIN;

UPDATE public.settlement_operations
SET paid_amount = paid_amount;

COMMIT;

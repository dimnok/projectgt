-- Взаиморасчёты: ставка НДС для операции.
-- NULL = без НДС; 0 = экспорт (ставка 0%); 22/10/7/5 — расчётные ставки.
BEGIN;

ALTER TABLE public.settlement_operations
    ADD COLUMN IF NOT EXISTS vat_rate NUMERIC;

COMMENT ON COLUMN public.settlement_operations.vat_rate IS
    'Ставка НДС в процентах (22, 10, 7, 5, 0). NULL = без НДС.';

COMMIT;

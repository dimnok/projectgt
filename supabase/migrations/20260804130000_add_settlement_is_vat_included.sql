-- Взаиморасчёты: признак включения НДС в сумму.
-- true = «в том числе НДС» (сумма включает НДС).
-- false = «НДС сверху» (сумма без НДС, налог начисляется сверху).
BEGIN;

ALTER TABLE public.settlement_operations
    ADD COLUMN IF NOT EXISTS is_vat_included BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN public.settlement_operations.is_vat_included IS
    'true = НДС включён в сумму (в том числе); false = НДС сверху (сумма без НДС).';

COMMIT;

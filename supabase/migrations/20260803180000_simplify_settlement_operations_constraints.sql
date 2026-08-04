-- Взаиморасчёты: упрощение ограничений под модель «операция = счёт на оплату».
-- Для типа «act» обязателен только act_number (без даты акта и периода).
-- Для типа «other» purpose необязателен.

BEGIN;

ALTER TABLE public.settlement_operations
    DROP CONSTRAINT IF EXISTS settlement_operations_act_fields_chk;

ALTER TABLE public.settlement_operations
    ADD CONSTRAINT settlement_operations_act_fields_chk CHECK (
        (
            operation_type = 'act'
            AND act_number IS NOT NULL
            AND btrim(act_number) <> ''
        )
        OR (
            operation_type IN ('advance', 'other')
            AND act_number IS NULL
            AND act_date IS NULL
            AND advance_retention = 0
            AND warranty_retention = 0
        )
    );

ALTER TABLE public.settlement_operations
    DROP CONSTRAINT IF EXISTS settlement_operations_other_purpose_chk;

COMMIT;

-- После синхронизации paid_amount из settlement_payments принудительно
-- пересчитываем payment_status (даже если paid_amount не изменился).

BEGIN;

CREATE OR REPLACE FUNCTION public.sync_settlement_paid_amount_from_payments()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    op_id UUID;
    new_paid NUMERIC;
    total NUMERIC;
    new_status TEXT;
    eps CONSTANT NUMERIC := 0.005;
BEGIN
    IF TG_OP = 'DELETE' THEN
        op_id := OLD.settlement_operation_id;
    ELSE
        op_id := NEW.settlement_operation_id;
    END IF;

    SELECT COALESCE(SUM(amount), 0)
    INTO new_paid
    FROM public.settlement_payments
    WHERE settlement_operation_id = op_id;

    SELECT total_to_pay
    INTO total
    FROM public.settlement_operations
    WHERE id = op_id;

    total := COALESCE(total, 0);

    IF total <= eps THEN
        IF new_paid <= eps THEN
            new_status := 'paid';
        ELSE
            new_status := 'overpaid';
        END IF;
    ELSIF new_paid <= eps THEN
        new_status := 'unpaid';
    ELSIF new_paid + eps < total THEN
        new_status := 'partial';
    ELSIF abs(new_paid - total) <= eps THEN
        new_status := 'paid';
    ELSE
        new_status := 'overpaid';
    END IF;

    UPDATE public.settlement_operations
    SET
        paid_amount = new_paid,
        payment_status = new_status,
        updated_at = now()
    WHERE id = op_id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

-- Пересчёт статусов для существующих записей.
UPDATE public.settlement_operations
SET paid_amount = paid_amount;

COMMIT;

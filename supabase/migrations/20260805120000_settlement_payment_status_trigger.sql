-- Автоматический пересчёт payment_status при изменении сумм оплаты.
-- Логика зеркалит Dart: computeSettlementPaymentStatus (eps = 0.005).

BEGIN;

CREATE OR REPLACE FUNCTION public.sync_settlement_payment_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  total NUMERIC;
  paid NUMERIC;
  eps CONSTANT NUMERIC := 0.005;
BEGIN
  total := NEW.total_to_pay;
  paid := NEW.paid_amount;

  IF total <= eps THEN
    IF paid <= eps THEN
      NEW.payment_status := 'paid';
    ELSE
      NEW.payment_status := 'overpaid';
    END IF;
  ELSIF paid <= eps THEN
    NEW.payment_status := 'unpaid';
  ELSIF paid + eps < total THEN
    NEW.payment_status := 'partial';
  ELSIF abs(paid - total) <= eps THEN
    NEW.payment_status := 'paid';
  ELSE
    NEW.payment_status := 'overpaid';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_settlement_payment_status
    ON public.settlement_operations;

CREATE TRIGGER trg_settlement_payment_status
    BEFORE INSERT OR UPDATE OF paid_amount, amount, vat_amount,
        advance_retention, warranty_retention
    ON public.settlement_operations
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_settlement_payment_status();

COMMENT ON FUNCTION public.sync_settlement_payment_status() IS
    'Пересчитывает payment_status по paid_amount и total_to_pay.';

COMMIT;

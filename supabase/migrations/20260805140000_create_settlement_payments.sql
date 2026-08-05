-- История оплат по счетам взаиморасчётов (этап 2).
-- paid_amount на settlement_operations пересчитывается триггером из суммы платежей.

BEGIN;

CREATE TABLE IF NOT EXISTS public.settlement_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    settlement_operation_id UUID NOT NULL
        REFERENCES public.settlement_operations(id) ON DELETE CASCADE,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC NOT NULL CHECK (amount > 0),
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_settlement_payments_operation
    ON public.settlement_payments (settlement_operation_id, payment_date DESC);

CREATE INDEX IF NOT EXISTS idx_settlement_payments_company
    ON public.settlement_payments (company_id);

COMMENT ON TABLE public.settlement_payments IS
    'Оплаты по счетам взаиморасчётов (частичные и полные).';

ALTER TABLE public.settlement_payments ENABLE ROW LEVEL SECURITY;

DROP TRIGGER IF EXISTS trg_settlement_payments_updated_at
    ON public.settlement_payments;
CREATE TRIGGER trg_settlement_payments_updated_at
    BEFORE UPDATE ON public.settlement_payments
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

DROP POLICY IF EXISTS "Strict SELECT for settlement_payments"
    ON public.settlement_payments;
CREATE POLICY "Strict SELECT for settlement_payments"
ON public.settlement_payments FOR SELECT
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'read')
);

DROP POLICY IF EXISTS "Strict INSERT for settlement_payments"
    ON public.settlement_payments;
CREATE POLICY "Strict INSERT for settlement_payments"
ON public.settlement_payments FOR INSERT
TO authenticated
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
);

DROP POLICY IF EXISTS "Strict UPDATE for settlement_payments"
    ON public.settlement_payments;
CREATE POLICY "Strict UPDATE for settlement_payments"
ON public.settlement_payments FOR UPDATE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
)
WITH CHECK (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
);

DROP POLICY IF EXISTS "Strict DELETE for settlement_payments"
    ON public.settlement_payments;
CREATE POLICY "Strict DELETE for settlement_payments"
ON public.settlement_payments FOR DELETE
TO authenticated
USING (
    company_id IN (SELECT public.get_my_company_ids())
    AND public.check_permission(auth.uid(), 'settlements', 'update')
);

CREATE OR REPLACE FUNCTION public.sync_settlement_paid_amount_from_payments()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    op_id UUID;
BEGIN
    IF TG_OP = 'DELETE' THEN
        op_id := OLD.settlement_operation_id;
    ELSE
        op_id := NEW.settlement_operation_id;
    END IF;

    UPDATE public.settlement_operations
    SET paid_amount = COALESCE((
        SELECT SUM(amount)
        FROM public.settlement_payments
        WHERE settlement_operation_id = op_id
    ), 0)
    WHERE id = op_id;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_settlement_payments_sync_paid
    ON public.settlement_payments;
CREATE TRIGGER trg_settlement_payments_sync_paid
    AFTER INSERT OR UPDATE OR DELETE
    ON public.settlement_payments
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_settlement_paid_amount_from_payments();

COMMENT ON FUNCTION public.sync_settlement_paid_amount_from_payments() IS
    'Пересчитывает paid_amount счёта как сумму settlement_payments.';

-- Перенос существующих paid_amount в первую запись оплаты.
INSERT INTO public.settlement_payments (
    company_id,
    settlement_operation_id,
    payment_date,
    amount,
    note,
    created_at,
    created_by
)
SELECT
    so.company_id,
    so.id,
    so.invoice_date,
    so.paid_amount,
    'Перенесено из учёта',
    COALESCE(so.created_at, now()),
    so.created_by
FROM public.settlement_operations so
WHERE so.paid_amount > 0
  AND NOT EXISTS (
      SELECT 1
      FROM public.settlement_payments sp
      WHERE sp.settlement_operation_id = so.id
  );

COMMIT;

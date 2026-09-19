-- Аудит операций ФОТ: автор создания и последнего изменения.
-- Колонки заполняются триггером из auth.uid(); при сервисной записи (импорт,
-- service_role) auth.uid() пуст, поэтому значение не перезаписывается.

ALTER TABLE public.payroll_bonus
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz;

ALTER TABLE public.payroll_penalty
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz;

ALTER TABLE public.payroll_payout
  ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz;

COMMENT ON COLUMN public.payroll_bonus.created_by IS 'Кто создал премию.';
COMMENT ON COLUMN public.payroll_bonus.updated_by IS 'Кто последним изменил премию.';
COMMENT ON COLUMN public.payroll_penalty.created_by IS 'Кто создал удержание.';
COMMENT ON COLUMN public.payroll_penalty.updated_by IS 'Кто последним изменил удержание.';
COMMENT ON COLUMN public.payroll_payout.created_by IS 'Кто создал выплату.';
COMMENT ON COLUMN public.payroll_payout.updated_by IS 'Кто последним изменил выплату.';

CREATE OR REPLACE FUNCTION public.set_payroll_operation_audit()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(NEW.created_by, auth.uid());
    NEW.updated_by := COALESCE(NEW.updated_by, NEW.created_by);
    NEW.updated_at := COALESCE(NEW.updated_at, now());
  ELSE
    NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
    NEW.updated_at := now();
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_payroll_operation_audit() IS
  'Проставляет автора создания/изменения операций ФОТ.';

DROP TRIGGER IF EXISTS trg_payroll_bonus_audit ON public.payroll_bonus;
CREATE TRIGGER trg_payroll_bonus_audit
  BEFORE INSERT OR UPDATE ON public.payroll_bonus
  FOR EACH ROW EXECUTE FUNCTION public.set_payroll_operation_audit();

DROP TRIGGER IF EXISTS trg_payroll_penalty_audit ON public.payroll_penalty;
CREATE TRIGGER trg_payroll_penalty_audit
  BEFORE INSERT OR UPDATE ON public.payroll_penalty
  FOR EACH ROW EXECUTE FUNCTION public.set_payroll_operation_audit();

DROP TRIGGER IF EXISTS trg_payroll_payout_audit ON public.payroll_payout;
CREATE TRIGGER trg_payroll_payout_audit
  BEFORE INSERT OR UPDATE ON public.payroll_payout
  FOR EACH ROW EXECUTE FUNCTION public.set_payroll_operation_audit();

CREATE INDEX IF NOT EXISTS idx_payroll_bonus_created_by
  ON public.payroll_bonus (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payroll_penalty_created_by
  ON public.payroll_penalty (created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payroll_payout_created_by
  ON public.payroll_payout (created_by) WHERE created_by IS NOT NULL;

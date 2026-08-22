-- Автор позиции сметы: колонка, автозаполнение при INSERT, имя в view.

ALTER TABLE public.estimates
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.estimates.created_by IS
  'Пользователь, создавший строку (ручное добавление, импорт, ДС).';

CREATE INDEX IF NOT EXISTS idx_estimates_created_by
  ON public.estimates (created_by)
  WHERE created_by IS NOT NULL;

CREATE OR REPLACE FUNCTION public.set_estimates_created_by()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.created_by := COALESCE(NEW.created_by, auth.uid());
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_estimates_created_by ON public.estimates;
CREATE TRIGGER trg_estimates_created_by
  BEFORE INSERT ON public.estimates
  FOR EACH ROW
  EXECUTE FUNCTION public.set_estimates_created_by();

CREATE OR REPLACE VIEW public.estimates_with_contracts AS
SELECT
  e.id,
  e.contract_id,
  e.object_id,
  e.system,
  e.subsystem,
  e.name,
  e.article,
  e.manufacturer,
  e.unit,
  e.quantity,
  e.price,
  e.total,
  e.created_at,
  e.updated_at,
  e.estimate_title,
  e.number,
  public.get_contract_number(e.contract_id) AS contract_number,
  e.company_id,
  e.visible_in_estimates_module,
  e.position_id,
  e.created_by,
  NULLIF(BTRIM(p.full_name), '') AS created_by_name
FROM public.estimates e
LEFT JOIN public.profiles p ON p.id = e.created_by;

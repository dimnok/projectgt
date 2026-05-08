-- Метаданные ДС (описание, применение к estimates) и position_id во view смет.

BEGIN;

ALTER TABLE public.estimate_revisions
  ADD COLUMN IF NOT EXISTS user_description TEXT,
  ADD COLUMN IF NOT EXISTS applied_to_estimates_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS applied_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.estimate_revisions.user_description IS
  'Краткое описание доп. соглашения (ввод при загрузке).';
COMMENT ON COLUMN public.estimate_revisions.applied_to_estimates_at IS
  'Момент переноса снимка ревизии в таблицу estimates; NULL — ещё не применено.';
COMMENT ON COLUMN public.estimate_revisions.applied_by IS
  'Пользователь, применивший ревизию к основной смете.';

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
  e.position_id
FROM public.estimates e;

COMMIT;

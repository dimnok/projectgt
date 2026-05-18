-- Привязка акта КС-2 к утверждённой ВОР: один акт на одну ВОР (частичный уникальный индекс).

BEGIN;

ALTER TABLE public.ks2_acts
  ADD COLUMN IF NOT EXISTS vor_id UUID REFERENCES public.vors (id) ON DELETE RESTRICT;

COMMENT ON COLUMN public.ks2_acts.vor_id IS 'Ведомость объёмов работ: акт формируется только из строк этой ВОР (не более одного акта на ВОР).';

CREATE UNIQUE INDEX IF NOT EXISTS idx_ks2_acts_vor_id_unique
  ON public.ks2_acts (vor_id)
  WHERE vor_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ks2_acts_vor_id_lookup
  ON public.ks2_acts (vor_id)
  WHERE vor_id IS NOT NULL;

COMMIT;

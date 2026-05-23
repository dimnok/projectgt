-- Единая сущность «акт по договору»: КС-2 и ручной реестр в contract_acts.
-- Данные ks2_acts пересоздаются пользователем; таблица удаляется.

BEGIN;

ALTER TABLE public.contract_acts
    ADD COLUMN IF NOT EXISTS act_kind TEXT NOT NULL DEFAULT 'manual',
    ADD COLUMN IF NOT EXISTS vor_id UUID REFERENCES public.vors(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS excel_path TEXT,
    ADD COLUMN IF NOT EXISTS amount_source TEXT NOT NULL DEFAULT 'manual';

ALTER TABLE public.contract_acts
    DROP CONSTRAINT IF EXISTS contract_acts_act_kind_chk;

ALTER TABLE public.contract_acts
    ADD CONSTRAINT contract_acts_act_kind_chk
        CHECK (act_kind IN ('manual', 'ks2'));

ALTER TABLE public.contract_acts
    DROP CONSTRAINT IF EXISTS contract_acts_amount_source_chk;

ALTER TABLE public.contract_acts
    ADD CONSTRAINT contract_acts_amount_source_chk
        CHECK (amount_source IN ('manual', 'vor_preview'));

ALTER TABLE public.contract_acts
    DROP CONSTRAINT IF EXISTS contract_acts_ks2_vor_chk;

ALTER TABLE public.contract_acts
    ADD CONSTRAINT contract_acts_ks2_vor_chk
        CHECK (
            (act_kind = 'manual' AND vor_id IS NULL)
            OR (act_kind = 'ks2' AND vor_id IS NOT NULL)
        );

CREATE UNIQUE INDEX IF NOT EXISTS idx_contract_acts_contract_number
    ON public.contract_acts (contract_id, number);

CREATE UNIQUE INDEX IF NOT EXISTS idx_contract_acts_vor_id_unique
    ON public.contract_acts (vor_id)
    WHERE vor_id IS NOT NULL;

COMMENT ON TABLE public.contract_acts IS
    'Акты по договору: ручной реестр (manual) и КС-2 по ВОР (ks2).';
COMMENT ON COLUMN public.contract_acts.act_kind IS 'manual | ks2';
COMMENT ON COLUMN public.contract_acts.vor_id IS
    'Утверждённая ВОР для акта КС-2 (не более одного акта на ВОР).';
COMMENT ON COLUMN public.contract_acts.excel_path IS
    'Путь к Excel формы КС-2 в Storage (bucket ks2_documents).';
COMMENT ON COLUMN public.contract_acts.amount_source IS 'manual | vor_preview';

ALTER TABLE public.work_items
    ADD COLUMN IF NOT EXISTS contract_act_id UUID
        REFERENCES public.contract_acts(id) ON DELETE SET NULL;

UPDATE public.work_items wi
SET contract_act_id = wi.ks2_id
WHERE wi.ks2_id IS NOT NULL
  AND wi.contract_act_id IS NULL;

ALTER TABLE public.work_items
    DROP CONSTRAINT IF EXISTS work_items_ks2_id_fkey;

DROP INDEX IF EXISTS public.idx_work_items_ks2_id;

ALTER TABLE public.work_items
    DROP COLUMN IF EXISTS ks2_id;

CREATE INDEX IF NOT EXISTS idx_work_items_contract_act_id
    ON public.work_items (contract_act_id);

DROP TABLE IF EXISTS public.ks2_acts CASCADE;

COMMIT;

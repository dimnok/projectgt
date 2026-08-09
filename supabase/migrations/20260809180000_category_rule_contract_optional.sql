-- Режим «только статья» для правил автосопоставления (налоги и прочие операции без договора).

BEGIN;

ALTER TABLE public.cash_flow_category_rules
    ADD COLUMN IF NOT EXISTS requires_contract_binding BOOLEAN NOT NULL DEFAULT true;

COMMENT ON COLUMN public.cash_flow_category_rules.requires_contract_binding IS
    'false — при совпадении правила достаточно статьи ДДС, договор и объект не требуются.';

COMMIT;

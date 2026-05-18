-- Порядок отображения документов договора в UI.
-- Новые записи попадают «вверх» списка (меньшее display_order), как при сортировке по created_at DESC.

ALTER TABLE public.contract_files
  ADD COLUMN IF NOT EXISTS display_order integer NOT NULL DEFAULT 0;

WITH ranked AS (
  SELECT
    id,
    (ROW_NUMBER() OVER (PARTITION BY contract_id ORDER BY created_at DESC) - 1)::integer AS ord
  FROM public.contract_files
)
UPDATE public.contract_files cf
SET display_order = ranked.ord
FROM ranked
WHERE cf.id = ranked.id;

CREATE OR REPLACE FUNCTION public.contract_files_assign_display_order_before_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  SELECT COALESCE(MIN(cf.display_order), 0) - 1
  INTO NEW.display_order
  FROM public.contract_files cf
  WHERE cf.contract_id = NEW.contract_id
    AND cf.company_id = NEW.company_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_contract_files_display_order_bi ON public.contract_files;
CREATE TRIGGER trg_contract_files_display_order_bi
  BEFORE INSERT ON public.contract_files
  FOR EACH ROW
  EXECUTE FUNCTION public.contract_files_assign_display_order_before_insert();

CREATE INDEX IF NOT EXISTS contract_files_contract_display_order_idx
  ON public.contract_files (contract_id, display_order);

-- Привязка строки выполнения смены к контрагенту-подрядчику (NULL = работа силами компании).

ALTER TABLE public.work_items
  ADD COLUMN IF NOT EXISTS contractor_id uuid REFERENCES public.contractors(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS work_items_contractor_id_idx
  ON public.work_items(contractor_id)
  WHERE contractor_id IS NOT NULL;

COMMENT ON COLUMN public.work_items.contractor_id IS
  'Контрагент, выполнивший объём по строке. NULL — работа силами компании.';

-- Что именно поменяли при ручной правке позиции.

ALTER TABLE public.estimate_item_history
  ADD COLUMN IF NOT EXISTS changes JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.estimate_item_history.changes IS
  'Что изменилось: {"quantity": {"from": 10, "to": 33}, ...}';

-- Количество специалистов подрядчика по строке выполнения (NULL — не указано или своя бригада).

ALTER TABLE public.work_items
  ADD COLUMN IF NOT EXISTS specialists_count integer NULL;

COMMENT ON COLUMN public.work_items.specialists_count IS
  'Число специалистов подрядчика на строке. NULL — не задано или работа силами компании.';

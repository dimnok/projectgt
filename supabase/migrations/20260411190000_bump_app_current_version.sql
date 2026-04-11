-- Обновление «текущей» версии в каталоге обновлений.
-- minimum_version не трогаем: клиенты на предыдущей поддерживаемой сборке продолжают работать.
UPDATE public.app_versions
SET
  current_version = '1.0.14',
  updated_at = now();

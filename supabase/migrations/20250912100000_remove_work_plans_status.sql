-- Удаление колонки status из таблицы work_plans
-- Статус больше не используется в приложении

-- Удаляем индекс по статусу
DROP INDEX IF EXISTS idx_work_plans_status;

-- Удаляем колонку status
ALTER TABLE public.work_plans DROP COLUMN IF EXISTS status;

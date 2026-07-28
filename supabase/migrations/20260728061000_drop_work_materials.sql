-- Удаление неиспользуемой таблицы материалов смены.
-- Контур UI/data в приложении удалён; в таблице 0 записей.
-- Никакие другие таблицы/функции на work_materials не ссылаются.

DROP TABLE IF EXISTS public.work_materials CASCADE;

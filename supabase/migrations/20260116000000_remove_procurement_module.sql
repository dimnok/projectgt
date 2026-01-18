-- Удаление модуля "Заявки" (Procurement) из базы данных

-- 1. Удаление таблиц (CASCADE удалит связанные внешние ключи и триггеры)
DROP TABLE IF EXISTS public.procurement_history CASCADE;
DROP TABLE IF EXISTS public.procurement_requests CASCADE;
DROP TABLE IF EXISTS public.procurement_applications CASCADE;
DROP TABLE IF EXISTS public.procurement_approval_config CASCADE;

-- 2. Удаление кастомного типа перечисления
DROP TYPE IF EXISTS public.procurement_status;

-- 3. Удаление записей из системных таблиц прав доступа
DELETE FROM public.role_permissions WHERE module_code = 'procurement';
DELETE FROM public.app_modules WHERE code = 'procurement';

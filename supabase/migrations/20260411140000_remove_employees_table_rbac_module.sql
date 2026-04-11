-- ===================================================================
-- Удаление дублирующего RBAC-модуля employees_table после рефакторинга UI.
-- В приложении используется единый module_code = 'employees'.
-- ===================================================================

BEGIN;

-- 1) Подтянуть права с legacy-модуля: если для той же роли/компании/permission
--    в 'employees' записи нет — копируем строку с module_code = 'employees'.
INSERT INTO public.role_permissions (role_id, company_id, module_code, permission_code, is_enabled)
SELECT s.role_id, s.company_id, 'employees'::text, s.permission_code, s.is_enabled
FROM public.role_permissions s
WHERE s.module_code = 'employees_table'
  AND NOT EXISTS (
    SELECT 1
    FROM public.role_permissions e
    WHERE e.role_id = s.role_id
      AND e.module_code = 'employees'
      AND e.permission_code = s.permission_code
      AND (e.company_id IS NOT DISTINCT FROM s.company_id)
  );

-- 2) Если обе строки были: включить право на employees, если оно было true на employees_table
UPDATE public.role_permissions e
SET is_enabled = true
FROM public.role_permissions s
WHERE s.module_code = 'employees_table'
  AND s.is_enabled = true
  AND e.role_id = s.role_id
  AND e.module_code = 'employees'
  AND e.permission_code = s.permission_code
  AND (e.company_id IS NOT DISTINCT FROM s.company_id)
  AND e.is_enabled IS DISTINCT FROM true;

-- 3) Удалить права и справочную строку модуля
DELETE FROM public.role_permissions WHERE module_code = 'employees_table';
DELETE FROM public.app_modules WHERE code = 'employees_table';

-- 4) Каноническая строка модуля «Сотрудники» (при отсутствии — создать; иначе нормализовать подпись)
INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('employees', 'Сотрудники', 'person_3', 40, true)
ON CONFLICT (code) DO UPDATE
SET
  name = EXCLUDED.name,
  is_active = true;

COMMIT;

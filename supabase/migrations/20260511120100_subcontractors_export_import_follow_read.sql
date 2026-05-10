-- Экспорт/импорт расценок подрядчика ранее не проверяли отдельные флаги в UI.
-- Выравниваем с доступом на просмотр раздела «Подрядчики».
UPDATE public.role_permissions r
SET is_enabled = sr.is_enabled
FROM public.role_permissions sr
WHERE r.module_code = 'subcontractors'
  AND r.permission_code IN ('export', 'import')
  AND sr.role_id = r.role_id
  AND sr.company_id IS NOT DISTINCT FROM r.company_id
  AND sr.module_code = 'subcontractors'
  AND sr.permission_code = 'read';

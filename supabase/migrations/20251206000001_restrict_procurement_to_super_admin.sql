-- Отключаем права на модуль "Заявки" для всех ролей
UPDATE public.role_permissions
SET is_enabled = false
WHERE module_code = 'procurement';

-- Выдаем полные права "Супер-админ" на модуль "Заявки"
-- Сначала пытаемся обновить существующие записи
UPDATE public.role_permissions
SET is_enabled = true
FROM public.roles
WHERE public.role_permissions.role_id = public.roles.id
  AND public.roles.role_name = 'Супер-админ'
  AND public.role_permissions.module_code = 'procurement';

-- Затем вставляем недостающие (если их не было)
INSERT INTO public.role_permissions (role_id, module_code, permission_code, is_enabled)
SELECT 
    roles.id,
    'procurement',
    p.code,
    true
FROM public.roles
CROSS JOIN (VALUES ('read'), ('create'), ('update'), ('delete')) AS p(code)
WHERE roles.role_name = 'Супер-админ'
  AND NOT EXISTS (
      SELECT 1 FROM public.role_permissions rp
      WHERE rp.role_id = roles.id
        AND rp.module_code = 'procurement'
        AND rp.permission_code = p.code
  );


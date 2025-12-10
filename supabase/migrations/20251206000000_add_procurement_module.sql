-- Добавляем модуль "Заявки"
INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('procurement', 'Заявки', 'cart', 100, true)
ON CONFLICT (code) DO NOTHING;

-- Выдаем права Администратору на модуль "Заявки"
INSERT INTO public.role_permissions (role_id, module_code, permission_code, is_enabled)
SELECT 
    id as role_id,
    'procurement' as module_code,
    p_code as permission_code,
    true as is_enabled
FROM public.roles
CROSS JOIN (VALUES ('read'), ('create'), ('update'), ('delete')) as p(p_code)
WHERE role_name = 'Администратор'
ON CONFLICT DO NOTHING;


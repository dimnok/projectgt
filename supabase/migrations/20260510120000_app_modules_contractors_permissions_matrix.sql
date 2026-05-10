-- Модуль RBAC «contractors»: справочник контрагентов (не раздел «Подрядчики»).
INSERT INTO public.app_modules (code, name, icon_key, sort_order, is_active)
VALUES ('contractors', 'Контрагенты', 'briefcase_fill', 85, true)
ON CONFLICT (code) DO UPDATE
SET
  name = EXCLUDED.name,
  icon_key = EXCLUDED.icon_key,
  sort_order = EXCLUDED.sort_order,
  is_active = true;

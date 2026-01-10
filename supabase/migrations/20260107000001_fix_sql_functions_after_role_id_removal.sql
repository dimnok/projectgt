-- ===================================================================
-- Миграция: Исправление SQL-функций после удаления role_id из profiles
-- ===================================================================
-- ОПИСАНИЕ:
-- После удаления колонки role_id из таблицы profiles необходимо исправить
-- SQL-функции, которые использовали эту колонку.
-- 
-- ИСПРАВЛЯЕМЫЕ ФУНКЦИИ:
-- 1. is_super_admin - использует p.role_id в JOIN
-- 2. handle_new_user - использует role_id при INSERT в profiles
-- 3. check_permission - использует role_id из profiles как fallback
-- ===================================================================

BEGIN;

-- ===================================================================
-- 1. ФУНКЦИЯ: is_super_admin
-- ===================================================================
-- Исправляем: получаем role_id из company_members вместо profiles
CREATE OR REPLACE FUNCTION public.is_super_admin(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.company_members cm
    JOIN public.roles r ON cm.role_id = r.id
    WHERE cm.user_id = is_super_admin.user_id 
      AND cm.is_active = true
      AND r.is_system = true 
      AND r.role_name = 'Супер-админ'
  );
END;
$$;

-- ===================================================================
-- 2. ФУНКЦИЯ: handle_new_user
-- ===================================================================
-- Исправляем: убираем role_id из INSERT, так как он больше не существует в profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    email, 
    full_name, 
    short_name, 
    phone, 
    status, 
    approved_at, 
    disabled_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', ''),
    '',
    '',
    false,
    null,
    null
  );
  RETURN NEW;
END;
$$;

-- ===================================================================
-- 3. ФУНКЦИЯ: check_permission
-- ===================================================================
-- Исправляем: убираем fallback на profiles.role_id, используем только company_members
CREATE OR REPLACE FUNCTION public.check_permission(
  user_id UUID,
  module_slug TEXT,
  permission_slug TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_role_id UUID;
  has_perm BOOLEAN;
  active_company_id UUID;
  is_company_owner BOOLEAN;
BEGIN
  -- Получаем ID последней активной компании пользователя
  SELECT last_company_id INTO active_company_id 
  FROM public.profiles 
  WHERE id = check_permission.user_id;
  
  -- Если компания не выбрана, прав нет
  IF active_company_id IS NULL THEN
    RETURN false;
  END IF;

  -- Проверяем, является ли пользователь владельцем компании
  SELECT is_owner INTO is_company_owner
  FROM public.company_members 
  WHERE company_members.user_id = check_permission.user_id 
    AND company_members.company_id = active_company_id
    AND company_members.is_active = true;

  -- Владельцы имеют все права
  IF is_company_owner = true THEN
    RETURN true;
  END IF;

  -- Получаем role_id пользователя именно в этой компании
  SELECT role_id INTO user_role_id 
  FROM public.company_members 
  WHERE company_members.user_id = check_permission.user_id 
    AND company_members.company_id = active_company_id
    AND company_members.is_active = true;
  
  -- Если role_id найден в участниках компании
  IF user_role_id IS NOT NULL THEN
    SELECT is_enabled INTO has_perm
    FROM public.role_permissions
    WHERE role_id = user_role_id
      AND module_code = module_slug
      AND permission_code = permission_slug;
      
    IF has_perm IS NOT NULL THEN
      RETURN has_perm;
    END IF;
  END IF;

  -- [RBAC v3] Убран fallback на profiles.role_id, так как колонка удалена
  -- Роли теперь хранятся только в company_members

  RETURN false;
END;
$$;

COMMIT;

-- ===================================================================
-- Результат:
-- ✅ Функция is_super_admin исправлена - использует company_members
-- ✅ Функция handle_new_user исправлена - убран role_id из INSERT
-- ✅ Функция check_permission исправлена - убран fallback на profiles.role_id
-- ✅ Все функции теперь используют только company_members для получения ролей
-- ===================================================================

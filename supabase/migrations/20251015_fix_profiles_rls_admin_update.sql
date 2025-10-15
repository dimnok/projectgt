-- ===================================================================
-- Миграция: Исправление RLS политики UPDATE на таблице profiles
-- ===================================================================
-- Проблема: политика UPDATE на profiles требует, чтобы админ обновлял 
-- только через сервис-роль, т.к. обычный клиент подчиняется RLS
--
-- Решение: создать две отдельные политики:
--   1. Для service_role (админ через бэкенд) - без ограничений
--   2. Для public (обычный пользователь) - только свой профиль
-- ===================================================================

BEGIN;

-- Удалить старые политики UPDATE
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins bypass profile security" ON profiles;

-- Политика 1: Пользователи через обычный клиент (anon key) могут обновить свой профиль
CREATE POLICY "Users can update their own profile"
  ON profiles 
  FOR UPDATE 
  TO public
  USING (
    (SELECT auth.uid()) = id
  )
  WITH CHECK (
    (SELECT auth.uid()) = id
  );

-- Политика 2: Админ через сервис-роль может менять любой профиль
CREATE POLICY "Admins can update any profile via service role"
  ON profiles 
  FOR UPDATE 
  TO service_role
  USING (true)
  WITH CHECK (true);

COMMIT;

-- ===================================================================
-- Результат:
-- ✅ public role: может обновить только себя
-- ✅ service_role: может обновить любой профиль (для админа через бэкенд)
-- ✅ Нет рекурсии, нет infinite recursion ошибок
-- ===================================================================

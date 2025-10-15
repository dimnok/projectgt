-- ===================================================================
-- Миграция: Только администраторы могут изменять профили
-- ===================================================================
-- ТРЕБОВАНИЕ: Изменять object_ids и другие поля профиля 
--             может ТОЛЬКО администратор!
--
-- РЕШЕНИЕ:
-- 1. RLS политика UPDATE на profiles только для service_role (админ)
-- 2. Обычные пользователи (public) не могут обновлять profiles
-- 3. Все обновления идут через Edge Function update_user_profile
--    которая проверяет, что вызывающий - админ
-- ===================================================================

BEGIN;

-- Удалить все старые UPDATE политики
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins bypass profile security" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile via service role" ON profiles;
DROP POLICY IF EXISTS "Only admins via service role can update profiles" ON profiles;

-- ЕДИНСТВЕННАЯ политика UPDATE: только service_role (админ через бэкенд)
-- Обычные пользователи НЕ могут напрямую обновлять profiles!
CREATE POLICY "Admins only can update profiles via service role"
  ON profiles 
  FOR UPDATE 
  TO service_role
  USING (true)
  WITH CHECK (true);

COMMIT;

-- ===================================================================
-- Результат:
-- ✅ Только админ может менять object_ids
-- ✅ Обычный пользователь НЕ может менять ничего в своем профиле
-- ✅ Все обновления идут через Edge Function (защищено)
-- ✅ Безопасно и надежно
-- ===================================================================

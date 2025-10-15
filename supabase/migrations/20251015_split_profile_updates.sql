-- ===================================================================
-- Миграция: Разделение логики обновления профилей
-- ===================================================================
-- УТОЧНЕНИЕ: 
-- - Пользователь может обновлять СВОЙ профиль (но НЕ object_ids!)
-- - Админ может обновлять ЛЮБОЙ профиль (включая object_ids)
-- 
-- РЕАЛИЗАЦИЯ:
-- 1. Edge Function update_own_profile - для пользователя (без admin check)
-- 2. Edge Function update_user_profile - для админа (с admin check)
-- 3. RLS политика UPDATE только для service_role
-- ===================================================================

BEGIN;

-- RLS политика UPDATE только для service_role (бэкенд)
DROP POLICY IF EXISTS "Admins only can update profiles via service role" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile via service role" ON profiles;

CREATE POLICY "Only service role can update profiles"
  ON profiles 
  FOR UPDATE 
  TO service_role
  USING (true)
  WITH CHECK (true);

COMMIT;

-- ===================================================================
-- Edge Functions:
-- 
-- 1. update_own_profile (для пользователя):
--    - Без проверки прав (каждый может обновить свой профиль)
--    - Только поля: fullName, phone, photoUrl, shortName, object
--    - БЕЗ object_ids, role, status
--    - БЕЗ access check
--
-- 2. update_user_profile (для админа):
--    - С проверкой прав (только админ)
--    - Любые поля: fullName, phone, photoUrl, status, role, object_ids
--    - С access check (проверяет что вызывающий админ)
--
-- Использование в Dart:
-- - Пользователь вызывает: updateProfile(свой_профиль)
--   → updateOwnProfile() → update_own_profile
-- - Админ вызывает: updateProfile(чужой_профиль)
--   → updateProfileViaFunction() → update_user_profile
-- ===================================================================

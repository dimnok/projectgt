-- ===================================================================
-- Миграция: Исправление множественных RLS политик на app_versions
-- ===================================================================
-- Проблема: Две SELECT политики для role=authenticated
--   1. "Все могут читать версию приложени" (qual = true)
--   2. "Только админы могут изменять верс" (qual = проверка админов)
-- 
-- Решение: Объединить в одну политику с OR логикой
-- ===================================================================

BEGIN;

-- Удалить старые политики
DROP POLICY IF EXISTS "Все могут читать версию приложени" ON app_versions;
DROP POLICY IF EXISTS "Только админы могут изменять верс" ON app_versions;

-- Создать единую политику SELECT
CREATE POLICY "Allow read app_versions"
  ON app_versions 
  FOR SELECT 
  TO authenticated
  USING (true);  -- Все аутентифицированные могут читать

-- Отдельная политика для UPDATE/DELETE только для админов
CREATE POLICY "Allow admins to modify app_versions"
  ON app_versions 
  FOR UPDATE, DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (SELECT auth.uid())
        AND profiles.role = 'admin'
    )
  );

-- Для INSERT только админы
CREATE POLICY "Allow admins to insert app_versions"
  ON app_versions 
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (SELECT auth.uid())
        AND profiles.role = 'admin'
    )
  );

COMMIT;

-- ===================================================================
-- Результат:
-- ✅ Объединены 2 SELECT политики в 1
-- ✅ Добавлены отдельные политики UPDATE, DELETE, INSERT
-- ✅ Устранено предупреждение multiple_permissive_policies
-- ===================================================================

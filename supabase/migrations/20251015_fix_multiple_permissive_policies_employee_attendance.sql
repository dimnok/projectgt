-- ===================================================================
-- Миграция: Исправление множественных RLS политик на employee_attendance
-- ===================================================================
-- Проблема: 3 SELECT политики на role=public
--   1. "Admins can view all attendance records"
--   2. "Users can view attendance for their objects"
--   3. "Users can view their own attendance"
-- 
-- Решение: Объединить в одну SELECT политику с OR логикой
-- ===================================================================

BEGIN;

-- Удалить старые SELECT политики
DROP POLICY IF EXISTS "Admins can view all attendance records" ON employee_attendance;
DROP POLICY IF EXISTS "Users can view attendance for their objects" ON employee_attendance;
DROP POLICY IF EXISTS "Users can view their own attendance" ON employee_attendance;

-- Создать единую SELECT политика - объединяем все три условия с OR
CREATE POLICY "Allow read attendance records"
  ON employee_attendance 
  FOR SELECT 
  TO public
  USING (
    -- Админы видят всё
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (SELECT auth.uid())
        AND profiles.role = 'admin'
    )
    OR
    -- Менеджеры объектов видят записи для своих объектов
    object_id IN (
      SELECT unnest(profiles.object_ids)
      FROM profiles
      WHERE profiles.id = (SELECT auth.uid())
    )
    OR
    -- Сотрудники видят свои записи
    employee_id IN (
      SELECT e.id
      FROM employees e
      WHERE EXISTS (
        SELECT 1
        FROM profiles p
        WHERE p.id = (SELECT auth.uid())
          AND p.employee_id = e.id
      )
    )
  );

COMMIT;

-- ===================================================================
-- Результат:
-- ✅ Объединены 3 SELECT политики в 1
-- ✅ Логика: Админы ИЛИ менеджеры объектов ИЛИ сотрудник видит своё
-- ✅ Устранено предупреждение multiple_permissive_policies для SELECT
-- ===================================================================

-- Миграция: Исправление триггеров агрегатов
-- Дата: 11 октября 2025 года
-- Проблема: Триггеры срабатывают только при изменении конкретных полей (total, employee_id)
-- Решение: Триггеры должны срабатывать при ЛЮБЫХ UPDATE операциях

-- ============================================================================
-- 1. ПЕРЕСОЗДАНИЕ ТРИГГЕРА ДЛЯ WORK_ITEMS
-- ============================================================================

-- Удаляем старый триггер
DROP TRIGGER IF EXISTS work_items_aggregate_trigger ON work_items;

-- Создаём триггер, который срабатывает при ЛЮБЫХ изменениях work_items
-- (а не только при UPDATE OF total)
CREATE TRIGGER work_items_aggregate_trigger
  AFTER INSERT OR UPDATE OR DELETE ON work_items
  FOR EACH ROW 
  EXECUTE FUNCTION trigger_update_work_aggregates_items();

COMMENT ON TRIGGER work_items_aggregate_trigger ON work_items IS 
  'Автоматически обновляет агрегаты смены при любых изменениях работ (INSERT/UPDATE/DELETE). 
   Исправлено: теперь срабатывает при изменении ЛЮБЫХ полей, а не только total.';

-- ============================================================================
-- 2. ПЕРЕСОЗДАНИЕ ТРИГГЕРА ДЛЯ WORK_HOURS
-- ============================================================================

-- Удаляем старый триггер
DROP TRIGGER IF EXISTS work_hours_aggregate_trigger ON work_hours;

-- Создаём триггер, который срабатывает при ЛЮБЫХ изменениях work_hours
-- (а не только при UPDATE OF employee_id)
CREATE TRIGGER work_hours_aggregate_trigger
  AFTER INSERT OR UPDATE OR DELETE ON work_hours
  FOR EACH ROW 
  EXECUTE FUNCTION trigger_update_work_aggregates_hours();

COMMENT ON TRIGGER work_hours_aggregate_trigger ON work_hours IS 
  'Автоматически обновляет агрегаты смены при любых изменениях часов сотрудников (INSERT/UPDATE/DELETE).
   Исправлено: теперь срабатывает при изменении ЛЮБЫХ полей, а не только employee_id.';

-- ============================================================================
-- 3. ПРОВЕРКА ИСПРАВЛЕНИЯ
-- ============================================================================

DO $$
DECLARE
  items_trigger_def TEXT;
  hours_trigger_def TEXT;
BEGIN
  -- Получаем определения триггеров
  SELECT pg_get_triggerdef(oid) INTO items_trigger_def
  FROM pg_trigger
  WHERE tgrelid = 'work_items'::regclass 
    AND tgname = 'work_items_aggregate_trigger';

  SELECT pg_get_triggerdef(oid) INTO hours_trigger_def
  FROM pg_trigger
  WHERE tgrelid = 'work_hours'::regclass 
    AND tgname = 'work_hours_aggregate_trigger';

  -- Проверяем что триггеры НЕ содержат "UPDATE OF"
  IF items_trigger_def LIKE '%UPDATE OF%' THEN
    RAISE EXCEPTION 'Триггер work_items всё ещё использует UPDATE OF! Определение: %', items_trigger_def;
  END IF;

  IF hours_trigger_def LIKE '%UPDATE OF%' THEN
    RAISE EXCEPTION 'Триггер work_hours всё ещё использует UPDATE OF! Определение: %', hours_trigger_def;
  END IF;

  RAISE NOTICE 'Триггеры успешно исправлены! Теперь они срабатывают при любых UPDATE операциях.';
  RAISE NOTICE 'work_items триггер: %', items_trigger_def;
  RAISE NOTICE 'work_hours триггер: %', hours_trigger_def;
END $$;

-- ============================================================================
-- 4. ПЕРЕСЧЁТ АГРЕГАТОВ ДЛЯ ВСЕХ СМЕН (на случай рассинхронизации)
-- ============================================================================

DO $$
BEGIN
  -- Обновляем агрегаты для всех смен, чтобы устранить возможные несоответствия
  UPDATE works w SET
    total_amount = COALESCE((
      SELECT SUM(wi.total) 
      FROM work_items wi 
      WHERE wi.work_id = w.id
    ), 0),
    items_count = (
      SELECT COUNT(*) 
      FROM work_items wi 
      WHERE wi.work_id = w.id
    ),
    employees_count = (
      SELECT COUNT(DISTINCT wh.employee_id) 
      FROM work_hours wh 
      WHERE wh.work_id = w.id
    ),
    updated_at = timezone('utc', now());

  RAISE NOTICE 'Агрегаты всех смен пересчитаны для устранения рассинхронизации.';
END $$;


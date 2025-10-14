-- Миграция: Добавление агрегатных полей в таблицу works
-- Дата: 10 октября 2025 года
-- Цель: Оптимизация производительности для масштабирования до тысяч смен

-- ============================================================================
-- 1. ДОБАВЛЕНИЕ КОЛОНОК АГРЕГАТОВ
-- ============================================================================

-- Добавляем три колонки для хранения предрассчитанных агрегатов
ALTER TABLE works 
  ADD COLUMN IF NOT EXISTS total_amount NUMERIC DEFAULT 0 NOT NULL,
  ADD COLUMN IF NOT EXISTS items_count INTEGER DEFAULT 0 NOT NULL,
  ADD COLUMN IF NOT EXISTS employees_count INTEGER DEFAULT 0 NOT NULL;

-- Комментарии для документации
COMMENT ON COLUMN works.total_amount IS 'Общая сумма всех работ (work_items.total). Обновляется автоматически через триггеры.';
COMMENT ON COLUMN works.items_count IS 'Количество работ в смене. Обновляется автоматически через триггеры.';
COMMENT ON COLUMN works.employees_count IS 'Количество уникальных сотрудников в смене. Обновляется автоматически через триггеры.';

-- ============================================================================
-- 2. ЗАПОЛНЕНИЕ АГРЕГАТОВ ДЛЯ СУЩЕСТВУЮЩИХ СМЕН
-- ============================================================================

-- Рассчитываем и заполняем агрегаты для всех существующих записей
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
  );

-- ============================================================================
-- 3. ФУНКЦИЯ ПЕРЕСЧЁТА АГРЕГАТОВ
-- ============================================================================

-- Основная функция для пересчёта всех агрегатов смены
CREATE OR REPLACE FUNCTION update_work_aggregates(work_uuid UUID) 
RETURNS VOID 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE works SET
    total_amount = COALESCE((
      SELECT SUM(total) 
      FROM work_items 
      WHERE work_id = work_uuid
    ), 0),
    items_count = (
      SELECT COUNT(*) 
      FROM work_items 
      WHERE work_id = work_uuid
    ),
    employees_count = (
      SELECT COUNT(DISTINCT employee_id) 
      FROM work_hours 
      WHERE work_id = work_uuid
    ),
    updated_at = timezone('utc', now())
  WHERE id = work_uuid;
END;
$$;

COMMENT ON FUNCTION update_work_aggregates(UUID) IS 'Пересчитывает агрегатные поля (total_amount, items_count, employees_count) для указанной смены.';

-- ============================================================================
-- 4. ТРИГГЕРНЫЕ ФУНКЦИИ ДЛЯ WORK_ITEMS
-- ============================================================================

-- Триггерная функция для автоматического обновления при изменениях work_items
CREATE OR REPLACE FUNCTION trigger_update_work_aggregates_items()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  work_uuid UUID;
BEGIN
  -- Определяем work_id в зависимости от операции
  IF (TG_OP = 'DELETE') THEN
    work_uuid := OLD.work_id;
  ELSE
    work_uuid := NEW.work_id;
  END IF;

  -- Обновляем агрегаты смены
  PERFORM update_work_aggregates(work_uuid);
  
  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION trigger_update_work_aggregates_items() IS 'Триггерная функция для обновления агрегатов при изменении work_items.';

-- ============================================================================
-- 5. ТРИГГЕРНЫЕ ФУНКЦИИ ДЛЯ WORK_HOURS
-- ============================================================================

-- Триггерная функция для автоматического обновления при изменениях work_hours
CREATE OR REPLACE FUNCTION trigger_update_work_aggregates_hours()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  work_uuid UUID;
BEGIN
  -- Определяем work_id в зависимости от операции
  IF (TG_OP = 'DELETE') THEN
    work_uuid := OLD.work_id;
  ELSE
    work_uuid := NEW.work_id;
  END IF;

  -- Обновляем агрегаты смены
  PERFORM update_work_aggregates(work_uuid);
  
  RETURN NULL;
END;
$$;

COMMENT ON FUNCTION trigger_update_work_aggregates_hours() IS 'Триггерная функция для обновления агрегатов при изменении work_hours.';

-- ============================================================================
-- 6. СОЗДАНИЕ ТРИГГЕРОВ
-- ============================================================================

-- Триггер на work_items: срабатывает при INSERT, UPDATE, DELETE
DROP TRIGGER IF EXISTS work_items_aggregate_trigger ON work_items;
CREATE TRIGGER work_items_aggregate_trigger
  AFTER INSERT OR UPDATE OF total OR DELETE ON work_items
  FOR EACH ROW 
  EXECUTE FUNCTION trigger_update_work_aggregates_items();

COMMENT ON TRIGGER work_items_aggregate_trigger ON work_items IS 'Автоматически обновляет агрегаты смены при изменении работ.';

-- Триггер на work_hours: срабатывает при INSERT, UPDATE, DELETE
DROP TRIGGER IF EXISTS work_hours_aggregate_trigger ON work_hours;
CREATE TRIGGER work_hours_aggregate_trigger
  AFTER INSERT OR UPDATE OF employee_id OR DELETE ON work_hours
  FOR EACH ROW 
  EXECUTE FUNCTION trigger_update_work_aggregates_hours();

COMMENT ON TRIGGER work_hours_aggregate_trigger ON work_hours IS 'Автоматически обновляет агрегаты смены при изменении часов сотрудников.';

-- ============================================================================
-- 7. ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ (опционально)
-- ============================================================================

-- Индекс для быстрой фильтрации по дате (для группировки по месяцам)
CREATE INDEX IF NOT EXISTS idx_works_date_desc ON works (date DESC);

-- Индекс для быстрой фильтрации по статусу
CREATE INDEX IF NOT EXISTS idx_works_status ON works (status);

-- ============================================================================
-- ПРОВЕРКА МИГРАЦИИ
-- ============================================================================

-- Проверяем что колонки добавлены
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'works' AND column_name = 'total_amount'
  ) THEN
    RAISE EXCEPTION 'Колонка total_amount не добавлена!';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'works' AND column_name = 'items_count'
  ) THEN
    RAISE EXCEPTION 'Колонка items_count не добавлена!';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'works' AND column_name = 'employees_count'
  ) THEN
    RAISE EXCEPTION 'Колонка employees_count не добавлена!';
  END IF;

  RAISE NOTICE 'Миграция успешно применена! Колонки добавлены, триггеры созданы.';
END $$;


-- Миграция: Добавление триггера для пересчёта агрегатов при UPDATE works
-- Дата: 14 октября 2025
-- Цель: Защита от прямого обновления агрегатных полей (total_amount, items_count, employees_count)
-- Проблема: При закрытии смены приложение могло перезаписывать агрегаты NULL-значениями

-- Триггерная функция для пересчёта агрегатов при UPDATE works
CREATE OR REPLACE FUNCTION trigger_update_work_aggregates_on_work_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Пересчитываем агрегаты только если изменился статус или другие поля (но не сами агрегаты)
  -- Это защита от бесконечной рекурсии и от случайного затирания агрегатов
  IF (OLD.status != NEW.status) 
     OR (NEW.total_amount IS NULL AND OLD.total_amount IS NOT NULL)
     OR (NEW.items_count IS NULL AND OLD.items_count IS NOT NULL)
     OR (NEW.employees_count IS NULL AND OLD.employees_count IS NOT NULL)
  THEN
    -- Вызываем функцию пересчёта агрегатов
    PERFORM update_work_aggregates(NEW.id);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Создаём триггер на UPDATE works (AFTER UPDATE)
DROP TRIGGER IF EXISTS works_update_aggregate_trigger ON works;
CREATE TRIGGER works_update_aggregate_trigger
  AFTER UPDATE ON works
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_work_aggregates_on_work_update();

-- Комментарий к триггеру
COMMENT ON TRIGGER works_update_aggregate_trigger ON works IS 
'Пересчитывает агрегатные поля (total_amount, items_count, employees_count) при обновлении смены, если они стали NULL или изменился статус.';

-- Пересчитываем агрегаты для всех существующих смен с NULL-значениями
DO $$
DECLARE
  work_record RECORD;
  fixed_count INT := 0;
BEGIN
  FOR work_record IN 
    SELECT id 
    FROM works 
    WHERE total_amount IS NULL 
       OR items_count IS NULL 
       OR employees_count IS NULL
  LOOP
    PERFORM update_work_aggregates(work_record.id);
    fixed_count := fixed_count + 1;
  END LOOP;
  
  RAISE NOTICE 'Исправлено смен с NULL-агрегатами: %', fixed_count;
END $$;


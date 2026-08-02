-- Защита агрегатов works от гонки при параллельных вставках/удалениях в work_items и work_hours.
-- Корневая причина: при открытии смены сотрудники добавляются параллельно (Future.wait),
-- и триггеры пересчёта не видят друг друга — последний записывает устаревшее значение.
-- Решение: перед пересчётом берём row-level блокировку строки смены (FOR UPDATE).
-- Параллельные вызовы выстраиваются по очереди; последний пересчёт видит все закоммиченные строки.

CREATE OR REPLACE FUNCTION update_work_aggregates(work_uuid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Сериализуем пересчёт по смене: блокируем строку works до конца транзакции.
  PERFORM 1 FROM works WHERE id = work_uuid FOR UPDATE;

  UPDATE works SET
    total_amount = COALESCE((
      SELECT SUM(total) FROM work_items WHERE work_id = work_uuid
    ), 0),
    own_total_amount = COALESCE((
      SELECT SUM(total) FROM work_items
      WHERE work_id = work_uuid AND contractor_id IS NULL
    ), 0),
    items_count = (
      SELECT COUNT(*) FROM work_items WHERE work_id = work_uuid
    ),
    employees_count = (
      SELECT COUNT(DISTINCT employee_id) FROM work_hours WHERE work_id = work_uuid
    ),
    updated_at = timezone('utc', now())
  WHERE id = work_uuid;
END;
$$;

COMMENT ON FUNCTION update_work_aggregates(UUID) IS
  'Пересчитывает total_amount, own_total_amount, items_count, employees_count для смены. Блокирует строку works (FOR UPDATE) для защиты от гонки при параллельных изменениях work_items/work_hours.';

-- Разовый пересчёт всех агрегатов (устраняет накопленные рассинхроны).
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT id FROM works LOOP
    PERFORM update_work_aggregates(r.id);
  END LOOP;
END $$;

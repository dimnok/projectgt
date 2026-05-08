-- Агрегат own_total_amount: сумма work_items только без подрядчика (как вкладка «Данные»).

ALTER TABLE works
  ADD COLUMN IF NOT EXISTS own_total_amount NUMERIC DEFAULT 0 NOT NULL;

COMMENT ON COLUMN works.own_total_amount IS
  'Сумма work_items.total по строкам с contractor_id IS NULL. Пересчитывается в update_work_aggregates.';

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
    own_total_amount = COALESCE((
      SELECT SUM(total)
      FROM work_items
      WHERE work_id = work_uuid
        AND contractor_id IS NULL
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

COMMENT ON FUNCTION update_work_aggregates(UUID) IS
  'Пересчитывает total_amount, own_total_amount, items_count, employees_count для смены.';

UPDATE works w SET
  total_amount = COALESCE((
    SELECT SUM(wi.total)
    FROM work_items wi
    WHERE wi.work_id = w.id
  ), 0),
  own_total_amount = COALESCE((
    SELECT SUM(wi.total)
    FROM work_items wi
    WHERE wi.work_id = w.id
      AND wi.contractor_id IS NULL
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

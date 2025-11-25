DROP FUNCTION IF EXISTS get_month_employees_summary(DATE);
DROP FUNCTION IF EXISTS get_month_hours_summary(DATE);
DROP FUNCTION IF EXISTS get_month_objects_summary(DATE);
DROP FUNCTION IF EXISTS get_month_systems_summary(DATE);

-- Function to get total employees count for a month (unique people)
CREATE OR REPLACE FUNCTION get_month_employees_summary(p_month DATE)
RETURNS TABLE (total_employees BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT count(DISTINCT wh.employee_id)
  FROM work_hours wh
  JOIN works w ON w.id = wh.work_id
  WHERE date_trunc('month', w.date) = date_trunc('month', p_month);
END;
$$;

-- Function to get total hours for a month
CREATE OR REPLACE FUNCTION get_month_hours_summary(p_month DATE)
RETURNS TABLE (total_hours DOUBLE PRECISION)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(sum(wh.hours), 0)::DOUBLE PRECISION
  FROM work_hours wh
  JOIN works w ON w.id = wh.work_id
  WHERE date_trunc('month', w.date) = date_trunc('month', p_month);
END;
$$;

-- Function to get objects summary for a month
CREATE OR REPLACE FUNCTION get_month_objects_summary(p_month DATE)
RETURNS TABLE (
  object_id UUID,
  object_name TEXT,
  works_count BIGINT,
  total_amount DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.name,
    count(w.id),
    COALESCE(sum(w.total_amount), 0)::DOUBLE PRECISION
  FROM works w
  JOIN objects o ON o.id = w.object_id
  WHERE date_trunc('month', w.date) = date_trunc('month', p_month)
  GROUP BY o.id, o.name
  ORDER BY COALESCE(sum(w.total_amount), 0) DESC;
END;
$$;

-- Function to get systems summary for a month
CREATE OR REPLACE FUNCTION get_month_systems_summary(p_month DATE)
RETURNS TABLE (
  system TEXT,
  works_count BIGINT,
  items_count BIGINT,
  total_amount DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    wi.system,
    count(DISTINCT w.id),
    count(wi.id),
    COALESCE(sum(wi.total), 0)::DOUBLE PRECISION
  FROM work_items wi
  JOIN works w ON w.id = wi.work_id
  WHERE date_trunc('month', w.date) = date_trunc('month', p_month)
  GROUP BY wi.system
  ORDER BY COALESCE(sum(wi.total), 0) DESC;
END;
$$;

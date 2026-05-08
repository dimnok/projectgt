-- Удаляем старую перегрузку calculate_payroll_for_month(int, int, uuid[]) без p_company_id.
-- Остаётся только версия с 4 параметрами (с p_company_id),
-- все вызовы в Dart-коде используют именно её (проверено grep'ом).
-- Причина: старая версия была SECURITY DEFINER без фильтра по компании — потенциальный риск утечки.

DROP FUNCTION IF EXISTS public.calculate_payroll_for_month(integer, integer, uuid[]);

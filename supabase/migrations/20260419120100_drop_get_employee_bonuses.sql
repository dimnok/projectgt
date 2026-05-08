-- Удаляем неиспользуемую функцию get_employee_bonuses(int, int).
-- Была без p_company_id — потенциальный риск утечки между компаниями.
-- Ни в Dart-коде, ни внутри других функций БД вызовов нет (проверено grep и pg_proc.prosrc).

DROP FUNCTION IF EXISTS public.get_employee_bonuses(integer, integer);

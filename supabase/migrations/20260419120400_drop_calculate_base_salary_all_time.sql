-- Удаляем легаси-функцию calculate_base_salary_all_time() без фильтра по компании.
-- Не используется ни в Dart-коде, ни в других RPC (проверено grep + pg_proc.prosrc).

DROP FUNCTION IF EXISTS public.calculate_base_salary_all_time();

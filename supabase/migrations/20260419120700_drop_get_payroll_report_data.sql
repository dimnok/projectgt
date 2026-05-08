-- Удаляем неиспользуемую get_payroll_report_data(int, int, uuid).
-- Не вызывается ни в Dart-коде, ни в других RPC.
-- Имела собственную (отличную от Dart-FIFO) реализацию выплат — источник потенциальных расхождений.

DROP FUNCTION IF EXISTS public.get_payroll_report_data(integer, integer, uuid);

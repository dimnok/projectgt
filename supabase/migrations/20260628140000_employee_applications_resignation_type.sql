-- Тип заявления: увольнение по собственному желанию.

BEGIN;

ALTER TABLE public.employee_applications
  DROP CONSTRAINT IF EXISTS employee_applications_application_type_check;

ALTER TABLE public.employee_applications
  ADD CONSTRAINT employee_applications_application_type_check
  CHECK (application_type IN ('vacation', 'unpaid_leave', 'resignation'));

COMMIT;

-- PostgREST PGRST203: две перегрузки public.get_months_summary(uuid) и (uuid, uuid)
-- при вызове с одним параметром неразличимы. Оставляем только вариант с двумя аргументами
-- (второй по умолчанию NULL).

DROP FUNCTION IF EXISTS public.get_months_summary(uuid);

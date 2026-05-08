-- RPC: уникальные должности сотрудников компании.
--
-- До этой миграции клиент вычитывал все строки employees по колонке
-- position и считал DISTINCT на стороне приложения. На десятках строк
-- это приемлемо, но на 1000+ сотрудниках вычитывается вся колонка при
-- каждом открытии формы редактирования.
--
-- SECURITY INVOKER: функция выполняется с правами вызывающего,
-- RLS-политики employees применяются, поэтому вернутся только позиции
-- тех компаний, к которым у пользователя есть доступ через company_members.
--
-- Примечание: название колонки возврата не position, т.к. это
-- зарезервированное слово в PL/pgSQL контексте RETURNS TABLE.

CREATE OR REPLACE FUNCTION public.get_employee_positions(p_company_id uuid)
RETURNS TABLE (position_name text)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT DISTINCT e.position::text AS position_name
  FROM public.employees e
  WHERE e.company_id = p_company_id
    AND e.position IS NOT NULL
    AND length(btrim(e.position)) > 0
  ORDER BY position_name;
$$;

COMMENT ON FUNCTION public.get_employee_positions(uuid) IS
  'Unique employee positions for company. SECURITY INVOKER, RLS employees applied.';

GRANT EXECUTE ON FUNCTION public.get_employee_positions(uuid) TO authenticated;

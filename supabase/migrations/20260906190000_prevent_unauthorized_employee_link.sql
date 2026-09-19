-- Regular users may update their own profile, but employee_id
-- may be changed only by users.update (owner / super-admin / admin).

CREATE OR REPLACE FUNCTION public.prevent_unauthorized_employee_link()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.employee_id IS NOT DISTINCT FROM NEW.employee_id THEN
    RETURN NEW;
  END IF;

  -- Service-role / system updates have no auth.uid()
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF public.check_permission(auth.uid(), 'users', 'update')
     OR public.is_super_admin(auth.uid()) THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Только супер-админ или руководитель может изменять привязку к сотруднику'
    USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS prevent_unauthorized_employee_link ON public.profiles;

CREATE TRIGGER prevent_unauthorized_employee_link
  BEFORE UPDATE OF employee_id ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_unauthorized_employee_link();

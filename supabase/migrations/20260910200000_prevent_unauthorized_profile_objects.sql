-- Regular users may update their own profile, but object_ids
-- may be changed only by users.update (owner / super-admin / admin).

CREATE OR REPLACE FUNCTION public.prevent_unauthorized_profile_objects()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF COALESCE(OLD.object_ids, '{}'::uuid[])
     IS NOT DISTINCT FROM COALESCE(NEW.object_ids, '{}'::uuid[]) THEN
    RETURN NEW;
  END IF;

  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF public.check_permission(auth.uid(), 'users', 'update')
     OR public.is_super_admin(auth.uid()) THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Только супер-админ или руководитель может назначать объекты пользователю'
    USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS prevent_unauthorized_profile_objects ON public.profiles;

CREATE TRIGGER prevent_unauthorized_profile_objects
  BEFORE UPDATE OF object_ids ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_unauthorized_profile_objects();
